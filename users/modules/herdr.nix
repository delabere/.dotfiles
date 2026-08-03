{ pkgs
, config
, lib
, ...
}:
let
  mkOption = lib.mkOption;
  types = lib.types;

  cfg = config.tools.herdr;

  tmuxBin = "${config.programs.tmux.package}/bin/tmux";
  herdrBin = "${pkgs.herdr}/bin/herdr";

  worktreeRoot = "${config.home.homeDirectory}/${cfg.worktreeDir}";

  # Hands the terminal over from tmux to herdr and back again.
  #
  # tmux's `detach-client -E` replaces the detaching client's process with the
  # given command, so herdr ends up owning the bare terminal. Chaining an
  # `attach-session` after it means tmux comes back when herdr exits. Because
  # tmux is detached while herdr runs, it is out of the keyboard path entirely
  # and never swallows herdr's prefix.
  herd = pkgs.writeShellScriptBin "herd" ''
    set -uo pipefail

    config="$HOME/.config/herdr/config.toml"
    stamp="$HOME/.config/herdr/.herd-config-stamp"
    current=$(readlink "$config" 2>/dev/null || echo plain)

    restart=0
    args=()
    for a in "$@"; do
      if [ "$a" = "--restart" ]; then restart=1; else args+=("$a"); fi
    done

    if [ "$restart" -eq 1 ]; then
      ${herdrBin} server stop >/dev/null 2>&1 || true
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        ${herdrBin} status server 2>/dev/null | grep -q "status: running" || break
        sleep 0.2
      done
    fi

    if ${herdrBin} status server 2>/dev/null | grep -q "status: running"; then
      # Live reload only covers theme and UI settings. The prefix and keybindings
      # are bound when the server starts, so a stale server keeps serving the old
      # keymap however many times the config is reloaded.
      ${herdrBin} server reload-config >/dev/null 2>&1 || true
      if [ -f "$stamp" ] && [ "$(cat "$stamp")" != "$current" ]; then
        echo "herd: config changed since the server started." >&2
        echo "herd: prefix/keybinding changes need: herd --restart" >&2
      fi
    else
      # About to start a fresh server, which will read the current config.
      printf '%s\n' "$current" > "$stamp"
    fi

    if [ -z "''${TMUX:-}" ]; then
      exec ${herdrBin} ''${args[@]+"''${args[@]}"}
    fi

    session=$(${tmuxBin} display-message -p '#{session_id}')
    client=$(${tmuxBin} display-message -p '#{client_tty}')

    # Quote the launch command so the shell tmux spawns re-parses it correctly.
    launch=$(printf '%q ' ${herdrBin} ''${args[@]+"''${args[@]}"})

    # The session id is single-quoted so the spawned shell treats it literally
    # rather than expanding it as a positional parameter.
    exec ${tmuxBin} detach-client -t "$client" -E \
      "$launch; ${tmuxBin} attach-session -t '$session' || ${tmuxBin} attach-session"
  '';

  # Creates a worktree-backed herdr workspace and starts the agent in it.
  # herdr has no declarative startup layout, so the agent is launched over the
  # socket API once the new workspace has focus.
  herd-wt = pkgs.writeShellScriptBin "herd-wt" ''
    set -euo pipefail

    branch="''${1:-}"
    if [ -z "$branch" ]; then
      printf 'branch: '
      read -r branch
    fi
    if [ -z "$branch" ]; then
      echo "herd-wt: no branch given" >&2
      exit 1
    fi

    base="''${HERD_BASE_BRANCH:-${cfg.baseBranch}}"

    # Resolve the primary checkout rather than the current one: --show-toplevel
    # returns the worktree path when run from inside a linked worktree, which
    # would nest new worktrees inside each other.
    root=$(dirname "$(${pkgs.git}/bin/git rev-parse --path-format=absolute --git-common-dir)")
    repo=$(basename "$root")

    # Reproduce the repo's path relative to $HOME inside the worktree, so Go
    # tooling that depends on the src/github.com/... layout keeps working.
    rel=''${root#"$HOME"/}
    path="${worktreeRoot}/$repo/$branch/$rel"

    # --cwd pins the source repo to the primary checkout, so this works from
    # inside a worktree workspace too, unlike the built-in new_worktree dialog.
    ${herdrBin} worktree create \
      --cwd "$root" \
      --branch "$branch" \
      --base "$base" \
      --path "$path" \
      --focus \
      --json >/dev/null

    pane=$(${herdrBin} pane list \
      | ${pkgs.jq}/bin/jq -r '.result.panes[] | select(.focused) | .pane_id' \
      | head -n1)

    if [ -z "$pane" ]; then
      echo "herd-wt: could not resolve the focused pane" >&2
      exit 1
    fi

    exec ${herdrBin} agent start ${cfg.agent} --kind ${cfg.agent} --pane "$pane"
  '';
in
{
  options = {
    tools.herdr.enable = mkOption {
      type = types.bool;
      default = false;
      description = "herdr agent multiplexer, launched from tmux via the herd wrapper";
    };

    tools.herdr.agent = mkOption {
      type = types.str;
      default = "claude";
      description = "Agent kind started in new worktree workspaces by herd-wt";
    };

    tools.herdr.baseBranch = mkOption {
      type = types.str;
      default = "master";
      description = "Default base ref for worktrees created by herd-wt";
    };

    tools.herdr.worktreeDir = mkOption {
      type = types.str;
      default = "projects/worktrees/herdr";
      description = "Worktree root, relative to the home directory";
    };

    tools.herdr.tmuxKey = mkOption {
      type = types.str;
      default = "H";
      description = "tmux prefix key that hands the terminal over to herdr";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.herdr
      herd
      herd-wt
    ];

    programs.tmux.extraConfig = lib.mkAfter ''
      # Hand the terminal over to herdr; tmux reattaches when herdr exits.
      bind ${cfg.tmuxKey} run-shell -b "${herd}/bin/herd"
    '';

    xdg.configFile."herdr/config.toml".text = ''
      # Managed by home-manager (users/modules/herdr.nix). Do not edit in place.
      # Apply changes with: home-manager switch && herdr server reload-config

      [theme]
      # catppuccin, terminal, tokyo-night, dracula, nord, gruvbox, one-dark,
      # solarized, kanagawa, rose-pine, vesper
      name = "catppuccin"

      [worktrees]
      directory = "~/${cfg.worktreeDir}"

      [session]
      resume_agents_on_restore = true

      [ui]
      hide_tab_bar_when_single_tab = true
      show_agent_labels_on_pane_borders = true

      [ui.toast]
      delivery = "herdr"

      [keys]
      # Matches the tmux secondary prefix, which is the one that is comfortable
      # on the split external keyboard. herdr supports a single prefix only:
      # there is no equivalent of tmux's prefix2, so ctrl+a is not available here.
      prefix = "ctrl+b"

      # Splits mirror the tmux bindings: v beside, x below.
      split_vertical = "prefix+v"
      split_horizontal = "prefix+x"

      # prefix+c is deliberately left unbound, as it is in tmux.
      new_tab = "prefix+t"

      # Direct (prefix-less) pane movement, matching the ctrl+hjkl muscle memory
      # that vim-tmux-navigator provides under tmux. herdr has no equivalent of
      # that plugin, so these are intercepted globally and are NOT forwarded to
      # the focused application: use <C-w>hjkl for splits inside nvim.
      focus_pane_left = "ctrl+h"
      focus_pane_down = "ctrl+j"
      focus_pane_up = "ctrl+k"
      focus_pane_right = "ctrl+l"

      detach = "prefix+d"
      zoom = "prefix+m"
      resize_mode = "prefix+r"

      # Moved clear of the split bindings above.
      close_pane = "prefix+shift+x"
      close_tab = "prefix+shift+k"
      close_workspace = "prefix+shift+d"

      # Worktree-backed workspaces are the workmux equivalent. open_worktree
      # adopts worktrees that already exist on disk, including workmux's.
      new_worktree = "prefix+shift+g"
      open_worktree = "prefix+shift+o"

      # Moved off prefix+shift+n, which creates a worktree workspace below.
      new_workspace = "prefix+shift+e"

      # alt chords are avoided throughout: they are terminal-dependent and this
      # terminal is known to mis-deliver them as a lone escape.

      # Create a worktree workspace with the agent already running in it.
      [[keys.command]]
      key = "prefix+shift+n"
      type = "pane"
      command = "${herd-wt}/bin/herd-wt"

      [[keys.command]]
      key = "prefix+shift+l"
      type = "popup"
      command = "${pkgs.lazygit}/bin/lazygit"
      width = "90%"
      height = "90%"
    '';
  };
}

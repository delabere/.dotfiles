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

    if [ -z "''${TMUX:-}" ]; then
      exec ${herdrBin} "$@"
    fi

    session=$(${tmuxBin} display-message -p '#{session_id}')
    client=$(${tmuxBin} display-message -p '#{client_tty}')

    # Quote the launch command so the shell tmux spawns re-parses it correctly.
    launch=$(printf '%q ' ${herdrBin} "$@")

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

    root=$(${pkgs.git}/bin/git rev-parse --show-toplevel)
    repo=$(basename "$root")

    # Reproduce the repo's path relative to $HOME inside the worktree, so Go
    # tooling that depends on the src/github.com/... layout keeps working.
    rel=''${root#"$HOME"/}
    path="${worktreeRoot}/$repo/$branch/$rel"

    ${herdrBin} worktree create \
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
      # Matches the tmux prefix, which is safe because tmux is detached while
      # herdr is running.
      prefix = "ctrl+a"

      # Splits mirror the tmux bindings: v beside, x below.
      split_vertical = "prefix+v"
      split_horizontal = "prefix+x"

      # prefix+c is deliberately left unbound, as it is in tmux.
      new_tab = "prefix+t"

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
      open_worktree = "prefix+alt+o"

      # Create a worktree workspace with the agent already running in it.
      [[keys.command]]
      key = "prefix+alt+n"
      type = "pane"
      command = "${herd-wt}/bin/herd-wt"

      [[keys.command]]
      key = "prefix+alt+g"
      type = "popup"
      command = "${pkgs.lazygit}/bin/lazygit"
      width = "90%"
      height = "90%"
    '';
  };
}

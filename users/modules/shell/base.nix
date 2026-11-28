{ pkgs
, name
, config
, ...
}:
let
  switch = pkgs.writeShellScriptBin "switch" (
    if pkgs.stdenv.hostPlatform.isDarwin && name == "delabere" then ''
      system=$(nix build --no-link --print-out-paths ~/.dotfiles#darwinConfigurations.Mac.system) \
        && sudo "$system/sw/bin/darwin-rebuild" switch --flake ~/.dotfiles#Mac
    '' else ''
      nix run ~/.dotfiles#switch.${name}
    ''
  );

  # Build brain's system on the Mac (the Rosetta builder VM does the x86_64
  # work) and activate it over SSH, so brain never compiles anything itself.
  #   build-brain             switch now
  #   build-brain boot        activate on next reboot
  #   build-brain build       build only, don't touch brain
  #   build-brain switch -L   extra args go to nixos-rebuild
  build-brain = pkgs.writeShellApplication {
    name = "build-brain";
    runtimeInputs = [ pkgs.nixos-rebuild-ng pkgs.git ];
    text = ''
      action=''${1:-switch}
      [ $# -gt 0 ] && shift
      # Brian (Hermes) deploys changes to brain itself and pushes them to
      # GitHub master. Pull them in first so a deploy from here never undoes
      # them: fast-forward, or rebase local commits on top (uncommitted
      # changes are stashed and restored). Stops only on a real conflict.
      d="$HOME/.dotfiles"
      if [ -z "''${BUILD_BRAIN_FORCE:-}" ] && git -C "$d" fetch -q origin master; then
        if ! git -C "$d" merge-base --is-ancestor origin/master HEAD; then
          echo "build-brain: pulling Brian's changes from GitHub master…" >&2
          if ! git -C "$d" pull -q --rebase --autostash origin master; then
            echo "build-brain: couldn't rebase onto GitHub master; sort out ~/.dotfiles (or BUILD_BRAIN_FORCE=1)." >&2
            exit 1
          fi
        fi
      fi
      exec nixos-rebuild "$action" --flake "$HOME/.dotfiles#brain" \
        --target-host delabere@brain --elevate sudo --use-substitutes "$@"
    '';
  };

  switch-remote = pkgs.writeShellScriptBin "switch-remote" ''
    nix run github:delabere/.dotfiles#switch.${name} --refresh
  '';

  todo = pkgs.writeShellScriptBin "todo" ''
    [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes"
    [ ! -f "$HOME/notes/todo.md" ] && touch "$HOME/notes/todo.md"
    nvim "$HOME/notes/todo.md"
  '';

  note = pkgs.writeShellScriptBin "note" ''
    [ ! -d "$HOME/notes" ] && mkdir -p "$HOME/notes"
    [ ! -f "$HOME/notes/$1.md" ] && touch "$HOME/notes/$1.md"
    nvim "$HOME/notes/$1.md"
  '';
  learnit = pkgs.writeShellScriptBin "learnit" ''
    [ ! -f "$HOME/learnit.txt" ] && touch "$HOME/learnit.txt"
    if [[ -z $1 ]]
    then
      cat $HOME/learnit.txt
    else
      echo "$(date +%d/%m/%Y) | $1" >> $HOME/learnit.txt
    fi
  '';
  _pkgs = [
    switch
    switch-remote
    todo
    note
    learnit
  ] ++ pkgs.lib.optional (pkgs.stdenv.hostPlatform.isDarwin && name == "delabere") build-brain;

  mkOption = pkgs.lib.mkOption;
  types = pkgs.lib.types;

in
{
  options = {
    shell.base.enable = mkOption {
      type = types.bool;
      default = false;
      description = "If enabled, will install cowsay";
    };
  };

  config = {
    home.packages =
      if config.shell.base.enable then _pkgs else [ ];
  };

}

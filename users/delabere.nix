{ pkgs, config, ... }: {
  imports = [
    ./modules/modules.nix # optional extras, enabled through config options
    ./modules/core.nix # essentials which should be included in all configurations
  ];

  # TODO: I want to have a nvim config for low powered machines
  # because it tends to chug on those otherwise

  # TODO: currently I need to stow my nvim and direnv configs into a new system
  # I should manage that here, and expose an optino to control which config to do
  # that with for nvim if I have more than one

  home.username = "delabere";

  # if you disable this you will have to run the full switch command
  shell.base.enable = true;
  languages.go.enable = true;

  # use this for packages that haven't permanently made it into this config
  # if they have a more permanent place in the config then they should live
  # in a module and be set by an option
  home.packages = with pkgs; [
    claude-code
    # nodePackages_latest.prettier
    # prettierd
    rclone
    codex
  ];

  # Claude Code: use Opus for planning, Sonnet for execution.
  # Merged into settings.json (rather than symlinked wholesale) so Claude
  # Code can still rewrite the rest of the file itself (e.g. via /theme).
  home.activation.claudeOpusPlan = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$settings")"
    if [ -f "$settings" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq '.model = "opusplan"' "$settings" > "$tmp" && mv "$tmp" "$settings"
    else
      echo '{"model": "opusplan"}' | ${pkgs.jq}/bin/jq '.' > "$settings"
    fi
  '';
}

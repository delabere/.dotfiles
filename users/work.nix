{
  config,
  pkgs,
  system,
  ...
}: let
  switch = pkgs.writeShellScriptBin "switch" ''
    home-manager switch --flake ~/.dotfiles#work-aarch64-darwin
  '';
in {
  imports = [
    ./config/base.nix
    ./config/shell/base.nix
    ./config/shell/work.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jackrickards";
  home.homeDirectory ="/Users/jackrickards/";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    switch
    pkgs.graphviz
    # pkgs.go
    # pkgs.gopls
  ];

  programs = {
    zsh = {
      envExtra = ''
        # work configuration
        [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv

        # custom environment variables
        [ -f $HOME/.dotfiles/env.sh ] && source $HOME/.dotfiles/env.sh

        JAVA_HOME=$(/usr/libexec/java_home -v 19)
      '';
    };
  };
}

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
    ./base.nix
    ./base-apps.nix
    ./work-apps.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jackrickards";
  home.homeDirectory =
    {
      aarch64-darwin = "/Users/jackrickards/";
      x86_64-linux = "/home/jackrickards";
    }
    .${system};

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
      enable = true;
      dotDir = ".config/zsh";
      # haven't quite managed to get these working
      #enableAutosuggestions = true;
      #enableCompletion = true;

      envExtra = ''
        # work configuration
        [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv

        # custom environment variables
        [ -f $HOME/.dotfiles/env.sh ] && source $HOME/.dotfiles/env.sh

        JAVA_HOME=$(/usr/libexec/java_home -v 19)
      '';
    };

}

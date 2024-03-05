{pkgs, ...}: {
  imports = [
    ./config/base.nix
    ./config/shell/base.nix
    ./config/shell/work.nix
  ];

  home.username = "jackrickards";

  home.packages = with pkgs; [
    graphviz
    nodejs_20
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

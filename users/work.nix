{ pkgs, ... }: {
  imports = [
    ./modules/modules.nix # optional extras, enabled through config options
    ./modules/core.nix # essentials which should be included in all configurations
  ];

  home.username = "jackrickards";

  shell = {
    base.enable = true;
    work.enable = true;
  };

  languages.go = {
    enable = true;
    work = true;
  };

  # use this for packages that haven't permanently made it into this config
  # if they have a more permanent place in the config then they should live
  # in a module and be set by an option
  home.packages = with pkgs; [
    graphviz
    nodejs_20
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

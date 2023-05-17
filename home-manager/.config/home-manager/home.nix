{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "delabere";
  home.homeDirectory = "/Users/delabere";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "22.11"; # Please read the comment before changing.


  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    #(pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    pkgs.tmux
    pkgs.go
    pkgs.gopls
    pkgs.lazygit
    pkgs.ranger
    pkgs.ripgrep
    pkgs.stow
    pkgs.sumneko-lua-language-server
    pkgs.tldr
    pkgs.tree
    pkgs.xclip
    pkgs.zsh
    pkgs.watch
    pkgs.thefuck
    pkgs.nodejs
    pkgs.niv
    pkgs.delve
    pkgs.nodePackages.vscode-html-languageserver-bin
    (pkgs.nerdfonts.override {
      fonts = [ "FiraCode" "Hack" ];
    })
  ];

  fonts.fontconfig.enable = true;
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    # haven't quite managed to get these working
    #enableAutosuggestions = true;
    #enableCompletion = true;

    initExtra = ''
      # brew is installed here on m1 macs
      [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

      # any .zshrc found can be sourced; its probably a work machine
      [ -f "$HOME/.zshrc" ] && source ~/.zshrc

      # allows easy resetting of home-manager
      function rebuild-home-manager() {
        home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
      }

      function todo() {
          [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes"
          [ ! -f "$HOME/notes/todo.md" ] && touch "$HOME/notes/todo.md"
          nvim "$HOME/notes/todo.md"
      }

      function note() {
          [ ! -d "$HOME/notes" ] && mkdir -p "$HOME/notes"
          [ ! -f "$HOME/notes/$1.md" ] && touch "$HOME/notes/$1.md"
          nvim "$HOME/notes/$1.md"
      }

      s101 () {
        shipper deploy --s101 $1 --disable-progressive-rollouts
      }

      prod () {
        shipper deploy --prod $1
      }

      alias lg='lazygit'
      alias gcm='git checkout master && git pull'

      # for pyenv
      export PYENV_ROOT="$HOME/.pyenv"
      command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"

      # The next line updates PATH for the Google Cloud SDK.
      if [ -f '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc'; fi

      # The next line enables shell command completion for gcloud.
      if [ -f '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

    '';

    envExtra = ''
      # work configuration
      [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv
    '';
  };


  programs = {
    direnv.enable = true;
    fzf.enable = true;
    starship.enable = true;
    autojump.enable = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    jq.enable = true;

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };

    neovim = {
      enable = true;
      vimAlias = true;
    };

  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/delabere/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

{ config, pkgs, ... }:
let
  user = builtins.getEnv "USER";
  home = builtins.getEnv "HOME";
  sources = import ./nix/sources.nix;
  vim-plug = sources.vim-plug;
  tpm = sources.tpm;
in
{
  home = {
    username = user;
    stateVersion = "22.11";
    homeDirectory = home;
    sessionVariables = {
      NIX_PATH = "nixpkgs=${sources.nixpkgs}";
    };
  };

  fonts.fontconfig.enable = true;

  
  programs = {
    home-manager = {
      enable = true;
      path = "${sources.home-manager}";
    };


    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      # haven't quite managed to get these working
      # enableAutosuggestions = true;
      # enableCompletion = true;

      initExtra = ''
          # brew is installed here on m1 macs
          [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

          # any .zshrc found can be sourced; its probably a work machine
          [ -f "$HOME/.zshrc" ] && source ~/.zshrc
          
          # add adb to path (for work)
          export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

          # allows easy resetting of home-manager          
          function rebuild-home-manager() {
            home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
          }

          function todo() {
              [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes" 
              [ ! -f "$HOME/notes.todo.md" ] && touch "$HOME/notes/todo.md" 
              nvim "$HOME/notes/todo.md"
          }

          s101 () {
            vpn && shipper deploy --s101 $1 --disable-progressive-rollouts
          }

          prod () {
            vpn && shipper deploy --prod $1
          }

          alias lg='lazygit'
          alias gcm='git checkout master && git pull'
      '';

      envExtra = ''
          # work configuration
          [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv
      '';
    };

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

  home.packages = with pkgs; [
    tmux
    go
    gopls
    lazygit
    ranger
    ripgrep
    stow
    sumneko-lua-language-server
    tldr
    tree
    xclip
    zsh
    watch 
    thefuck
    python39
    (nerdfonts.override {
      fonts = [ "FiraCode" ];
    })
  ];

  home.file.".local/share/nvim/site/autoload/plug.vim".source = "${vim-plug}/plug.vim";
  home.file.".tmux/plugins/tpm".source = "${tpm}";
}


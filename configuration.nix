{ config, pkgs, ... }:
let
  user = builtins.getEnv "USER";
  home = builtins.getEnv "HOME";
  sources = import ./nix/sources.nix;
  vim-plug = sources.vim-plug;
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

          # allows easy resetting of home-manager          
          function rebuild-home-manager() {
            home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
          }

          function ship2prod() {
              shipper deploy $1 --s101 --skip-confirm-rollout && shipper deploy $1 --prod --skip-confirm-rollout
          }

          function todo() {
              [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes" 
              [ ! -f "$HOME/notes.todo.md" ] && touch "$HOME/notes/todo.md" 
              nvim "$HOME/notes/todo.md"
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
      plugins = [ pkgs.vimPlugins.vim-plug ];
    };

    tmux = {
      enable = true;
    };

  };

  home.packages = with pkgs; [
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
    thefuck
    (nerdfonts.override {
      fonts = [ "FiraCode" ];
    })
  ];

  home.file.".local/share/nvim/site/autoload/plug.vim".source = "${vim-plug}/plug.vim";
}


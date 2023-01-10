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

  programs.home-manager = {
    enable = true;
    path = "${sources.home-manager}";
  };


  programs.zsh = {
   enable = true;
   dotDir = ".config/zsh";

   initExtra = ''
          # brew is installed here on m1 macs
          [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

          # any .zshrc found can be sourced; its probably a work machine
          [ -f "$HOME/.zshrc" ] && source ~/.zshrc

          # allows easy resetting of home-manager          
          function home-manager-rebuild() {
            home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
          }

          function ship2prod() {
              shipper deploy $1 --s101 --skip-confirm-rollout && shipper deploy $1 --prod --skip-confirm-rollout
          }

          alias lg='lazygit'
          alias gcm='git checkout master && git pull'
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

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };

    neovim = {
      enable = true;
      vimAlias = true;
      plugins = [ pkgs.vimPlugins.vim-plug ];
    };
  };

  home.packages = with pkgs; [
    go
    gopls
    jq
    lazygit
    ranger
    ripgrep
    stow
    sumneko-lua-language-server
    tldr
    tree
    xclip
    zsh
    (nerdfonts.override {
      fonts = [ "FiraCode" ];
    })
  ];

  home.file.".local/share/nvim/site/autoload/plug.vim".source = "${vim-plug}/plug.vim";
}


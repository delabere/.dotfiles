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

  programs.autojump.enable = true;

 programs.bash = {
   enable = true;

   bashrcExtra = ''
     if [ -f ~/.bashrc.local ]; then
       source ~/.bashrc.local
     fi
     if [ -f ~/.bashrc.work ]; then
       source ~/.bashrc.work
     fi
   '';
 };

 programs.zsh = {
   enable = true;
   dotDir = ".config/zsh";


   initExtra = ''
     if [ -f ~/.bashrc.local ]; then
       source ~/.bashrc.local
     fi
     if [ -f ~/.bashrc.work ]; then
       source ~/.bashrc.work
     fi
   '';
 };
  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.starship.enable = true;
  # programs.zsh.oh-my-zsh.enable = true;

  programs.home-manager = {
    enable = true;
    path = "${sources.home-manager}";
  };

  programs.git = {
    enable = true;
    userName = "delabere";
    userEmail = "jack.rickards@hotmail.co.uk";
  };

  programs.neovim =
    {
      enable = true;
      vimAlias = true;

      plugins = [ pkgs.vimPlugins.vim-plug ];
    };

  home.packages = with pkgs; [
    bat
    go
    gopls
    (nerdfonts.override {
      fonts = [ "FiraCode" ];
    })
    ripgrep
    stow
    tldr
    tree
    xclip
    zsh
    lazygit
    sumneko-lua-language-server
    ranger
  ];

  home.file.".local/share/nvim/site/autoload/plug.vim".source = "${vim-plug}/plug.vim";
}


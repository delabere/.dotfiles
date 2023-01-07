{ config, pkgs, ... }:
let
  home = builtins.getEnv "HOME";
  sources = import ./nix/sources.nix;
  nixpkgs = sources.nixpkgs;
in
{
  home = {
    username = "delabere";
    stateVersion = "22.11";
    homeDirectory = home;
    sessionVariables = {
      NIX_PATH = "nixpkgs=${nixpkgs}";
    };
  };

  fonts.fontconfig.enable = true;

  programs.autojump.enable = true;

  programs.bash = {
    enable = true;

    bashrcExtra = ''
      if [ -f ~/.bashrc.work ]; then
        source ~/.bashrc.work
      fi
    '';
  };

  programs.zsh = {
    enable = true;

    initExtra = ''
    '';
  };

  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.starship.enable = true;

  programs.home-manager = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "delabere";
    userEmail = "jack.rickards@hotmail.co.uk";
  };

  home.packages = with pkgs; [
    bat
    go
    neovim
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ripgrep
    stow
    tldr
    tree
    xclip
    zsh
    lazygit
  ];
}


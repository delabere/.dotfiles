{
  config,
  pkgs,
  system,
  ...
}: let
  switch = pkgs.writeShellScriptBin "switch" ''
    home-manager switch --flake ~/.dotfiles#lakeview-aarch64-linux
  '';
in {
  imports = [
    ./base.nix
    ./base-apps.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    switch
    pkgs.alejandra
    pkgs.delve
    pkgs.go
    pkgs.gopls
    pkgs.lazygit
    pkgs.niv
    pkgs.nixpkgs-fmt
    pkgs.nodePackages.vscode-html-languageserver-bin
    pkgs.nodejs
    pkgs.ranger
    pkgs.ripgrep
    pkgs.stow
    pkgs.sumneko-lua-language-server
    pkgs.thefuck
    pkgs.tldr
    pkgs.tree
    pkgs.watch
    pkgs.xclip
    pkgs.zsh
    (pkgs.nerdfonts.override {
      fonts = ["FiraCode" "Hack"];
    })
  ];
}

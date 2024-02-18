{
  config,
  pkgs,
  system,
  brag,
  ...
}: let
  switch = pkgs.writeShellScriptBin "switch" ''
    home-manager switch --flake ~/.dotfiles#delabere-aarch64-darwin
  '';
in {
  imports = [
    ./base.nix
    ./base-apps.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "delabere";
  home.homeDirectory = "/Users/delabere";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    switch
    alejandra
    go
    gopls
    nixpkgs-fmt
  ];
}

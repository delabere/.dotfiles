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
  home.homeDirectory =
    {
      aarch64-darwin = "/Users/delabere";
      aarch64-linux = "/home/ubuntu";
      x86_64-linux = "/home/delabere";
    }
    .${system};

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

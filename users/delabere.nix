{ config
, pkgs
, system
, brag
, ...
}:
{
  imports = [
    ./config/base.nix
    ./config/shell/base.nix
  ];

  home.username = "delabere";

  home.packages = with pkgs; [
    alejandra
    go
    gopls
    nixpkgs-fmt
  ];
}

{pkgs, ...}: {
  imports = [
    ./config/base.nix
    ./config/shell/base.nix
  ];

  home.username = "delabere";

  home.packages = with pkgs; [
    go
    gopls
  ];
}

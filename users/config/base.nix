{
  pkgs,
  system,
  ...
}: {
  imports = [
    ./lite.nix
  ];

  home.packages = with pkgs; [
    alejandra
    brag
    delve
    nixpkgs-fmt
    sumneko-lua-language-server
    thefuck
    nodejs_20
  ];
}

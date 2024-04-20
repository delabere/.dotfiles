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
    nodePackages.vscode-html-languageserver-bin
    sumneko-lua-language-server
    thefuck
    nodejs_20
  ];
}

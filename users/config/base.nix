{
  config,
  pkgs,
  brag,
  session-x,
  system,
  ...
}: {
  imports = [
    ./lite.nix
  ];

  home.packages = with pkgs; [
    alejandra
    brag.packages.${system}.default
    delve
    nixpkgs-fmt
    nodePackages.vscode-html-languageserver-bin
    sumneko-lua-language-server
    thefuck
  ];
}

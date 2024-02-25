{
  config,
  pkgs,
  brag,
  system,
  ...
}: {
  imports = [
    ./lite.nix
  ];

  home.packages = with pkgs; [
    brag.packages.${system}.default
    delve
    nodePackages.vscode-html-languageserver-bin
    nodejs
    sumneko-lua-language-server
    thefuck
  ];
}

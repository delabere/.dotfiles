{pkgs, ...}: {
  home.packages = with pkgs; [
    btop
    delve
    lazygit
    nodePackages.vscode-html-languageserver-bin
    nodePackages.vscode-html-languageserver-bin
    nodejs
    ranger
    ripgrep
    stow
    sumneko-lua-language-server
    sumneko-lua-language-server
    thefuck
    thefuck
    tldr
    tree
    watch
    xclip
    zsh
    (nerdfonts.override {
      fonts = ["FiraCode" "Hack"];
    })
  ];
}

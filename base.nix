{
  config,
  pkgs,
  brag,
  system,
  ...
}: let
  randomShellScript = pkgs.writeShellScriptBin "my-hello" ''
    echo "Hello, ${config.home.username}!"
  '';
in {
  home.packages =
    [
      randomShellScript
      brag.packages.${system}.default
    ]
    ++ (
      with pkgs; [
        btop
        delve
        lazygit
        nodePackages.vscode-html-languageserver-bin
        nodejs
        ranger
        ripgrep
        stow
        sumneko-lua-language-server
        thefuck
        tldr
        tree
        watch
        xclip
        zsh
        (nerdfonts.override {
          fonts = ["FiraCode" "Hack"];
        })
      ]
    );
}

let
  sources = import ./nix/sources.nix;
  nixpkgs = sources.nixpkgs;
  pkgs = import nixpkgs { };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    home-manager
    niv
  ];

  NIX_PATH = "nixpkgs=${builtins.toString nixpkgs}";
}

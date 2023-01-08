let
  sources = import ./nix/sources.nix;
  pkgs = import ./nixpkgs.nix;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    home-manager
    niv
  ];

  NIX_PATH = "nixpkgs=${builtins.toString sources.nixpkgs}";
}

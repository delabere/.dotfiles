let
  sources = import ./nix/sources.nix;
  nixpkgs = sources.nixpkgs;
  home-manager = sources.home-manager;
  home-manager-overlay = import "${home-manager}/overlay.nix";
in
import nixpkgs {
  overlays = [
    home-manager-overlay
  ];
}

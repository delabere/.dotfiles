{
  description = "Home Manager configuration of delabere";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brag = {
      url = "github:delabere/brag";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    session-x = {
      url = "github:omerxx/tmux-sessionx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    home-manager,
    brag,
    session-x,
    ...
  } @ inputs:
    flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-linux" "aarch64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import ./overlay.nix inputs)];
        };
        mkHomeManagerConfig = module: name:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              module
            ];

            extraSpecialArgs = {
              inherit inputs system brag session-x name;
            };
          };
        homeConfigurations = {
          delabere = mkHomeManagerConfig ./users/delabere.nix "delabere";
          lakeview = mkHomeManagerConfig ./users/lakeview.nix "lakeview";
          work = mkHomeManagerConfig ./users/work.nix "work";
        };
      in {
        apps.switch =
          nixpkgs.lib.mapAttrs
          (
            name: config:
              flake-utils.lib.mkApp {
                drv = config.activationPackage;
                exePath = "/activate";
              }
          )
          homeConfigurations;
      }
    );
}

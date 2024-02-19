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
  };

  outputs =
    { nixpkgs
    , flake-utils
    , home-manager
    , brag
    , ...
    } @ inputs:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        mkHomeManagerConfig = module:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              module
            ];

            extraSpecialArgs = {
              inherit inputs system brag;
            };
          };
        homeConfigurations = {
          delabere = mkHomeManagerConfig ./users/delabere.nix;
          lakeview = mkHomeManagerConfig ./users/lakeview.nix;
          work = mkHomeManagerConfig ./users/work.nix;
        };
      in
      {
        apps.switch = nixpkgs.lib.mapAttrs
          (
            name: config:
              flake-utils.lib.mkApp {
                drv = config.activationPackage;
                exePath = "/activate";
              }
          )
          homeConfigurations
        ;
      }
    );
}

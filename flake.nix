{
  description = "Home Manager configuration of delabere";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brag = {
      url = "github:delabere/brag";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    goprotomocker = {
      url = "github:delabere/goprotomocker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    session-x = {
      url = "github:omerxx/tmux-sessionx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , flake-utils
    , home-manager
    , brag
    , agenix
    , nixarr
    , ...
    } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import ./overlay.nix inputs) ];
          };
          mkHomeManagerConfig = module: name:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                module
              ];

              extraSpecialArgs = {
                inherit inputs system name brag;
              };
            };
          homeConfigurations = {
            delabere = mkHomeManagerConfig ./users/delabere.nix "delabere";
            lakeview = mkHomeManagerConfig ./users/lakeview.nix "lakeview";
            work = mkHomeManagerConfig ./users/work.nix "work";
          };
        in
        {
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

          packages.nixosConfigurations.nixos =
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                ./machines/oracle-free/configuration.nix
                { nixpkgs.config.allowUnfree = true; }
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.delabere = import ./users/delabere.nix;
                  home-manager.extraSpecialArgs = { inherit inputs system brag; };
                }
              ];
            };

          packages.nixosConfigurations.brain =
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                ./machines/brain/configuration.nix
                agenix.nixosModules.default
                nixarr.nixosModules.default
                { nixpkgs.config.allowUnfree = true; }
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.delabere = import ./users/delabere.nix;
                  home-manager.extraSpecialArgs = { inherit inputs system brag; };
                }
              ];
            };
        }
      );
}


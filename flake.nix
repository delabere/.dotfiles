{
  description = "Home Manager configuration of delabere";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
    workmux = {
      url = "github:raine/workmux";
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
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Linux VM on the Mac that builds x86_64-linux (brain) through Rosetta 2
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
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
    , darwin
    , ...
    } @ inputs:
    let
      # nix-darwin config for the Mac; `extra` adds the Linux builder variant
      mkMac = extra:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.darwinModules.home-manager
            {
              security.pam.services.sudo_local.touchIdAuth = true;
              ids.gids.nixbld = 30000;
              system.stateVersion = 7;
              nix.settings.trusted-users = [ "root" "delabere" ];
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              # keep /nix/store from filling the disk: drop system generations
              # older than two weeks and collect garbage every Sunday at 03:00
              nix.gc = {
                automatic = true;
                interval = { Weekday = 0; Hour = 3; Minute = 0; };
                options = "--delete-older-than 14d";
              };
              nix.optimise.automatic = true;
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ (import ./overlay.nix inputs) ];
              users.users.delabere.home = "/Users/delabere";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.delabere = import ./users/delabere.nix;
              home-manager.extraSpecialArgs = { inherit inputs brag; name = "delabere"; };
            }
          ] ++ extra;
        };
    in
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import ./overlay.nix inputs) ];
            config.allowUnfree = true;
          };
          mkHomeManagerConfig = module: name:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                module
              ];

              extraSpecialArgs = {
                inherit inputs name brag;
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

        }
      ) // {
        nixosConfigurations.nixos =
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./machines/oracle-free/configuration.nix
              {
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = [ (import ./overlay.nix inputs) ];
              }
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.delabere = import ./users/delabere.nix;
                home-manager.extraSpecialArgs = { inherit inputs brag; name = "delabere"; };
              }
            ];
          };

        nixosConfigurations.brain =
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./machines/brain/configuration.nix
              agenix.nixosModules.default
              nixarr.nixosModules.default
              {
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = [ (import ./overlay.nix inputs) ];
              }
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.delabere = import ./users/delabere.nix;
                home-manager.extraSpecialArgs = { inherit inputs brag; name = "delabere"; };
              }
            ];
          };

        # The Rosetta builder rebuilds its own VM image. On a fresh Mac it needs
        # another Linux builder the first time: switch once with
        # `{ nix.linux-builder.enable = true; }` in place of the module below.
        darwinConfigurations.Mac = mkMac [
          inputs.nix-rosetta-builder.darwinModules.default
          {
            nix-rosetta-builder = {
              # boot the VM when a Linux build is queued, power it off when idle
              onDemand = true;
              onDemandLingerMinutes = 30;
              # the Mac has 10 cores / 16GB; leave it room while building
              cores = 8;
              memory = "8GiB";
              diskSize = "60GiB";
            };
          }
        ];
      };
}

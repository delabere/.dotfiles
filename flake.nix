{
  description = "Home Manager configuration of delabere";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs:
    let
      mkHomeManagerConfig = module: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
          };

          modules = [
            module
          ];

          extraSpecialArgs = {
            inherit inputs system;
          };
        };
    in
    {
      homeConfigurations = {
        delabere-aarch64-darwin = mkHomeManagerConfig ./delabere.nix "aarch64-darwin";
        delabere-x86_64-linux = mkHomeManagerConfig ./delabere.nix "x86_64-linux";
        work-aarch64-darwin = mkHomeManagerConfig ./work.nix "aarch64-darwin";
      };

      nixosConfigurations = {
        bitch = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./bitch.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };

      devShells.aarch64-darwin.default =
        let pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        in
        pkgs.mkShell {
          buildInputs = [
            pkgs.nixos-rebuild
          ];
        };
    };
}


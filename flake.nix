{
  description = "Home Manager configuration of delabere";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brag = {
      url = "github:delabere/brag";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    brag,
    ...
  } @ inputs: let
    mkHomeManagerConfig = module: system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          module
        ];

        extraSpecialArgs = {
          inherit inputs system brag;
        };
      };
  in {
    homeConfigurations = {
      delabere-aarch64-darwin = mkHomeManagerConfig ./config/delabere.nix "aarch64-darwin";
      lakeview-aarch64-linux = mkHomeManagerConfig ./config/lakeview.nix "aarch64-linux";
      delabere-x86_64-linux = mkHomeManagerConfig ./config/delabere.nix "x86_64-linux";
      work-aarch64-darwin = mkHomeManagerConfig ./config/work.nix "aarch64-darwin";
    };
  };
}

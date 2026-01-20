{
  description = "Heime Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nixvim,
      nixos-hardware,
      stylix,
      sops-nix,
      zen-browser,
      ...
    }@inputs:

    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkHomeConfig =
        { username, stateVersion }:
        {
          imports = [ nixvim.homeModules.nixvim ];
          home = {
            username = username;
            homeDirectory = "/home/${username}";
            stateVersion = stateVersion;
          };
          programs.home-manager.enable = true;
        };

      commonModules = [
        ./modules
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
      ];
    in
    {

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = commonModules ++ [
            ./hosts/laptop
            { user = "none"; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs pkgs-unstable; };
                users.none = mkHomeConfig {
                  username = "none";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };

        VNPC-21 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = commonModules ++ [
            ./hosts/vnpc-21
            { user = "odin"; }
            nixos-hardware.nixosModules.lenovo-thinkpad-p53
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs pkgs-unstable; };
                users.odin = mkHomeConfig {
                  username = "odin";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };

        station = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = commonModules ++ [
            ./hosts/station
            { user = "none"; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs pkgs-unstable; };
                users.none = mkHomeConfig {
                  username = "none";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };
      };

      # homeConfigurations removed - using integrated home-manager instead
    };
}

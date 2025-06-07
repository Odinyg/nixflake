{
  description = "Heime Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    stylix.url = "github:danth/stylix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      nixos-hardware,
      stylix,
      ...
    }@inputs:

    let
      mkHomeConfig =
        { username, stateVersion }:
        {
          imports = [ nixvim.homeManagerModules.nixvim ];
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
      ];
    in
    {

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hosts/laptop
            { user = "none"; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.none = mkHomeConfig {
                  username = "none";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };

        VNPC-21 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hosts/p53
            { user = "odin"; }
            nixos-hardware.nixosModules.lenovo-thinkpad-p53
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.odin = mkHomeConfig {
                  username = "odin";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };

        station = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hosts/station
            { user = "none"; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.none =
                  (mkHomeConfig {
                    username = "none";
                    stateVersion = "25.05";
                  })
                  // {
                  };
              };
            }
          ];
        };
      };
    };
}

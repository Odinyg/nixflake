{
  description = "Heime Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
    };
    winboat.url = "github:TibixDev/winboat";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      nixvim,
      nixos-hardware,
      stylix,
      sops-nix,
      zen-browser,
      winboat,
      ...
    }@inputs:

    let
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
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            ./hosts/laptop
            { user = "none"; }
            {
              nixpkgs.config.allowUnfree = true;
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
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = false;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                };
                users.odin = (mkHomeConfig {
                  username = "odin";
                  stateVersion = "25.05";
                }) // {
                  nixpkgs.config.allowUnfree = true;
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
              nixpkgs.config.allowUnfree = true;
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

      homeConfigurations = {
        "odin@p53" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/p53/home-standalone.nix
            nixvim.homeModules.nixvim
            stylix.homeManagerModules.stylix
            ./modules/home-manager
          ];
        };
      };
    };
}

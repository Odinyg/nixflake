{
  description = "Heime Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    stylix.url = "github:danth/stylix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-which-key.url = "github:alexwforsythe/tmux-which-key";
    tmux-which-key.flake = false;
  };
  outputs =
    {
      self,
      firefox-addons,
      nixpkgs,
      home-manager,
      nixvim,
      nixos-hardware,
      stylix,
      ...
    }@inputs:

    let
      userInfo = {
        user = "none";
      };
      userInfoWork = {
        user = "odin";
      };
      system = "x86_64-linux";
      nixpkgs-outPath = {
        environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
      };
      homeManagerModules = [ nixvim.homeManagerModules.nixvim ];
    in
    {

      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };

          modules = [ ./hosts/vm ];
        };
        vmserver = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };
          modules = [ ./hosts/vmserver ];
        };
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };

          modules = [
            ./hosts/laptop
            stylix.nixosModules.stylix
            ./modules
            userInfo
        #    nixos-hardware.nixosModules.dell-xps-15-9560

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.none.imports = [ ./hosts/laptop/home.nix ] ++ homeManagerModules;
              };
            }
          ];
        };
        VNPC-21 = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };

          modules = [
            ./hosts/p53
            ./modules
            stylix.nixosModules.stylix
            userInfoWork
            nixos-hardware.nixosModules.lenovo-thinkpad-p53
            nixpkgs-outPath
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.odin.imports = [ ./hosts/p53/home.nix ] ++ homeManagerModules;
              };
            }
          ];
        };
        station = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };

          modules = [
            ./hosts/station
            ./modules
            inputs.stylix.nixosModules.stylix
            userInfo
            nixpkgs-outPath
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.none.imports = [ ./hosts/station/home.nix ] ++ homeManagerModules;
              };
            }
          ];
        };
      };
    };
}

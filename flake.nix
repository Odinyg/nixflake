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

      # Helper function for standalone home-manager configurations (Arch Linux, etc.)
      mkStandaloneHomeConfig =
        { username, stateVersion, hostname, system ? "x86_64-linux", extraModules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [
            nixvim.homeModules.nixvim
            stylix.homeManagerModules.stylix
            ./modules/home-manager
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = stateVersion;
              };
              programs.home-manager.enable = true;
            }
          ] ++ extraModules;
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
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
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
            ./hosts/vnpc-21
            { user = "odin"; }
            nixos-hardware.nixosModules.lenovo-thinkpad-p53
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                };
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
                extraSpecialArgs = { inherit inputs; };
                users.none = mkHomeConfig {
                  username = "none";
                  stateVersion = "25.05";
                };
              };
            }
          ];
        };
      };

      # ==============================================================================
      # STANDALONE HOME-MANAGER CONFIGURATIONS (for non-NixOS systems like Arch)
      # ==============================================================================
      homeConfigurations = {
        # Example configuration for Arch Linux
        # Usage: home-manager switch --flake .#youruser@yourhostname
        "youruser@yourhostname" = mkStandaloneHomeConfig {
          username = "youruser";
          stateVersion = "25.05";
          hostname = "yourhostname";
          extraModules = [ ./arch-hosts/example/home.nix ];
        };

        # Add your own Arch configurations here, for example:
        # "odin@archpc" = mkStandaloneHomeConfig {
        #   username = "odin";
        #   stateVersion = "25.05";
        #   hostname = "archpc";
        #   extraModules = [ ./arch-hosts/archpc/home.nix ];
        # };
      };
    };
}

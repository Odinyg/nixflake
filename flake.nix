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
      inputs.nixpkgs.follows = "nixpkgs";
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

      commonModules = [
        ./modules
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
      ];
      
      # For standalone home-manager (Arch Linux)
      mkStandaloneHomeConfig = { username, hostname, profile }: 
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            nixvim.homeModules.nixvim
            stylix.homeManagerModules.stylix
            ./modules/home-manager  # Your existing home-manager modules
            ./arch-modules/arch-packages.nix  # Arch package management
            profile  # Machine-specific profile (arch-laptop.nix, etc.)
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "25.05";
                # Pass hostname for machine-specific configs
                sessionVariables.HOSTNAME = hostname;
              };
              programs.home-manager.enable = true;
              # Set hostname in config for arch-packages module
              _module.args.hostname = hostname;
              # Set user for modules that need it
              user = username;
            }
          ];
        };
    in
    {
      # Standalone Home Manager configurations for Arch Linux
      homeConfigurations = {
        "none@arch-laptop" = mkStandaloneHomeConfig {
          username = "none";
          hostname = "arch-laptop";
          profile = ./profiles/arch-laptop.nix;
        };
      };

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

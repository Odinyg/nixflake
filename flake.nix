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

      commonModules = [
        ./modules
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
      ];

      # Helper function to create home-manager configuration
      mkHomeManagerConfig =
        { username, stateVersion }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.${username} = mkHomeConfig {
              inherit username stateVersion;
            };
          };
        };

      # Helper function to create a NixOS system configuration
      mkSystem =
        { hostPath, user, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            hostPath
            { inherit user; }
            (mkHomeManagerConfig {
              username = user;
              stateVersion = "25.05";
            })
          ] ++ extraModules;
        };
    in
    {

      nixosConfigurations = {
        laptop = mkSystem {
          hostPath = ./hosts/laptop;
          user = "none";
        };

        VNPC-21 = mkSystem {
          hostPath = ./hosts/vnpc-21;
          user = "odin";
          extraModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-p53 ];
        };

        station = mkSystem {
          hostPath = ./hosts/station;
          user = "none";
        };
      };

      # homeConfigurations removed - using integrated home-manager instead
    };
}

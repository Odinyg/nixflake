{
  description = "Heime Flake";
  outputs = inputs@{ nixpkgs, home-manager, nixvim, nixos-hardware, self, ... }:

    let
      user = "none";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

    # configure lib
    lib = nixpkgs.lib // home-manager.lib;
    in {

    nixosConfigurations = {
      laptop = lib.nixosSystem {
        extraSpecialArgs = {inherit inputs;};
        modules = [ 
          ./hosts/laptop
          ./modules/common   
         inputs.home-manager.nixosModules.laptop
        ]; 
        specialArgs = {
          inherit system;
          inherit user;
        };
      };
    };


#    homeConfigurations = {
#      laptop = inputs.home-manager.lib.homeManagerConfiguration {
#          inherit pkgs;
#          modules = [ 
#            ./home/laptop.nix
#          ];
#          extraSpecialArgs = {
#          inherit inputs ;
#          inherit pkgs;
#          };
#      };
#    };






  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nix-colors.url = "github:misterio77/nix-colors";
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
    hyprland.url = "github:hyprwm/Hyprland";
    };
    };
}

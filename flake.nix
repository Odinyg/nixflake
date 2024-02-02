{
  description = "Heime Flake";
  outputs = { nixpkgs, home-manager, nixvim, nixos-hardware, self, ...}@inputs:


    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      in {

        nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
          modules = [ 
            ./hosts/laptop
            ./modules/common   
          ]; 

        specialArgs = {
          inherit system;
          inherit inputs; 
          user = "none";
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
    };






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
}

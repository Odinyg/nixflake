{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };


  outputs = { self, nixpkgs, home-manager,  ... }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      lib = nixpkgs.lib // home-manager.lib;
      pkgs = import nixpkgs {
      inherit system;

      config = {
        allowUnfree = true;
	};
      };  
    in
    {
      inherit lib;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;


    nixosConfigurations = { 
      myNixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs system; };

	modules = [
	./hosts/laptop
	];
      };
    };
    homeConfigurations = {
      "none@nixos" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        modules = [ ./home/laptop.nix ./home/features/cli/zsh.nix ];
	extraSpecialArgs = { inherit inputs outputs; };
      };
    };

  };
}

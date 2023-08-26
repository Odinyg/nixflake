
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      # url = "/home/gaetan/perso/nix/nixvim/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        config = {
        allowUnfree = true;
	};
      };  
    in
    {

    nixosConfigurations = { 
      vm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system; };

	modules = [
	./hosts/vm
	];
      };
      vmserver = nixpkgs.lib.nixosSystem { 
        specialArgs = { inherit inputs system; };
        modules = [ 
        ./hosts/vmserver
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system; };

	modules = [
	./hosts/laptop
     
	  
	];	
  
      };
#    homeConfiguration."laptop" = home.manage.lib.homeManagerConfiguration{
#      inherit pkgs;
#      extraSpecialArgs = {inherit inputs; };
#      modules = [ ./hosts/laptop ];
#      };
    };
  };
}

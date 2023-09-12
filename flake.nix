
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
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
  outputs = { self, nixpkgs,home-manager,nixvim,nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
    nixpkgs-outPath = {
      environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
    };
      pkgs = import nixpkgs {
        inherit system;

        config = {
        allowUnfree = true;
	};
      };  
    homeManagerModules = [
      nixvim.homeManagerModules.nixvim
    ];
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
        home-manager.nixosModules.home-manager

          {
          home-manager = {
	  useGlobalPkgs = true;
          useUserPackages = true;
          users.none.imports =
          [
	  ./home/laptop.nix
	  ]
	  ++ homeManagerModules;
	  };
	  }
	];
      };
      p53= nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system; };

	modules = [
	./hosts/p53
	nixos-hardware.nixosModules.lenovo-thinkpad-p53
	nixpkgs-outPath
        home-manager.nixosModules.home-manager
        {
          home-manager = {
	  useGlobalPkgs = true;
          useUserPackages = true;
          users.odin.imports =
          [
	  ./home/p53.nix
	  ]
	  ++ homeManagerModules;
	  };
	}
	];
      };
    };
  };
}

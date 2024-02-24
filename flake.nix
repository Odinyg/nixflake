{
  description = "Heime Flake";
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
    hyprland-nix.url = "github:spikespaz/hyprland-nix";
    };
  outputs = { self, firefox-addons, nixpkgs,home-manager,nixvim,nixos-hardware,nix-colors, ... }@inputs:

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
    homeManagerModules = [
      nixvim.homeManagerModules.nixvim
      nix-colors.homeManagerModules.default
    ];
    in
    {

    nixosConfigurations = { 
      vm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system ; };

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
        specialArgs = { inherit inputs system ;};

	modules = [
	./hosts/laptop
    ./modules
    userInfo



    home-manager.nixosModules.home-manager
          {
          home-manager = {
    	  useGlobalPkgs = true;
          useUserPackages = true;
          users.none.imports =
          [
	  ./hosts/laptop/home.nix
	  ]
	  ++ homeManagerModules;
	  };
	  }
	];
      };
      p53= nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system ; };

	modules = [
	./hosts/p53
    ./modules
    userInfoWork
	nixos-hardware.nixosModules.lenovo-thinkpad-p53
	nixpkgs-outPath
        home-manager.nixosModules.home-manager
        {
          home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.odin.imports = [ ./hosts/p53/home.nix ]
	  ++ homeManagerModules;
	  };
	}
	];
      };
      station = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs system ; };

	modules = [
	./hosts/station
    ./modules
    userInfo
	nixpkgs-outPath
        home-manager.nixosModules.home-manager
        {
          home-manager = {
	  useGlobalPkgs = true;
          useUserPackages = true;
          users.none.imports =
          [
	  ./hosts/station/home.nix
	  ]
	  ++ homeManagerModules;
	  };
	}
	];
      };
    };
  };
}

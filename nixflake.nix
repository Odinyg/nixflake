{
  description = "Heime Flake";
  outputs = { self, nixpkgs,home-manager,nixvim,nixos-hardware,... }@inputs:
    let
      user = "none";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
      config = { allowUnfree = true;
                 allowUnfreePredicate = (_: true); };
    };

    # configure lib
    lib = nixpkgs.lib;
    in {


    homeConfigurations = {
      laptop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ .home/laptop/home.nix];
                    #  inputs.nix-flatpak.homeManagerModules.nix-flatpak # Declarative flatpaks
          extraSpecialArgs = {
          inherit (inputs) nixvim;
            # pass config variables from above

          };
      };
    };
    nixosConfigurations = {
      laptop = lib.nixosSystem {
        modules = [ .hosts/configuration.nix  ]; # load configuration.nix from selected PROFILE
        specialArgs = {
          # pass config variables from above
          inherit system;
          inherit user;
        };
      };
    };
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
    };
}

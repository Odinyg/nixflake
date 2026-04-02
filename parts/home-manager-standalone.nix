{
  inputs,
  ...
}:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  pkgs-unstable = import inputs.nixpkgs-unstable {
    localSystem = system;
    config.allowUnfree = true;
  };
in
{
  flake.homeConfigurations."none@station" = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs pkgs-unstable;
    };
    modules = [
      inputs.nixvim.homeModules.nixvim
      ../hosts/station-arch/home.nix
    ];
  };
}

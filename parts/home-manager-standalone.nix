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
      inputs.stylix.homeModules.stylix
      inputs.sops-nix.homeManagerModules.sops
      # standalone-compat provides options.user + options.hyprland.* + options.home-manager.users
      # Do NOT import ../modules/home-manager/default.nix — it also defines options.user (duplicate)
      ../modules/home-manager/standalone-compat.nix
      # Category defaults — each imports all its member modules
      ../modules/home-manager/cli/default.nix
      ../modules/home-manager/app/default.nix
      ../modules/home-manager/desktop/default.nix
      ../modules/home-manager/misc/default.nix
      ../hosts/station-arch/home.nix
    ];
  };
}

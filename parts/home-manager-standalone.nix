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
      ../modules/home-manager/standalone-compat.nix
      ../modules/home-manager/cli/git.nix
      ../modules/home-manager/cli/neovim/default.nix
      ../modules/home-manager/desktop/hyprland/default.nix
      ../modules/home-manager/cli/mcp.nix
      ../hosts/station-arch/home.nix
    ];
  };
}

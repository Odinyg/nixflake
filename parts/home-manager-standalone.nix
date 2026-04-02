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
      ../modules/home-manager/desktop/hyprland/packages.nix
      ../modules/home-manager/desktop/hyprland/services.nix
      ../modules/home-manager/desktop/hyprland/hyprpanel.nix
      ../modules/home-manager/desktop/hyprland/keybindings.nix
      ../modules/home-manager/desktop/hyprland/monitors.nix
      ../modules/home-manager/cli/mcp.nix
      ../modules/home-manager/app/discord.nix
      ../modules/home-manager/app/development.nix
      ../modules/home-manager/app/media.nix
      ../modules/home-manager/app/communication.nix
      ../modules/home-manager/app/utilities.nix
      ../modules/home-manager/app/lmstudio.nix
      ../modules/home-manager/misc/chromium.nix
      ../modules/home-manager/misc/zen-browser.nix
      ../modules/home-manager/misc/thunar.nix
      ../hosts/station-arch/home.nix
    ];
  };
}

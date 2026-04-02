{
  config,
  lib,
  options,
  ...
}:
let
  standalone = !(options ? nixpkgs);

  hmConfig = {
    wayland.windowManager.hyprland.extraConfig =
      if (config.hyprland.monitors.extraConfig != "") then
        config.hyprland.monitors.extraConfig
      else
        # Default fallback configuration
        ''
          # Default configuration for hosts without custom monitor setup
          workspace = 1, default:true
        '';
  };
in
{
  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.hyprland.enable hmConfig;
      }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.hyprland.enable hmConfig)
    ]
  );
}

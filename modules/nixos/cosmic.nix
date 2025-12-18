{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    cosmic = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable COSMIC desktop environment";
      };
    };
  };

  config = lib.mkIf config.cosmic.enable {
    # Enable the COSMIC login manager
    services.displayManager.cosmic-greeter.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;

    # Enable System76 scheduler for better performance
    services.system76-scheduler.enable = false;

    # Enable clipboard support by allowing all windows to access clipboard
    # This bypasses Wayland's default security measure where only focused windows
    # can set the clipboard. While less secure, it enables clipboard managers
    # and rapid copy-paste operations.
    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  };
}

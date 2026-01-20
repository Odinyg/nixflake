{
  lib,
  config,
  pkgs,
  pkgs-unstable,
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
      autoLogin = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable auto-login (recommended with disk encryption)";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "odin";
          description = "User to auto-login as";
        };
      };
    };
  };

  config = lib.mkIf config.cosmic.enable {
    # Enable the COSMIC login manager
    services.displayManager.cosmic-greeter.enable = true;

    # Auto-login (safe with disk encryption)
    services.displayManager.autoLogin = lib.mkIf config.cosmic.autoLogin.enable {
      enable = true;
      user = config.cosmic.autoLogin.user;
    };

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

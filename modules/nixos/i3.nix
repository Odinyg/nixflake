{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.i3wm = {
    enable = lib.mkEnableOption "Enable i3 window manager and display manager";
  };

  config = lib.mkIf config.i3wm.enable {
    # Enable X11 windowing system
    services.xserver = {
      enable = true;

      # Enable i3-gaps window manager
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        extraPackages = with pkgs; [
          dmenu
          i3status
        ];
      };

      # Configure display manager
      displayManager = {
        lightdm.enable = true;
        defaultSession = "none+i3";
      };
    };

    # Install i3-related packages
    environment.systemPackages = with pkgs; [
      i3-gaps
    ];
  };
}

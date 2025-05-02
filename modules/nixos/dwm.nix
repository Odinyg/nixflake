{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    dwm = {
      enable = lib.mkEnableOption {
        description = "Enable DWM window manager and dependencies";
        default = false;
      };
    };
  };

  config = lib.mkIf config.dwm.enable {
    # Install necessary packages
    environment.systemPackages = with pkgs; [
      # Window manager itself
      dwm
      dmenu
      st # Simple terminal (fallback)

      # Terminal and utilities from your config
      kitty
      brave
      flameshot

      # Status bar and appearance
      polybar
      picom
      nitrogen
      dunst

      # System utilities
      networkmanagerapplet
      lxqt.lxqt-policykit
      xclip

      # Additional utilities (common DWM companions)
      rofi
      feh
      pavucontrol
      playerctl
      brightnessctl

      # X utilities
      xorg.xrandr
      xorg.xsetroot
      xorg.xinit

      # Font for status bar
    ];

    # Enable X11 windowing system
    services.xserver = {
      enable = true;
      windowManager.dwm.enable = true;

      # Enable SDDM display manager
      displayManager = {
        sddm = {
          enable = true;
          theme = "breeze";
        };
        defaultSession = "none+dwm";
      };
    };

  };
}

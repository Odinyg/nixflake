{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.simpleI3 = {
    enable = lib.mkEnableOption "Enable i3 with display manager";

    displayManager = lib.mkOption {
      type = lib.types.enum [
        "lightdm"
        "sddm"
        "gdm"
      ];
      default = "lightdm";
      description = "Display manager to use with i3";
    };
  };

  config = lib.mkIf config.simpleI3.enable {
    # Enable X11
    services.xserver = {
      enable = true;

      # Configure keyboard
      xkb = {
        layout = "us";
        variant = "altgr-intl";
        options = "caps:escape,compose:ralt";
      };

      # Enable i3
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };

      # Configure display manager
      displayManager = {
        defaultSession = "none+i3";

        lightdm = lib.mkIf (config.simpleI3.displayManager == "lightdm") {
          enable = true;
          greeters.gtk.enable = true;
        };

        sddm = lib.mkIf (config.simpleI3.displayManager == "sddm") {
          enable = true;
        };

        gdm = lib.mkIf (config.simpleI3.displayManager == "gdm") {
          enable = true;
          wayland = false;
        };
      };
    };

    # Install required packages
    environment.systemPackages = with pkgs; [
      # i3 basics
      i3status
      i3lock
      dmenu

      # Terminal and browser
      kitty
      brave

      # File manager
      thunar

      # System tools
      xorg.xsetroot
      xorg.xinit
      xorg.xrdb
      feh
      picom
      xss-lock
      xidlehook
      rofi

      # Utils
      maim
      xclip
      lxqt.lxqt-policykit
      nm-applet
      copyq

      # Cursor theme
      bibata-cursors
    ];

    # Create user .config/i3/config if it doesn't exist
    system.activationScripts.createI3Config = ''
      mkdir -p /home/${config.user.name}/.config/i3
      if [ ! -f /home/${config.user.name}/.config/i3/config ]; then
        cp ${./example-i3-config} /home/${config.user.name}/.config/i3/config
        chown -R ${config.user.name}:users /home/${config.user.name}/.config/i3
      fi
    '';
  };
}

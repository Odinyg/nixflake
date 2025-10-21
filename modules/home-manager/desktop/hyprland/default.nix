{ config, lib, ... }: {

  imports = [
    ./packages.nix
    ./hyprpanel.nix
    ./services.nix
    ./keybindings.nix
    ./monitors.nix
  ];

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        # Startup applications
        exec-once = [
          "pypr"
          "hyprpanel & ~/.config/hypr/random-wallpaper.sh & swaync"
          "hyprctl setcursor Bibate-Modern-Ice 18"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "nm-applet --indicator"
          "systemctl --user import-environment"
          "lxqt-policykit-agent"
          "swayidle -w"
          "kanshi -c ~/.config/kanshi/config"
        ];

        # Recurring exec commands
        exec = [ "hyprshade auto" ];

        # Environment variables
        env = [
          "XDG_SESSION_TYPE,wayland"
          "WAYLAND_DISPLAY,wayland-1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
        ];

        # Input configuration
        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";
          kb_options = "caps:escape,compose:ralt";
          numlock_by_default = true;
          follow_mouse = 1;
          repeat_rate = 55;
          repeat_delay = 400;
          touchpad = { natural_scroll = false; };
          sensitivity = 0;
        };

        # General layout settings
        general = {
          gaps_in = 3;
          gaps_out = 5;
          border_size = 1;
          layout = "dwindle";
        };

        # Decoration settings
        decoration = {
          rounding = 7;
          blur = {
            enabled = true;
            size = 8;
            passes = 1;
          };
        };

        # Animations
        animations = {
          enabled = false;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 4, myBezier"
            "windowsOut, 1, 4, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 2, default"
          ];
        };

        # Dwindle layout settings
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 1;
        };

        # NVIDIA-specific cursor configuration
        cursor = {
          no_hardware_cursors = true;
          no_break_fs_vrr = true;
        };

        # NVIDIA-specific OpenGL settings
        opengl = { nvidia_anti_flicker = true; };

        # Miscellaneous settings
        misc = {
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        # Window rules
        windowrulev2 = [
          "float, class:file_progress"
          "float, class:flameshot"
          "float, class:confirm"
          "float, class:dialog"
          "float, class:download"
          "float, class:notification"
          "float, class:error"
          "float, class:splash"
          "float, class:confirmreset"
          "float, title:Open File"
          "float, title:branchdialog"
          "float, class:Rofi"
          "animation none, class:Rofi"
          "float, class:viewnior"
          "float, class:vimiv"
          "float, class:pavucontrol-qt"
          "float, class:pavucontrol"
          "float, class:file-roller"
          "fullscreen, class:wlogout"
          "float, title:wlogout"
          "fullscreen, title:wlogout"
          "idleinhibit focus, class:mpv"
          "idleinhibit fullscreen, class:firefox"
          "float, title:(Media viewer)"
          "float, title:(Volume Control)"
          "float, title:(Picture-in-Picture)"
          "size 800 600, title:(Volume Control)"
          "move 75% 44%, title:(Volume Control)"
          "noborder, class:^(chrome-.*)"
          "float, class:^(nsxiv)$"
          "size 90% 90%, class:^(nsxiv)$"
          "center, class:^(nsxiv)$"
        ];
      };
    };
  };
}

{
  config,
  lib,
  pkgs-unstable,
  ...
}:
{

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
      package = pkgs-unstable.hyprland;
      systemd.enable = true;

      settings = {
        # Startup applications
        exec-once = [
          "pypr"
          "waybar & ~/.config/hypr/random-wallpaper.sh & swaync"
          "hyprctl setcursor Bibata-Modern-Ice 18"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "nm-applet --indicator"
          "systemctl --user import-environment"
          "lxqt-policykit-agent"

          "hyprshade auto"
        ];

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
          kb_options = "compose:ralt";
          numlock_by_default = true;
          follow_mouse = 1;
          repeat_rate = 55;
          repeat_delay = 400;
          touchpad = {
            natural_scroll = false;
          };
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
        opengl = {
          nvidia_anti_flicker = true;
        };

        # Miscellaneous settings
        misc = {
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        # Window rules (new syntax: match:prop value, effect value)
        windowrule = [
          # Force remote desktop clients to tile
          "match:class ^(xfreerdp)$, float off"
          "match:class ^(com.moonlight_stream.Moonlight)$, idle_inhibit always"
          # 1Password Quick Access - stay focused and visible
          "match:title ^Quick Access, float on"
          "match:title ^Quick Access, stay_focused on"
          "match:title ^Quick Access, pin on"
          "match:class file_progress, float on"
          "match:class flameshot, float on"
          "match:class confirm, float on"
          "match:class dialog, float on"
          "match:class download, float on"
          "match:class notification, float on"
          "match:class error, float on"
          "match:class splash, float on"
          "match:class confirmreset, float on"
          "match:title Open File, float on"
          "match:title branchdialog, float on"
          "match:class Rofi, float on"
          "match:class Rofi, animation none"
          "match:class viewnior, float on"
          "match:class vimiv, float on"
          "match:class pavucontrol-qt, float on"
          "match:class pavucontrol, float on"
          "match:class file-roller, float on"
          "match:class wlogout, fullscreen on"
          "match:title wlogout, float on"
          "match:title wlogout, fullscreen on"
          "match:class mpv, idle_inhibit focus"
          "match:class firefox, idle_inhibit fullscreen"
          "match:title (Media viewer), float on"
          "match:title (Volume Control), float on"
          "match:title (Picture-in-Picture), float on"
          "match:title (Volume Control), size 800 600"
          "match:title (Volume Control), move 75% 44%"
          "match:class ^(chrome-.*), border_size 0"
          "match:class ^(nsxiv)$, float on"
          "match:class ^(nsxiv)$, size 90% 90%"
          "match:class ^(nsxiv)$, center on"
          # Waybar popup TUI windows
          "match:class ^(waybar-popup)$, float on"
          "match:class ^(waybar-popup)$, size 800 500"
          "match:class ^(waybar-popup)$, center on"
          # Gaming — keep games responsive across workspace switches
          "match:class ^(steam_app_.*)$, idle_inhibit always"
        ];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
{

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      extraConfig = ''
        workspace = 1, monitor:DP-4, default:true
        workspace = 2, monitor:DP-4
        workspace = 3, monitor:DP-4
        workspace = 4, monitor:DP-4
        workspace = 5, monitor:DP-4

        workspace = 6, monitor:DP-5, default:true
        workspace = 7, monitor:DP-5
        workspace = 8, monitor:DP-5

        workspace = 9, monitor:HDMI-A-1
        workspace = 0, monitor:HDMI-A-1
      '';

      settings = {
        "$mainMod" = "SUPER";
        exec-once = [
          "pypr"
          "waybar & hyprpaper & swaync"
          "hyprctl setcursor Bibate-Modern-Ice 18"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "nm-applet --indicator"
          "systemctl --user import-environment"
          "lxqt-policykit-agent"
          "swayidle -w"
          "kanshi -c ~/.config/kanshi/config"
        ];

        exec = [ "hyprshade auto" ];
        env = [
          "XDG_SESSION_TYPE,wayland"
          "WLR_NO_HARDWARE_CURSORS,1;"
          "WLR_RENDERER_ALLOW_SOFTWARE,1"
          "WLR_BACKENDS,n-drm"
          "WAYLAND_DISPLAY,wayland-1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          # "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          # "GBM_BACKEND,nvidia-drm"
          # "LIBVA_DRIVER_NAME,nvidia"
        ];

        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";
          kb_options = "caps:escape,compose:ralt";
          numlock_by_default = true;
          follow_mouse = 1;
          repeat_rate = 55;
          repeat_delay = 400;
          touchpad = {
            natural_scroll = false;
          };

          sensitivity = 0;
        };

        general = {
          gaps_in = 3;
          gaps_out = 5;
          border_size = 2;
          layout = "dwindle";
        };

        animations = {
          enabled = true;
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

        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 1;
        };

        gestures = {
          workspace_swipe = false;
        };

        misc = {
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
        };

        bindm = [

          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        bind = [
          "$mainMod, W, exec, app.zen_browser.zen"
          "ALT CTRL, S, exec, grim -g \"$(slurp -d)\" - | wl-copy"
          "CTRL SUPER, S, exec, grim -g \"$(slurp -d)\" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png"
          "$mainMod, return, exec, kitty"
          "$mainMod, Q, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, thunar"
          "$mainMod, V, togglefloating,"
          "$mainMod, D, exec, pgrep rofi >/dev/null 2>&1 && killall rofi || rofi -show drun"

          "$mainMod, P, pseudo,"
          "$mainMod, O, togglesplit,"
          # Focus window bindings
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"
          # Resize window bindings
          "SUPER CTRL, left, resizeactive, -20 0"
          "SUPER CTRL, right, resizeactive, 20 0"
          "SUPER CTRL, up, resizeactive, 0 -20"
          "SUPER CTRL, down, resizeactive, 0 20"
          "SUPER CTRL, H, resizeactive, -20 0"
          "SUPER CTRL, L, resizeactive, 20 0"
          "SUPER CTRL, K, resizeactive, 0 -20"
          "SUPER CTRL, J, resizeactive, 0 20"
          # Workspace bindings
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          # Move to workspace bindings
          "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
          "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
          "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
          "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
          "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
          "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
          "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
          "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
          "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
          # Mouse scroll workspace bindings
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
          # Pypr bindings
          "$mainMod, T, exec, pypr toggle term"
          "$mainMod, N, exec, pypr toggle notes"
          "$mainMod, G, exec, pypr toggle gpt"
          "$mainMod, F, exec, pypr toggle todo"
        ];

        bindl = [
          ", switch:off:Lid Switch,exec,hyprctl keyword monitor \"eDP-1, 1920x1080, 0x0, 1\""
          ", switch:on:Lid Switch,exec,hyprctl keyword monitor \"eDP-1, disable\""
        ];

        windowrule = [
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
          "float, class:feh"
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
        ];
      };
    };

    home.packages = with pkgs; [
      waybar
      hyprpaper
      grim
      eww
      swayidle
      brightnessctl
      pyprland
      swaynotificationcenter
      wmctrl
      hyprshade
      swww
      gtk-engine-murrine
      sassc
      gtk3
      lxqt.lxqt-policykit
      copyq
      swayidle
      grim
      slurp
      wl-clipboard
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper/wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/pyprland.toml".source = ./config/pyprland.toml;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."swayidle".source = ./config/swayidle;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    programs.swaylock.enable = true;
    services.kanshi = {
      enable = true;
      profiles =
        let
          hostname = config.networking.hostName;
        in
        {
          # External Monitors Profile (unchanged)
          external-monitors = lib.mkIf (hostname == "p53") {
            outputs = [
              {
                criteria = "eDP-1";
                position = "0,1920"; # Place laptop screen under HDMI (middle-bottom)
              }
              {
                criteria = "HDMI-A-1";
                mode = "1920x1080";
                transform = "90"; # rotate 90 degrees
                position = "0,0"; # Left monitor
              }
              {
                criteria = "DP-4";
                mode = "2560x1440";
                position = "1080,0"; # Middle monitor (main)
              }
              {
                criteria = "DP-5";
                mode = "1920x1080";
                position = "3640,0"; # Right monitor
              }
            ];
          };
          # Profile for 'laptop'
          laptop-only = lib.mkIf (hostname == "laptop") {
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "1920x1200";
                scale = 1.0;
              }
            ];
          };
          station-only = lib.mkIf (hostname == "station") {
            outputs = [
              {
                criteria = "DP-2";
                mode = "1920x1080@120";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "HDMI-A-2";
                mode = "3840x2160@120";
                position = "1920,0";
                scale = 1.25;
              }
            ];
          };

          # Profile for 'p53'
          p53-only = lib.mkIf (hostname == "p53") {
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "1920x1080";
                scale = 1.0;
              }
            ];
          };

          # Default Profile (if not laptop or p53)
          default = lib.mkIf (hostname != "laptop" && hostname != "p53" && hostname != "station") {
            outputs = [
              {
                criteria = "eDP-1";
                mode = "1920x1080";
                scale = 1.0;
              }
            ];
          };
        };
    };
    #    services.kanshi = {
    #      enable = true;
    #      profiles = {
    #        # Profile when external monitors are connected to HDMI-A-1
    #        external-monitors = {
    #          outputs = [
    #            {
    #              criteria = "eDP-1";
    #              status = "disable";
    #            }
    #            {
    #              criteria = "HDMI-A-1";
    #              mode = "1920x1080";
    #              transform = "90"; # transform 1 means rotate 90 degrees
    #            }
    #            {
    #              criteria = "DP-4";
    #              mode = "2560x1440";
    #            }
    #            {
    #              criteria = "DP-5";
    #              mode = "1920x1080";
    #            }
    #          ];
    #        };
    #
    #        laptop-only = {
    #          outputs = [
    #            {
    #              criteria = "eDP-1";
    #              mode = "1920x1080";
    #              scale = 1.0;
    #            }
    #          ];
    #        };
    #      };
    #    };
  };
}

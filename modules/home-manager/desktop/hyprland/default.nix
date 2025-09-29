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
          "waybar & ~/.config/hypr/random-wallpaper.sh & swaync"
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
          border_size = 1;
          layout = "dwindle";
        };

        decoration = {
          rounding = 7;
          blur = {
            enabled = true;
            size = 8;
            passes = 1;
          };
        };

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

        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 1;
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
          "$mainMod SHIFT, W, exec, ~/.config/hypr/random-wallpaper.sh"
          "$mainMod, W, exec, zen-beta"
          "ALT CTRL, S, exec, grim -g \"$(slurp -d)\" - | wl-copy"
          "CTRL SUPER, S, exec, grim -g \"$(slurp -d)\" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png | wl-copy"

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
          "$mainMod, C, exec, pypr toggle gpt"
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
          "noborder, class:^(chrome-.*)"
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
      xclip
      slurp
      wl-clipboard
      rofi
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper/wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/random-wallpaper.sh" = {
      source = ./scripts/random-wallpaper.sh;
      executable = true;
    };
    xdg.configFile."hypr/pyprland.toml".source = ./config/pyprland.toml;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."swayidle".source = ./config/swayidle;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    xdg.configFile."rofi/config.rasi".source = ./config/rofi.rasi;
    xdg.configFile."rofi/nord.rasi".source = ./config/rofi-nord.rasi;
    xdg.configFile."rofi/rounded-common.rasi".source = ./config/rounded-common.rasi;

    programs.swaylock.enable = true;
    services.kanshi = {
      enable = true;
      settings =
        let
          hostname = config.networking.hostName;
        in
        lib.optionals (hostname == "VNPC-21") [
          # External Monitors Profile for p53
          {
            profile.name = "external-monitors";
            profile.outputs = [
              {
                criteria = "eDP-1";
                position = "0,0"; # Place laptop screen under HDMI (middle-bottom)
              }
              {
                criteria = "DP-4";
                mode = "2560x1440";
                position = "1920,0"; # Middle monitor (main)
              }
              {
                criteria = "DP-5";
                mode = "2560x1440";
                position = "4480,0"; # Right monitor
              }
            ];
          }
          {
            profile.name = "p53-only";
            profile.outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "1920x1080";
                scale = 1.0;
              }
            ];
          }
        ]
        ++ lib.optionals (hostname == "laptop") [
          # Profile for laptop
          {
            profile.name = "laptop-only";
            profile.outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "1920x1200";
                scale = 1.0;
              }
            ];
          }
        ]
        ++ lib.optionals (hostname == "station") [
          # Profile for station
          {
            profile.name = "station-only";
            profile.outputs = [
              {
                criteria = "DP-2";
                mode = "2560x1440@239.96";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "HDMI-A-2";
                mode = "1920x1080@144";
                position = "-1920,0";
                scale = 1.0;
              }
            ];
          }
        ]
        ++ lib.optionals (hostname != "laptop" && hostname != "p53" && hostname != "station") [
          # Default Profile
          {
            profile.name = "default";
            profile.outputs = [
              {
                criteria = "eDP-1";
                mode = "1920x1080";
                scale = 1.0;
              }
            ];
          }
        ];
    };

    # Profile for 'p53'
  };
}

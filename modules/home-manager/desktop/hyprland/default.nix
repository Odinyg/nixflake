{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    hyprland = {
      enable = lib.mkEnableOption {
        description = "Enable  hyprland.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        "$mainMod" = "SUPER";
        exec-once = [
          "waybar & hyprpaper & swaync"
          "ulauncher --hide-window"
          "hyprctl setcursor Bibate-Modern-Ice 18"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "systemctl --user import-environment"
          "ulauncher --hide-window"
          "lxqt-policykit-agent"
          "copyq --start-server"
          "swayidle -w"
          "/etc/profiles/per-user/none/bin/pypr"
        ];

        exec = [ "hyprshade auto" ];

        monitor = [
          "HDMI-A-2,3840x2160@119.88,1920x0,1.25"
          "DP-2,1920x1080@119.88,0x0,1"
        ];

        env = [
          "XDG_SESSION_TYPE,wayland"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "XDG_CURRENT_DESKTOP,sway"
        ];

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
          "float, file_progress"
          "float, flameshot"
          "float, confirm"
          "float, dialog"
          "float, download"
          "float, notification"
          "float, error"
          "float, splash"
          "float, confirmreset"
          "float, title:Open File"
          "float, title:branchdialog"
          "float, Lxappearance"
          "float, Rofi"
          "animation none,Rofi"
          "float,viewnior"
          "float,feh"
          "float, pavucontrol-qt"
          "float, pavucontrol"
          "float, file-roller"
          "fullscreen, wlogout"
          "float, title:wlogout"
          "fullscreen, title:wlogout"
          "idleinhibit focus, mpv"
          "idleinhibit fullscreen, firefox"
          "float, title:^(Media viewer)$"
          "float, title:^(Volume Control)$"
          "float, title:^(Picture-in-Picture)$"
          "size 800 600, title:^(Volume Control)$"
          "move 75 44%, title:^(Volume Control)$"
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
      rofi-wayland
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper/wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/pyprland.toml".source = ./config/pyprland.toml;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."swayidle".source = ./config/swayidle;
    xdg.configFile."rofi/nord.rasi".source = ./config/rofi-nord.rasi;
    xdg.configFile."rofi/rounded-common.rasi".source = ./config/rounded-common.rasi;
    xdg.configFile."rofi/config.rasi".source = ./config/rofi.rasi;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    programs.swaylock.enable = true;

  };
}

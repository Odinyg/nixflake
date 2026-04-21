{ config, lib, ... }:
{

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      "$mainMod" = "SUPER";

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Volume/brightness keys (repeatable)
      bindel = [
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86MonoBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonoBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # Toggle keys (non-repeating)
      bindl = [
        '', switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1, 1920x1080, 0x0, 1"''
        '', switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable"''
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
      ];

      # Keyboard bindings
      bind = [
        # Wallpaper & Browser
        "$mainMod SHIFT, W, exec, ~/.config/hypr/random-wallpaper.sh"
        "$mainMod, W, exec, zen-beta"

        # Screenshots — region to clipboard + file + notification
        ''ALT CTRL, S, exec, mkdir -p ~/Pictures/screenshots && grim -g "$(slurp -d)" - | tee ~/Pictures/screenshots/screenshot-$(date '+%Y%m%d-%H%M%S').png | wl-copy && notify-send "Screenshot" "Copied to clipboard and saved" -t 2000''

        # Applications
        "$mainMod, return, exec, ghostty"
        "$mainMod, E, exec, thunar"
        "$mainMod, D, exec, pgrep rofi >/dev/null 2>&1 && killall rofi || rofi -show drun -hshow-icons"

        # Window Management
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod SHIFT, F, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, O, togglesplit,"
        "$mainMod, U, togglesplit,"

        # Focus window bindings (Arrow keys)
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Focus window bindings (Vim keys)
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Move window bindings (Vim keys)
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, L, movewindow, r"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, J, movewindow, d"

        # Resize window bindings (Arrow keys)
        "SUPER CTRL, left, resizeactive, -20 0"
        "SUPER CTRL, right, resizeactive, 20 0"
        "SUPER CTRL, up, resizeactive, 0 -20"
        "SUPER CTRL, down, resizeactive, 0 20"

        # Resize window bindings (Vim keys)
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

        # Pyprland scratchpad bindings
        "$mainMod, T, exec, pypr toggle term"
        "$mainMod, N, exec, pypr toggle notes"
        "$mainMod, F, exec, pypr toggle todo"
        "$mainMod, G, exec, pypr toggle scratch"
        "$mainMod SHIFT, G, exec, pypr toggle daily"
        "$mainMod, V, exec, pypr toggle vault"
        "$mainMod, R, exec, pypr toggle cheatsheet-search"
      ];

    };
  };
}

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.plasma;

  screenshotRegion = pkgs.writeShellScript "screenshot-region" ''
    mkdir -p ~/Pictures/screenshots
    grim -g "$(slurp -d)" - \
      | tee ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png \
      | wl-copy
    notify-send "Screenshot" "Copied to clipboard and saved" -t 2000
  '';

  rofiToggle = pkgs.writeShellScript "rofi-toggle" ''
    if pgrep rofi >/dev/null 2>&1; then
      killall rofi
    else
      rofi -show drun -hshow-icons
    fi
  '';

  pwaLauncher =
    name: url:
    pkgs.writeShellScript "pwa-${name}" ''
      launch-or-focus brave-${name} "brave --app=${url}"
    '';
in
{
  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;

      configFile.kwinrc = {
        # Focus follows mouse, no auto-raise (Hyprland follow_mouse=1 behavior)
        Windows = {
          FocusPolicy = "FocusFollowsMouse";
          AutoRaise = false;
          ClickRaise = true;
          DelayFocusInterval = 0;
        };

        # Super+drag = move, Super+right-drag = resize (Hyprland bindm)
        MouseBindings = {
          CommandAllKey = "Meta";
          CommandAll1 = "Move";
          CommandAll2 = "Toggle raise and lower";
          CommandAll3 = "Resize";
        };

        # Gap between tiled windows (matches Hyprland gaps_in=3)
        Tiling.padding = 3;
      };

      kwin.virtualDesktops.names = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];

      kwin.scripts.polonium = {
        enable = true;
        settings = {
          # BSP layout — matches Hyprland's dwindle
          layout.engine = "binaryTree";
          # Hide borders when there's only one window per screen
          borderVisibility = "noBorderTiled";
          # Default; set true if you want single windows to fill the screen
          maximizeSingleWindow = false;
          tilePopups = false;
          # Skip auto-tiling for games / launchers — matched against WM_CLASS
          filter.processes = [
            "steam"
            "steam_app_.*"
            "lutris"
            "heroic"
            "EscapeFromTarkov.exe"
            "BsgLauncher.exe"
            "Wow.exe"
            "WowClassic.exe"
            "Battle.net.exe"
            "wine.*"
            "explorer.exe"
          ];
        };
      };

      shortcuts = {
        # Window focus — vim keys (Hyprland: $mainMod H/J/K/L)
        kwin = {
          "Switch Window Left" = [
            "Meta+H"
            "Meta+Left"
          ];
          "Switch Window Right" = [
            "Meta+L"
            "Meta+Right"
          ];
          "Switch Window Up" = [
            "Meta+K"
            "Meta+Up"
          ];
          "Switch Window Down" = [
            "Meta+J"
            "Meta+Down"
          ];

          # Move window via Quick Tile (Hyprland: $mainMod SHIFT H/J/K/L)
          "Window Quick Tile Left" = "Meta+Shift+H";
          "Window Quick Tile Right" = "Meta+Shift+L";
          "Window Quick Tile Top" = "Meta+Shift+K";
          "Window Quick Tile Bottom" = "Meta+Shift+J";

          # Window management
          "Window Close" = "Meta+Q";
          "Toggle Window Floating" = "Meta+Shift+F";

          # Free up keys reclaimed by hotkeys.commands below
          "Overview" = "none";
          "Show Desktop" = "none";

          # Virtual desktops 1-9 (Hyprland: $mainMod 1-9)
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Switch to Desktop 5" = "Meta+5";
          "Switch to Desktop 6" = "Meta+6";
          "Switch to Desktop 7" = "Meta+7";
          "Switch to Desktop 8" = "Meta+8";
          "Switch to Desktop 9" = "Meta+9";

          # Move window to desktop (Hyprland: $mainMod SHIFT 1-9)
          # Plasma 6 Wayland resolves Shift+digit to the shifted symbol — bind that form
          "Window to Desktop 1" = "Meta+!";
          "Window to Desktop 2" = "Meta+@";
          "Window to Desktop 3" = "Meta+#";
          "Window to Desktop 4" = "Meta+$";
          "Window to Desktop 5" = "Meta+%";
          "Window to Desktop 6" = "Meta+^";
          "Window to Desktop 7" = "Meta+&";
          "Window to Desktop 8" = "Meta+*";
          "Window to Desktop 9" = "Meta+(";
        };

        # Logout (Hyprland: $mainMod M = exit)
        ksmserver = {
          "Log Out" = "Meta+M";
        };
      };

      # Custom command launchers — mirror Hyprland exec binds
      hotkeys.commands = {
        # Applications
        "launch-ghostty" = {
          name = "Ghostty terminal";
          key = "Meta+Return";
          command = "ghostty";
        };
        "launch-thunar" = {
          name = "Thunar file manager";
          key = "Meta+E";
          command = "thunar";
        };
        "launch-brave" = {
          name = "Brave browser";
          key = "Meta+W";
          command = "brave";
        };
        "launch-rofi" = {
          name = "Rofi app launcher";
          key = "Meta+D";
          command = toString rofiToggle;
        };

        # Screenshot — region to clipboard + file + notification
        "screenshot-region" = {
          name = "Region screenshot";
          key = "Ctrl+Alt+S";
          command = toString screenshotRegion;
        };

        # Wallpaper cycle
        "wallpaper-next" = {
          name = "Next wallpaper";
          key = "Meta+Shift+W";
          command = "wayle wallpaper next";
        };

        # Brave PWAs — focus existing window or launch
        "pwa-youtube-music" = {
          name = "YouTube Music PWA";
          key = "Meta+Y";
          command = toString (pwaLauncher "music.youtube.com" "https://music.youtube.com");
        };
        "pwa-claude" = {
          name = "Claude PWA";
          key = "Meta+C";
          command = toString (pwaLauncher "claude" "https://claude.ai");
        };
        "pwa-teams" = {
          name = "Teams PWA";
          key = "Meta+Shift+T";
          command = toString (pwaLauncher "teams" "https://teams.cloud.microsoft/");
        };
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  # Extract all frames from dynamic HEIC wallpapers into PNGs at build time
  dynamicWallpapers =
    pkgs.runCommand "dynamic-wallpapers"
      {
        nativeBuildInputs = [ pkgs.libheif ];
      }
      ''
        mkdir -p $out
        for heic in ${../Dynamic_wallpaper}/*.heic; do
          name=$(basename "$heic" .heic | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          heif-dec "$heic" "$out/$name.png"
        done
      '';
in
{

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    home.packages =
      (with pkgs-unstable; [
        # Core Hyprland ecosystem (from unstable for latest features)
        waybar # Status bar
        hyprpanel # Alternative panel
        hyprpaper # Wallpaper daemon
        pyprland # Scratchpad & window manager plugins
        hyprshade # Shader control
        pulsemixer # TUI volume control
        bluetuith # TUI bluetooth manager
        gnome-calendar # Calendar app
        gnome-online-accounts # Account sync (Nextcloud, Google, etc.)
        gnome-control-center # Settings GUI for GNOME Online Accounts
        vdirsyncer # CalDAV/CardDAV sync daemon
        khal # TUI calendar
        # khard # TUI contacts — disabled: upstream build broken (sphinx-argparse incompatibility)
        calcurse # TUI calendar with built-in CalDAV
        endeavour # GNOME Tasks with CalDAV sync
        evolution # Mail, calendar, contacts (GNOME Online Accounts)
        onedrive # OneDrive sync client
        onedrivegui # GUI for OneDrive client
        nextcloud-client # Nextcloud file sync
        nextcloud-talk-desktop # Nextcloud Talk desktop app
      ])
      ++ (with pkgs; [
        # Screenshot & Image Tools
        grim # Screenshot tool
        slurp # Region selector
        satty # Screenshot annotation editor
        vimiv-qt # Image viewer
        libnotify # Desktop notifications (notify-send)

        # Window Management
        wmctrl # Window control utility

        # Appearance & Theming
        gtk-engine-murrine # GTK engine
        sassc # Sass compiler for themes
        gtk3 # GTK3 libraries

        # Notifications & UI
        swaynotificationcenter # Notification daemon
        eww # ElKowar's Wacky Widgets
        rofi # Application launcher
        brightnessctl # Brightness control

        # Authentication & Security
        lxqt.lxqt-policykit # PolicyKit authentication agent

        # Clipboard & Selection
        xclip # X11 clipboard tool
        wl-clipboard # Wayland clipboard utilities
        wl-clip-persist
      ]);

    # XDG config files
    xdg.configFile = {
      # Dynamic wallpapers — extracted from HEIC at build time
      "wallpapers".source = dynamicWallpapers;
      "hypr/random-wallpaper.sh" = {
        source = ./scripts/random-wallpaper.sh;
        executable = true;
      };
      "hypr/pyprland.toml".source = ./config/pyprland.toml;
      "hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
      "hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
      "waybar-base".source = ./config/waybar;
      "rofi-base/config.rasi".source = ./config/rofi.rasi;
      "rofi-base/nord.rasi".source = ./config/rofi-nord.rasi;
      "rofi-base/rounded-common.rasi".source = ./config/rounded-common.rasi;
    };

    home.activation.initWaybar = {
      after = [ "linkGeneration" ];
      before = [ ];
      data = ''
        if [ ! -d "$HOME/.config/waybar" ] || [ -L "$HOME/.config/waybar" ]; then
          rm -rf "$HOME/.config/waybar"
          cp -rL "$HOME/.config/waybar-base" "$HOME/.config/waybar"
          chmod -R u+w "$HOME/.config/waybar"
        fi
      '';
    };

    home.activation.initRofi = {
      after = [ "linkGeneration" ];
      before = [ ];
      data = ''
        if [ ! -d "$HOME/.config/rofi" ] || [ -L "$HOME/.config/rofi" ]; then
          rm -rf "$HOME/.config/rofi"
          mkdir -p "$HOME/.config/rofi"
          cp -rL "$HOME/.config/rofi-base/." "$HOME/.config/rofi/"
          chmod -R u+w "$HOME/.config/rofi"
        fi
      '';
    };
  };
}

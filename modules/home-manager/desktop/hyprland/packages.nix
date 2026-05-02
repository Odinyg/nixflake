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
        wayle # Wayland Elements — bar, notifications, OSD, wallpaper (HyprPanel successor)
        awww # Wallpaper daemon (wayle's wallpaper backend; was swww, renamed upstream)
        pyprland # Scratchpad & window manager plugins
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
      "hypr/wallpapers".source = dynamicWallpapers;
      "pypr/config.toml".source = ./config/pyprland.toml;
      # Companion theme imported by rofi-nord.rasi (resolved relative to ~/.config/rofi/)
      "rofi/rounded-common.rasi".source = ./config/rounded-common.rasi;
    };

    # Custom Nord/rounded theme — opt out of stylix's auto-generated rofi theme.
    stylix.targets.rofi.enable = false;
    programs.rofi = {
      enable = true;
      terminal = "${pkgs.ghostty}/bin/ghostty";
      font = "Roboto 12";
      theme = ./config/rofi-nord.rasi;
      extraConfig = {
        modes = "combi";
        combi-modes = [
          "window"
          "drun"
          "run"
        ];
        drun-match-fields = [
          "name"
          "generic"
          "keywords"
          "categories"
        ];
        run-shell-command = "{terminal} -e {cmd}";
        show-icons = true;
      };
    };
  };
}

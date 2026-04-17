{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.security;
in
{
  options = {
    security = {
      enable = lib.mkEnableOption "security tools like Wireshark";

      insecurePackages = {
        enable = lib.mkEnableOption "Allow specific insecure packages that are required for compatibility";
      };
    };
  };

  config = lib.mkMerge [
    # Insecure packages configuration
    (lib.mkIf cfg.insecurePackages.enable {
      nixpkgs.config.permittedInsecurePackages = [
        # GUI/Desktop related
        "libsoup-2.74.3" # Required for various GNOME/GTK applications

        # Electron versions - Required for specific applications
        "electron-19.1.9" # Required for older Electron apps
        "electron-25.9.0" # Required for specific productivity tools
        "electron-29.4.6" # Required for certain development tools

        # Legacy dependencies
        "openssl-1.1.1w" # Required for legacy applications needing OpenSSL 1.1

        # Matrix clients
        "olm-3.2.16" # Required by nheko (libolm deprecated but no alternative yet)
      ];
    })

    # Security tools configuration (Wireshark, etc.)
    (lib.mkIf cfg.enable {
      # Enable Wireshark with proper capabilities for packet capture and USB monitoring
      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };

      users.users.${config.user}.extraGroups = [ "wireshark" ];

      services.udev.extraRules = ''
        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
      '';
    })
  ];
}

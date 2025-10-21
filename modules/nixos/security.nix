{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    security = {
      enable = lib.mkEnableOption {
        description = "Enable security tools like Wireshark";
        default = false;
      };
    };

    security.insecurePackages = {
      enable = lib.mkEnableOption {
        description = "Allow specific insecure packages that are required for compatibility";
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    # Insecure packages configuration
    (lib.mkIf config.security.insecurePackages.enable {
      nixpkgs.config.permittedInsecurePackages = [
        # GUI/Desktop related
        "libsoup-2.74.3"      # Required for various GNOME/GTK applications

        # Electron versions - Required for specific applications
        "electron-19.1.9"     # Required for older Electron apps
        "electron-25.9.0"     # Required for specific productivity tools
        "electron-29.4.6"     # Required for certain development tools

        # Legacy dependencies
        "openssl-1.1.1w"      # Required for legacy applications needing OpenSSL 1.1
      ];
    })

    # Security tools configuration (Wireshark, etc.)
    (lib.mkIf config.security.enable {
      # Enable Wireshark with proper capabilities for packet capture and USB monitoring
      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };

      # Add the configured user to wireshark group for packet capture permissions
      users.users.${config.user}.extraGroups = [ "wireshark" ];

      # Add udev rules to allow wireshark group access to USB monitoring devices
      services.udev.extraRules = ''
        # Allow wireshark group to access usbmon devices for USB packet capture
        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
      '';
    })
  ];
}
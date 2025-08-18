{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    security.insecurePackages = {
      enable = lib.mkEnableOption {
        description = "Allow specific insecure packages that are required for compatibility";
        default = true;
      };
    };
  };

  config = lib.mkIf config.security.insecurePackages.enable {
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
  };
}
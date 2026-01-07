{ lib, config, pkgs, ... }:
{
  options = {
    protonvpn = {
      enable = lib.mkEnableOption "ProtonVPN";
    };
  };

  config = lib.mkIf config.protonvpn.enable {
    # Install ProtonVPN GUI
    environment.systemPackages = with pkgs; [
      protonvpn-gui
    ];

    # Enable required services for VPN
    services.resolved.enable = true;
  };
}

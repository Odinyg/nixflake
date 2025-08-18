{ lib, config, ... }:
{
  options = {
    firewall = {
      enable = lib.mkEnableOption {
        description = "Enable firewall configuration";
        default = true;
      };
    };
  };

  config = lib.mkIf config.firewall.enable {
    networking.firewall = {
      enable = true;
      # Allow only necessary ports
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}
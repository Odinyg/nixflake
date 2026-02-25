{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.init-net;
in
{
  options = {
    init-net = {
      enable = lib.mkEnableOption "Enable internet sharing on ethernet interface";
      interface = lib.mkOption {
        type = lib.types.str;
        default = "enp45s0u2u3";
        description = "Internal ethernet interface to share internet on";
      };
      externalInterface = lib.mkOption {
        type = lib.types.str;
        default = "wlp82s0";
        description = "External interface with internet access (e.g. WiFi)";
      };
      subnets = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            address = lib.mkOption {
              type = lib.types.str;
              description = "IP address for this subnet";
            };
            network = lib.mkOption {
              type = lib.types.str;
              description = "Network CIDR for this subnet";
            };
          };
        });
        default = [
          { address = "192.168.1.99"; network = "192.168.1.0/24"; }
          { address = "192.168.2.99"; network = "192.168.2.0/24"; }
          { address = "192.168.250.99"; network = "192.168.250.0/24"; }
        ];
        description = "Subnets to configure on the internal interface";
      };
      dns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "8.8.8.8" "8.8.4.4" ];
        description = "DNS servers for DHCP clients";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };

    # Configure the ethernet interface with multiple IP addresses
    networking.interfaces.${cfg.interface} = {
      ipv4.addresses = map (s: {
        address = s.address;
        prefixLength = 24;
      }) cfg.subnets;
    };

    # Disable NetworkManager for this interface
    networking.networkmanager.unmanaged = [ cfg.interface ];

    # Enable NAT for internet sharing
    networking.nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = cfg.externalInterface;
      internalInterfaces = [ cfg.interface ];
      internalIPs = map (s: s.network) cfg.subnets;
    };

    # DHCP server for connected devices using dnsmasq
    services.dnsmasq = {
      enable = false;
      settings = {
        interface = cfg.interface;
        bind-interfaces = true;
        dhcp-range = lib.concatMap (s:
          let
            # Extract base from address (e.g. "192.168.1" from "192.168.1.99")
            parts = lib.splitString "." s.address;
            base = lib.concatStringsSep "." (lib.take 3 parts);
            host = lib.last parts;
          in [
            "${base}.1,${base}.${toString (lib.toInt host - 1)},24h"
            "${base}.${toString (lib.toInt host + 1)},${base}.254,24h"
          ]
        ) cfg.subnets;
        dhcp-option = [
          "option:router,${(builtins.head cfg.subnets).address}"
          "option:dns-server,${lib.concatStringsSep "," cfg.dns}"
        ];
        dhcp-authoritative = true;
      };
    };

    # Firewall configuration
    networking.firewall = {
      enable = true;
      interfaces.${cfg.interface} = {
        allowedTCPPorts = [ 22 53 ];
        allowedUDPPorts = [ 53 67 68 ];
      };
    };
  };
}

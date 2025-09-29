{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    init-net = {
      enable = lib.mkEnableOption "Enable internet sharing on ethernet interface";
    };
  };

  config = lib.mkIf config.init-net.enable {
    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };

    # Configure the ethernet interface with multiple IP addresses
    networking.interfaces.enp45s0u2u3 = {
      ipv4.addresses = [
        {
          address = "192.168.1.99";
          prefixLength = 24;
        }
        {
          address = "192.168.2.99";
          prefixLength = 24;
        }
        {
          address = "192.168.250.99";
          prefixLength = 24;
        }
      ];
    };

    # Disable NetworkManager for this interface
    networking.networkmanager.unmanaged = [ "enp45s0u2u3" ];

    # Enable NAT for internet sharing
    networking.nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "wlp82s0";
      internalInterfaces = [ "enp45s0u2u3" ];
      internalIPs = [
        "192.168.1.0/24"
        "192.168.2.0/24"
        "192.168.250.0/24"
      ];
    };

    # Enable IP masquerading
    # networking.firewall.extraCommands = ''
    #   iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o wlp82s0 -j MASQUERADE
    #   iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o wlp82s0 -j MASQUERADE
    #   iptables -t nat -A POSTROUTING -s 192.168.250.0/24 -o wlp82s0 -j MASQUERADE
    # '';

    # DHCP server for connected devices using dnsmasq
    services.dnsmasq = {
      enable = false;
      settings = {
        interface = "enp45s0u2u3";
        bind-interfaces = true;
        dhcp-range = [
          "192.168.1.1,192.168.1.98,24h"
          "192.168.1.100,192.168.1.254,24h"
          "192.168.2.1,192.168.2.98,24h"
          "192.168.2.100,192.168.2.254,24h"
          "192.168.250.1,192.168.250.98,24h"
          "192.168.250.100,192.168.250.254,24h"
        ];
        dhcp-option = [
          "option:router,192.168.1.99"
          "option:dns-server,8.8.8.8,8.8.4.4"
        ];
        dhcp-authoritative = true;
      };
    };

    # Firewall configuration
    networking.firewall = {
      enable = true;
      interfaces.enp45s0u2u3.allowedTCPPorts = [
        22
        53
      ];
      interfaces.enp45s0u2u3.allowedUDPPorts = [
        53
        67
        68
      ];
    };
  };
}

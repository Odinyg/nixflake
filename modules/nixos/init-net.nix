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
      "net.ipv6.conf.all.forwarding" = 1;
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
      externalInterface = "wlp82s0";
      internalInterfaces = [ "enp45s0u2u3" ];
      internalIPs = [
        "192.168.1.0/24"
        "192.168.2.0/24"
        "192.168.250.0/24"
      ];
    };

    # DHCP server for connected devices
    services.dhcpd4 = {
      enable = true;
      interfaces = [ "enp45s0u2u3" ];
      extraConfig = ''
        subnet 192.168.1.0 netmask 255.255.255.0 {
          range 192.168.1.10 192.168.1.98;
          option routers 192.168.1.99;
          option domain-name-servers 8.8.8.8, 8.8.4.4;
          default-lease-time 600;
          max-lease-time 7200;
        }

        subnet 192.168.2.0 netmask 255.255.255.0 {
          range 192.168.2.10 192.168.2.98;
          option routers 192.168.2.99;
          option domain-name-servers 8.8.8.8, 8.8.4.4;
          default-lease-time 600;
          max-lease-time 7200;
        }

        subnet 192.168.250.0 netmask 255.255.255.0 {
          range 192.168.250.10 192.168.250.98;
          option routers 192.168.250.99;
          option domain-name-servers 8.8.8.8, 8.8.4.4;
          default-lease-time 600;
          max-lease-time 7200;
        }
      '';
    };

    # Firewall configuration
    networking.firewall = {
      enable = true;
      interfaces.enp45s0u2u3.allowedTCPPorts = [ 22 53 ];
      interfaces.enp45s0u2u3.allowedUDPPorts = [ 53 67 68 ];
    };
  };
}
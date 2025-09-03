{
  lib,
  config,
  pkgs,
  ...
}:
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
      enable = false;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      
      # Allow incoming FTP data connections for active mode
      allowedTCPPortRanges = [
        { from = 50000; to = 52000; }  # Active FTP incoming data ports
      ];

      # Trust all libvirt interfaces
      trustedInterfaces = [
        "virbr+"
        "vnet+"
      ];
    };

    # Ensure NAT works for libvirt (moved outside firewall config since firewall is disabled)
    networking.nftables.enable = false;
    networking.firewall.extraCommands = ''
      # Check if the rule already exists before adding
      if ! iptables -t nat -C POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE 2>/dev/null; then
        iptables -t nat -A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
      fi
    '';

    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
    
    # Load FTP connection tracking modules for proper NAT handling
    boot.kernelModules = [ "nf_conntrack_ftp" "nf_nat_ftp" ];

    # Ensure libvirt default network autostarts
    systemd.services.libvirtd-config = {
      description = "Configure libvirt default network";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "setup-libvirt-network" ''
          #!${pkgs.bash}/bin/bash
          # Wait for libvirtd to be ready
          sleep 2

          # Ensure default network exists and is autostarted
          if ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "default"; then
            ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
            ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
          fi
        '';
      };
    };
  };
}

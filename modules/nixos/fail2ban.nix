{ lib, pkgs, config, ... }:

{
  options = {
    fail2ban-security = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable fail2ban intrusion prevention system";
      };
    };
  };

  config = lib.mkIf config.fail2ban-security.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h"; # 1 week
      };

      jails = {
        # SSH protection
        sshd = {
          enabled = true;
          filter = "sshd";
          action = "iptables-multiport[name=SSH, port=\"ssh\", protocol=tcp]";
          maxretry = 3;
          bantime = "1h";
          findtime = "10m";
        };

        # Additional security jails
        apache-auth = {
          enabled = false;
        };
        apache-badbots = {
          enabled = false;
        };
        apache-noscript = {
          enabled = false;
        };
        apache-overflows = {
          enabled = false;
        };
      };
    };

    # Ensure iptables is available for fail2ban
    networking.firewall.enable = true;

    # Kernel security hardening
    boot.kernel.sysctl = {
      # Disable IP forwarding
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;

      # Disable ICMP redirects
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;

      # Ignore ICMP ping requests
      "net.ipv4.icmp_echo_ignore_all" = 1;

      # Log suspicious packets
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;

      # Ignore broadcast requests
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

      # Disable source packet routing
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;

      # Enable reverse path filtering
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # TCP SYN flood protection
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_syn_retries" = 2;
      "net.ipv4.tcp_synack_retries" = 2;
      "net.ipv4.tcp_max_syn_backlog" = 4096;
    };

    # Log fail2ban activity
    systemd.services.fail2ban.serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/log/fail2ban";
    };
  };
}
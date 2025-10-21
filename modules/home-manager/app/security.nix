{ config, pkgs, lib, ... }: {
  # Home-manager component for security tools
  # The security.enable option is declared in modules/nixos/security.nix

  config.home-manager.users.${config.user} = lib.mkIf config.security.enable {
    # Security tools and utilities
    home.packages = with pkgs; [
      # Wireshark is configured at NixOS level (modules/nixos/security.nix)
      # to provide proper packet capture capabilities including usbmon
    ];
  };
}

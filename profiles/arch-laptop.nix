{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./arch-base.nix ];

  # ==============================================================================
  # ARCH LAPTOP-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Work-specific for laptop
  crypt.enable = true;

  # Laptop-specific styling
  styling.opacity.terminal = 0.92;  # Better for battery life
  styling.cursor.size = 18;         # Smaller for laptop screen

  # ==============================================================================
  # USER SERVICES (managed by systemd --user)
  # ==============================================================================
  services = {
    # These are Home Manager services (systemd --user units)
    playerctld.enable = true;  # Media key daemon for laptop
  };

  # ==============================================================================
  # LAPTOP-SPECIFIC ARCH PACKAGES
  # ==============================================================================
  archPackages = {
    additionalPackages = [
      # Power management
      "tlp"
      "powertop"
      "thermald"
      "power-profiles-daemon"
      "upower"
      
      # Laptop hardware
      "brightnessctl"
      "light"
      "acpi"
      "acpid"
      
      # Battery monitoring
      "acpi_call"
    ];
  };
}
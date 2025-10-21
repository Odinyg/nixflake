{ config, pkgs, lib, ... }: {

  options = {
    media = {
      enable = lib.mkEnableOption {
        description = "Enable media applications";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.media.enable {
    home.packages = with pkgs; [
      # Video & Audio
      vlc            # Media player

      # Image Editing
      pinta          # Simple image editor
      kdePackages.kolourpaint  # Paint program

      # Note Taking & Drawing
      xournalpp      # Note-taking and PDF annotation

      # 3D Printing
      orca-slicer    # 3D printing slicer
      curaengine_stable  # Cura slicing engine
    ];
  };
}

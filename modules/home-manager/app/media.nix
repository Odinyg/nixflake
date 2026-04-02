{
  config,
  lib,
  options,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  standalone = !(options ? nixpkgs);

  hmConfig = {
    home.packages = with pkgs; [
      # Video & Audio
      vlc # Media player

      # Image Editing
      gimp # Advanced image editor
      pinta # Simple image editor
      kdePackages.kolourpaint # Paint program

      # Note Taking & Drawing
      xournalpp # Note-taking and PDF annotation

      # 3D Printing
      pkgs-unstable.orca-slicer # 3D printing slicer (unstable)
      curaengine_stable # Cura slicing engine
    ];
  };
in
{
  options = {
    media = {
      enable = lib.mkEnableOption "media applications";
    };
  };

  config = lib.mkMerge (
    [
      { home-manager.users.${config.user} = lib.mkIf config.media.enable hmConfig; }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.media.enable hmConfig)
    ]
  );
}

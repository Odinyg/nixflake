{ lib, config, ... }:
let
  cfg = config.plasma;
in
{
  options.plasma.enable = lib.mkEnableOption "KDE Plasma 6 desktop environment";

  config = lib.mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
  };
}

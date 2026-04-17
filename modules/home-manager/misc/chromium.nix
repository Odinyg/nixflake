{ config, lib, ... }:
let
  cfg = config.chromium;
in
{

  options = {
    chromium = {
      enable = lib.mkEnableOption "Chromium browser";
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {

    programs.google-chrome.enable = true;
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--ozone-platform=wayland"
        "--gtk-version=4"
        "--enable-wayland-ime"
      ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
        { id = "nkgllhigpcljnhoakjkgaieabnkmgdkb"; } # dont f with past
        { id = "fihnjjcciajhdojfnbdddfaoknhalnja"; } # idka coockies
        { id = "fkhfakakdbjcdipdgnbfngaljiecclaf"; } # unhoocked
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # pass
        { id = "ankepacjgoajhjpenegknbefpmfffdic"; } # hide shorts
        { id = "ijaabbaphikljkkcbgpbaljfjpflpeoo"; } # Favicon changer
        { id = "hgenngnjgfkdggambccohomebieocekm"; } # open list
        { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; } # youtube enhancer

      ];
    };

  };
}

{ config, lib, ... }:
{

  options = {
    chromium = {
      enable = lib.mkEnableOption "Chromium browser";
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.chromium.enable {

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
        # { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
        #  { id = "abehfkkfjlplnjadfcjiflnejblfmmpj"; } # Nord
        { id = "fkhfakakdbjcdipdgnbfngaljiecclaf"; } # unhoocked
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # pass
        { id = "ankepacjgoajhjpenegknbefpmfffdic"; } # hide shorts
        { id = "ijaabbaphikljkkcbgpbaljfjpflpeoo"; } # Favicon changer
        { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
        { id = "hgenngnjgfkdggambccohomebieocekm"; } # open list
        { id = "nbdfpcokndmapcollfpjdpjlabnibjdi"; } # saka
        { id = "bfhkfdnddlhfippjbflipboognpdpoeh"; } # reMarkable
        { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; } # youtube enhancer

      ];
    };

  };
}

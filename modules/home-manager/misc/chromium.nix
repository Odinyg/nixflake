{config, lib, ... }: {

  options = {
    chromium = {
      enable = lib.mkEnableOption {
        description = "Enable several chromium";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user}= lib.mkIf config.chromium.enable {

  programs.chromium = {
    enable = true;
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
      { id = "becfinhbfclcgokjlobojlnldbfillpf"; } # Chat
      { id = "ijihchgjhagfhdkhagnmlebpepjlecml"; } # Chat
      { id = "bfhkfdnddlhfippjbflipboognpdpoeh"; } # Chat

    ];
  };

  programs.brave= {
    enable = true;
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
      { id = "becfinhbfclcgokjlobojlnldbfillpf"; } # Chat
      { id = "ijihchgjhagfhdkhagnmlebpepjlecml"; } # Chat
      { id = "bfhkfdnddlhfippjbflipboognpdpoeh"; } # Chat
    ];
  };



  };
}

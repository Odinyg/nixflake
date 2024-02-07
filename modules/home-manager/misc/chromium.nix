{config, lib, ... }: {

  options = {
    chromeium = {
      enable = lib.mkEnableOption {
        description = "Enable several chromeium";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user}= lib.mkIf config.chromeium.enable {

  programs.chromium = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
      { id = "nkgllhigpcljnhoakjkgaieabnkmgdkb"; } # dont f with past
      { id = "fihnjjcciajhdojfnbdddfaoknhalnja"; } # idka coockies
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
      { id = "dhlnjfhjjbminbjbegeiijdakdkamjoi"; } # Nord
      { id = "fkhfakakdbjcdipdgnbfngaljiecclaf"; } # unhoocked 
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # pass
      { id = "ankepacjgoajhjpenegknbefpmfffdic"; } # hide shorts
      { id = "difoiogjjojoaoomphldepapgpbgkhkb"; } # sider gpt
    ];
  };




  };
}

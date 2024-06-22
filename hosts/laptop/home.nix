{ ... }: {
  imports = [
#    ./features/cli
#    ./features/common
     ./../../modules/home-manager/misc/firefox.nix
  ];
  home = {
    username = "none";
    homeDirectory = "/home/none";
    stateVersion = "24.11";
  };
programs.home-manager.enable = true;
}

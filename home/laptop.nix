{ ... }: {
  imports = [
#    ./features/cli
#    ./features/common
  ];
  home = {
    username = "none";
    homeDirectory = "/home/none";
    stateVersion = "24.05";
  };
programs.home-manager.enable = true;
}


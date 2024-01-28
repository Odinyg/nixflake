{ ... }: {
  imports = [
#    ./features/cli
#    ./features/common
  ];
nixpkgs.config.allowUnfree = true;
  home = {
    username = "none";
    homeDirectory = "/home/none";
    stateVersion = "24.05";
  };
programs.home-manager.enable = true;
}


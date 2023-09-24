{ ... }: {
  imports = [
    ./features/cli
    ./features/common
  ];
nixpkgs.config.allowUnfree = true;
  home = {
    username = "none";
    homeDirectory = "/home/none";
    stateVersion = "23.11";
  };
programs.home-manager.enable = true;
}


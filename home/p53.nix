{ inputs, outputs, ... }: {
  imports = [
    ./features/cli
    ./features/common
  ];
nixpkgs.config.allowUnfree = true;

  home = {
    username = "odin";
    homeDirectory = "/home/odin";
    stateVersion = "23.11";
  };
programs.home-manager.enable = true;
}


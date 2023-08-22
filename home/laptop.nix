{ inputs, outputs, ... }: {
  imports = [
    ./features/cli
    ./features/common
  ];

home.stateVersion = "23.05";
programs.home-manager.enable = true;
}


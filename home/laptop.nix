{ inputs, outputs, ... }: {
  imports = [
    ./features/cli
    ./features/common
  ];

home.stateVersion = "23.11";
programs.home-manager.enable = true;
}


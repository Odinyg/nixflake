{ inputs, outputs, ... }: {
  imports = [
    ./features/cli
  ];

home.stateVersion = "23.05";
programs.home-manager.enable = true;
}


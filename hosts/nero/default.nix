{
  pkgs,
  mkServerNetwork,
  inventory,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    (mkServerNetwork {
      ip = inventory.nero;
      gateway = "10.10.30.1";
    })
  ];

  environment.systemPackages = [ pkgs.gh ];

  networking.hostName = "nero";

  server.disko = {
    enable = true;
    disk = "/dev/sda";
  };

  server.second-brain = {
    enable = true;
    projectDir = "/home/odin/projects/Brain";
    matrix.homeserver = "http://10.10.30.111:6167";
    matrix.userId = "@brain:pytt.io";
    matrix.notifyRoom = "!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q";
    flush = {
      enableServer = true;
      port = 8765;
    };
  };

  system.stateVersion = "25.05";
}

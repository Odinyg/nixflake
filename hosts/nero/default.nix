{
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking = {
    hostName = "nero";
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "10.10.30.115";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.10.30.1";
    nameservers = [
      "10.10.30.1"
      "1.1.1.1"
    ];
  };

  server.disko = {
    enable = true;
    disk = "/dev/sda";
  };

  # Direct LAN bypass for forgejo SSH (avoids broken hairpin NAT through psychosocial).
  # Keep hostname so SSH host key validation against git.pytt.io still matches.
  networking.hosts."10.10.30.111" = [ "git.pytt.io" ];

  server.second-brain = {
    enable = true;
    projectDir = "/home/odin/projects/Brain";
    repoUrl = "ssh://forgejo@git.pytt.io:22/odin/Brain.git";
    vaultRepoUrl = "ssh://forgejo@git.pytt.io:22/odin/brain-vault.git";
    matrix.homeserver = "http://10.10.30.111:6167";
    matrix.userId = "@brain:pytt.io";
    matrix.notifyRoom = "!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q";
  };

  system.stateVersion = "25.05";
}

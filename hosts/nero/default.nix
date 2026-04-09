{
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.hermes-agent.nixosModules.default
  ];

  environment.systemPackages = [ pkgs.gh ];

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

  sops.secrets."hermes-env" = {
    owner = "hermes";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    settings = {
      model = {
        base_url = "http://10.10.10.10:11434/v1";
        default = "gemma4:26b";
      };
      discord = {
        require_mention = true;
      };
    };
    documents."SOUL.md" = builtins.readFile ./hermes-soul.md;
  };

  system.stateVersion = "25.05";
}

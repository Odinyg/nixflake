{ config, lib, ... }: {
  imports = [
    ./app
    ./cli
    ./misc
    ./desktop
  ];
  options = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary user of the system";
    };
    userDirs = {
      # Required to prevent infinite recursion when referenced by himalaya
      download = lib.mkOption {
        type = lib.types.str;
        description = "XDG directory for downloads";
        default = "$HOME/Downloads";
      };
    };
    homePath = lib.mkOption {
      type = lib.types.path;
      description = "Path of user's home directory.";
      default = "/home/${config.user}";
    };
    identityFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to existing private key file.";
      default = ".ssh/ssh_host_ed25519_key";
    };
    gui = {
      enable = lib.mkEnableOption {
        description = "Enable graphics.";
        default = false;
      };
    };
    unfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of unfree packages to allow.";
      default = [ ];
    };
  };
}

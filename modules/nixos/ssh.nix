{ lib, config, ... }:
{
  options = {
    ssh = {
      enable = lib.mkEnableOption {
        description = "Enable ssh ";
        default = false;
      };
    };
  };
  config = lib.mkIf config.ssh.enable {

    services.openssh.enable = true;
  };
}

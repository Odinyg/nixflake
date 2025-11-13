{ lib, config, ... }:
{
  options = {
    ssh = {
      enable = lib.mkEnableOption "ssh";
    };
  };
  config = lib.mkIf config.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };

    programs.ssh.startAgent = true;
  };
}

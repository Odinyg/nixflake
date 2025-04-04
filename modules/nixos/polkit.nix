{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    polkit = {
      enable = lib.mkEnableOption {
        description = "Enable polkit";
        default = false;
      };
    };
  };
  config = lib.mkIf config.polkit.enable {

    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    environment.systemPackages = with pkgs; [
      polkit_gnome
      gnome-keyring
    ];
    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
      extraConfig = ''
        DefaultTimeoutStopSec=10s
      '';
    };
  };
}

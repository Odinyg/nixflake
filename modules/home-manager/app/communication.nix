{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.communication;
in
{

  options = {
    communication = {
      enable = lib.mkEnableOption "communication and productivity apps";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Email & Security
      protonmail-desktop # ProtonMail email client
      evolution # GNOME email/calendar/contacts client
      evolution-ews # Microsoft Exchange / Office 365 backend for Evolution

      # Terminals

      # Productivity
      planify # Task manager

      # Browsers
      brave # Privacy-focused browser

      # Matrix
      nheko # Native Qt Matrix client
      gomuks # Terminal Matrix client
      iamb # Vim-modal terminal Matrix client
    ];
  };
}

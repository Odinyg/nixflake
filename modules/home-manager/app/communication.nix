{ config, pkgs, lib, ... }: {

  options = {
    communication = {
      enable = lib.mkEnableOption "communication and productivity apps";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.communication.enable {
    home.packages = with pkgs; [
      # Email & Security
      protonmail-desktop  # ProtonMail email client
      proton-pass         # ProtonPass password manager
      # protonvpn-gui       # ProtonVPN client (temporarily disabled due to test failures in proton-core)
      keeweb              # Password manager

      # Terminals
      warp-terminal       # Modern terminal

      # Productivity
      planify             # Task manager

      # Browsers
      brave               # Privacy-focused browser
      kuro                # Minimal browser
    ];
  };
}

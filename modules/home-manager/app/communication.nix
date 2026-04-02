{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  standalone = !(options ? nixpkgs);

  hmConfig = {
    home.packages = with pkgs; [
      # Email & Security
      protonmail-desktop # ProtonMail email client
      proton-pass # ProtonPass password manager
      keeweb # Password manager

      # Terminals
      warp-terminal # Modern terminal

      # Productivity
      planify # Task manager

      # Browsers
      brave # Privacy-focused browser
      kuro # Minimal browser
    ];
  };
in
{
  options = {
    communication = {
      enable = lib.mkEnableOption "communication and productivity apps";
    };
  };

  config = lib.mkMerge (
    [
      { home-manager.users.${config.user} = lib.mkIf config.communication.enable hmConfig; }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.communication.enable hmConfig)
    ]
  );
}

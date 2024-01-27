{ lib,pkgs,config,... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.crypt.enable {
  options = {
    crypt = {
      enable = lib.mkEnableOption {
        description = "Enable Crypt";
        default = false;
      }; 
    };
  };

  hardware.ledger.enable = true;
  services.trezord.enable = true;
    packages = with pkgs; [
      trezor-suite
      ledger-live-desktop
    ];
  };
}

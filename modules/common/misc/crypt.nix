{ lib,pkgs,... }: {

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
  }

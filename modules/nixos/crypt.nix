{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    crypt = {
      enable = lib.mkEnableOption {
        description = "Enable Crypt";
        default = false;
      };
    };
  };
  config = lib.mkIf config.crypt.enable {
    services.trezord.enable = true;
    hardware.ledger.enable = true;
    environment.systemPackages = with pkgs; [
      trezor-suite
      ledger-live-desktop

    ];
  };
}

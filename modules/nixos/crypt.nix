{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.crypt;
in
{
  options = {
    crypt = {
      enable = lib.mkEnableOption "Crypt";
    };
  };
  config = lib.mkIf cfg.enable {
    services.trezord.enable = true;
    hardware.ledger.enable = true;
    environment.systemPackages = with pkgs; [
      trezor-suite
      ledger-live-desktop

    ];
  };
}

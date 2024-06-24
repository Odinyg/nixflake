
{ lib, config, pkgs, ... }: {

  options = {
    _1password = {
      enable = lib.mkEnableOption {
        description = "Enable locate";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.locate.enable{
  services.locate.enable = true;
  services.locate.locate = pkgs.mlocate;
};
}



{ lib,pkgs,config,... }: {
  options = {
    anbox = {
      enable = lib.mkEnableOption {
        description = "Enable anbox";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.anbox.enable{
  virtualisation.anbox = {
   enable = true; 
  };
    environment.systemPackages = with pkgs; [
      anbox
    ];
  };
}

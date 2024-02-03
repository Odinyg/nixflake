{ lib,pkgs,config,... }: {
  options = {
    wireless = {
      enable = lib.mkEnableOption {
        description = "Enable wireless";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.wireless.enable{
  networking.hostName = "${config.myhostname}"; 
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true; 
  hardware.bluetooth.powerOnBoot = true; 

    home.packages = with pkgs; [
      networkmanagerapplet
    ];
};
}

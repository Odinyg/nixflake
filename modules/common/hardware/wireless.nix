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
  networking.hostName = "XPS"; 
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true; 
  hardware.bluetooth.powerOnBoot = true; 

  environment.systemPackages = with pkgs; [
      networkmanagerapplet
    ];
};
}

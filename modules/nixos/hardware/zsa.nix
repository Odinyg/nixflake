{ lib,pkgs,config,... }: {
  options = {
    zsa = {
      enable = lib.mkEnableOption {
        description = "Enable zsa";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.zsa.enable{
#  networking.hostName = "XPS"; 
  hardware.keyboard.zsa.enable = true;
  environment.systemPackages = with pkgs; [
    wally-cli
    zsa-udev-rules
    ];
};
}

{ lib,config,... }: {
  options = {
    tailscale = {
      enable = lib.mkEnableOption {
        description = "Enable tailscale ";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.tailscale.enable{
  services.tailscale.enable = true;
};
}

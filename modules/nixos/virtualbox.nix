{ pkgs, config, lib,... }: {

  options = {
    virtualbox = {
      enable = lib.mkEnableOption {
        description = "Enable several virtualbox";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.virtualbox.enable{

    virtualisation.virtualbox.host = {
      enable = true;
      # urg, takes so long to build, but needed for macOS guest
      # enableExtensionPack = true;
    };

    user.extraGroups = [ "vboxusers" ];
  };
}

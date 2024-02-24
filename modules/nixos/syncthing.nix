{config, lib, ... }: {

  options = {
    syncthing = {
      enable = lib.mkEnableOption {
        description = "Enable several syncthing";
        default = true;
      }; 
    };
  };
config = lib.mkIf  config.syncthing.enable{
services = {
  syncthing = {
    enable = true;
    user = "${config.user}";
    dataDir = "/home/${config.user}/Documents";
    configDir = "/home/${config.user}/Documents/.config/syncthing";
    overrideDevices = true;     # overrides any devices added or deleted through the WebUI
#    overrideFolders = true;     # overrides any folders added or deleted through the WebUI
    settings = {
      devices = {
 #       "device1" = { id = "DEVICE-ID-GOES-HERE"; };
 #       "device2" = { id = "DEVICE-ID-GOES-HERE"; };
      };
#      folders = {
#        "Documents" = {         # Name of folder in Syncthing, also the folder ID
#          path = "/home/${config.user}/Documents";    # Which folder to add to Syncthing
#          devices = [ "device1" "device2" ];      # Which devices to share the folder with
#        };
#      };
    };
  };
};
    };
  }


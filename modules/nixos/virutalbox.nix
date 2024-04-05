{ lib,config,... }: {
  options = {
    virtualbox = {
      enable = lib.mkEnableOption {
        description = "Enable virtualbox ";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.virtualbox.enable{

  users.extraGroups.vboxusers.members = [ "none" ];
  virtualisation.virtualbox = {
       host.enable = true;
       host.enableExtensionPack = true;
       guest.enable = true;
       guest.x11 = true;

     };
     };
   }

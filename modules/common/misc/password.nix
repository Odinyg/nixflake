{ lib,config,... }: {
  options = {
    _1password = {
      enable = lib.mkEnableOption {
        description = "Enable _1password";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config._1password.enable{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "odin" ];
  };
};
}


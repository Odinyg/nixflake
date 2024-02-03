{ config, pkgs, lib, ... }: {

  options = {
    kitty = {
      enable = lib.mkEnableOption {
        description = "Enable kitty";
        default = false;
      }; 
    };
  };



  config.home-manager.users.${config.user} = lib.mkIf config.kitty.enable {
    programs.kitty = {
      enable = true;
      theme = nord;
      shellIntegration.enableZshIntegration = true;

    };


};
}

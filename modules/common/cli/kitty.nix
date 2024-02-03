{ config, lib, ... }: {

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
      theme = "Nord";
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 13;
      };
      shellIntegration.enableZshIntegration = true;

    };


};
}

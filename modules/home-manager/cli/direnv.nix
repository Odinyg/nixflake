{ config, lib, ... }:
{

  options = {
    direnv = {
      enable = lib.mkEnableOption {
        description = "Enable several direnv";
        default = false;
      };
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.direnv.enable {

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}

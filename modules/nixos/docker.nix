{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    docker = {
      enable = lib.mkEnableOption {
        description = "Enable virt man";
        default = false;
      };
    };
  };
  config = lib.mkIf config.docker.enable {

    virtualisation.docker.enable = true;
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];

  };
}

{
  lib,
  config,
  pkgs,
  ...
}:
{

  options = {
    ollama = {
      enable = lib.mkEnableOption {
        description = "Enable ollama";
        default = false;
      };
    };
  };
  config = lib.mkIf config.ollama.enable {

    services.ollama = {
      enable = true;
      acceleration = "cuda"; # Enables GPU acceleration using CUDA
      openFirewall = true; # Optional: Opens firewall for access
    };
  };
}

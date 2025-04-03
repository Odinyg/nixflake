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
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true; # Optional: Opens firewall for access
    };
    services.nextjs-ollama-llm-ui.enable = true;
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      acceleration = "cuda"; # Enables GPU acceleration using CUDA
      openFirewall = true; # Optional: Opens firewall for access
    };
  };
}

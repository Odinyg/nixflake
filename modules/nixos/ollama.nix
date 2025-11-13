{
  lib,
  config,
  pkgs,
  ...
}:
{

  options = {
    ollama = {
      enable = lib.mkEnableOption "ollama";
    };
  };
  config = lib.mkIf config.ollama.enable {
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = false;
    };
    services.nextjs-ollama-llm-ui.enable = true;
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      acceleration = "cuda";
      openFirewall = false;
    };

    # Allow access only through Tailscale (secure private network)
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}

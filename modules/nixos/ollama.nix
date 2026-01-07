{ lib, config, pkgs, ... }: {

  options = { ollama = { enable = lib.mkEnableOption "ollama"; }; };
  config = lib.mkIf config.ollama.enable {
    services.nextjs-ollama-llm-ui.enable = true;
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      package = pkgs.ollama-cuda;
      openFirewall = true;
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nextjsOllamaUI;
in {
  options.services.nextjsOllamaUI = {
    enable = mkEnableOption "NextJS Ollama LLM UI";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for NextJS Ollama UI";
    };

    hostname = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Hostname to bind to (use 0.0.0.0 for network access)";
    };

    ollamaUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:11434";
      description = "URL of the Ollama backend service";
    };
  };

  config = mkIf cfg.enable {
    services.nextjs-ollama-llm-ui = {
      enable = true;
      port = cfg.port;
      hostname = cfg.hostname;
      ollamaUrl = cfg.ollamaUrl;
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ollamaConfig;
in {
  options.services.ollamaConfig = {
    enable = mkEnableOption "Ollama local LLM server";

    port = mkOption {
      type = types.port;
      default = 11434;
      description = "Port for Ollama server";
    };

    acceleration = mkOption {
      type = types.nullOr (types.enum [ "rocm" "cuda" ]);
      default = null;
      description = "GPU acceleration type (rocm for AMD, cuda for NVIDIA)";
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "llama3.2" "codellama" ];
      description = "Models to automatically download on service start";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for Ollama port";
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      port = cfg.port;
      acceleration = cfg.acceleration;
      loadModels = cfg.models;
      openFirewall = cfg.openFirewall;
    };
  };
}

{ lib, config, pkgs-unstable, ... }: {

  options = { ollama = { enable = lib.mkEnableOption "ollama"; }; };
  config = lib.mkIf config.ollama.enable {
    networking.extraHosts = "127.0.0.1 ollama.local";
    services.ollama = {
      enable = true;
      package = pkgs-unstable.ollama;
      host = "0.0.0.0";
      acceleration = "cuda";
      openFirewall = true;
    };
  };
}

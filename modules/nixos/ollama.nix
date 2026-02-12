{ lib, config, ... }: {

  options = { ollama = { enable = lib.mkEnableOption "ollama"; }; };
  config = lib.mkIf config.ollama.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      acceleration = "cuda";
      openFirewall = true;
    };
  };
}

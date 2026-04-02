{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  standalone = !(options ? nixpkgs);

  hmConfig = {
    home.packages = [ pkgs.lmstudio ];
  };
in
{
  options = {
    lmstudio = {
      enable = lib.mkEnableOption "LM Studio";
    };
  };

  config = lib.mkMerge (
    [
      { home-manager.users.${config.user} = lib.mkIf config.lmstudio.enable hmConfig; }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.lmstudio.enable hmConfig)
    ]
  );
}

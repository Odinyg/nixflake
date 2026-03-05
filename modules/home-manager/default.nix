{ config, lib, ... }:
{
  imports = [
    ./app
    ./cli
    ./misc
    ./desktop
  ];
  options = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary user of the system";
    };
  };
}

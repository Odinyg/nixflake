{
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable nixos-hardware;
  lib = import ./lib.nix { inherit inputs; };
  inventory = lib.inventory;

  mkColmenaHost =
    {
      hostPath,
      user,
      targetHost,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    { ... }:
    {
      deployment = {
        targetHost = targetHost;
        targetUser = user;
        allowLocalDeployment = true;
      };
      imports = lib.hostModules {
        inherit
          hostPath
          user
          stateVersion
          extraModules
          ;
      };
    };

  mkColmenaServer =
    {
      hostPath,
      targetHost,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    { ... }:
    {
      deployment = {
        targetHost = targetHost;
        targetUser = "odin";
      };
      imports = lib.serverModules {
        inherit hostPath stateVersion extraModules;
      };
    };

  serverNixpkgs = import nixpkgs-unstable { localSystem = "x86_64-linux"; };
  serverHosts = [
    "pulse"
    "sugar"
    "byob"
    "psychosocial"
    "spiders"
    "nero"
  ];
in
{
  flake.colmena = {
    meta = {
      nixpkgs = import nixpkgs { localSystem = "x86_64-linux"; };
      nodeNixpkgs = nixpkgs.lib.genAttrs serverHosts (_: serverNixpkgs);
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable mkServerNetwork inventory;
      };
    };

    # Desktop hosts
    laptop = mkColmenaHost {
      hostPath = ../hosts/laptop;
      user = "none";
      targetHost = "laptop";
    };

    VNPC-21 = mkColmenaHost {
      hostPath = ../hosts/vnpc-21;
      user = "odin";
      targetHost = "vnpc-21";
      extraModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-p53 ];
    };

    station = mkColmenaHost {
      hostPath = ../hosts/station;
      user = "none";
      targetHost = "station";
    };

    # Homelab servers
    pulse = mkColmenaServer {
      hostPath = ../hosts/pulse;
      targetHost = inventory.pulse;
    };

    sugar = mkColmenaServer {
      hostPath = ../hosts/sugar;
      targetHost = inventory.sugar;
    };

    byob = mkColmenaServer {
      hostPath = ../hosts/byob;
      targetHost = inventory.byob;
    };

    psychosocial = mkColmenaServer {
      hostPath = ../hosts/psychosocial;
      targetHost = inventory.psychosocial;
    };

    spiders = mkColmenaServer {
      hostPath = ../hosts/spiders;
      targetHost = inventory.spiders;
    };

    nero = mkColmenaServer {
      hostPath = ../hosts/nero;
      targetHost = inventory.nero;
    };
  };
}

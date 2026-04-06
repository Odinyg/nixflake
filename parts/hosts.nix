{
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable nixos-hardware;
  lib = import ./lib.nix { inherit inputs; };

  mkHost =
    args:
    nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable;
      };
      modules = lib.hostModules args;
    };

  mkServer =
    args:
    nixpkgs-unstable.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable;
      };
      modules = lib.serverModules args;
    };
in
{
  flake.nixosConfigurations = {
    # Desktop hosts
    laptop = mkHost {
      hostPath = ../hosts/laptop;
      user = "none";
    };

    VNPC-21 = mkHost {
      hostPath = ../hosts/vnpc-21;
      user = "odin";
      extraModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-p53 ];
    };

    station = mkHost {
      hostPath = ../hosts/station;
      user = "none";
    };

    # Homelab servers
    pulse = mkServer {
      hostPath = ../hosts/pulse;
    };

    sugar = mkServer {
      hostPath = ../hosts/sugar;
    };

    byob = mkServer {
      hostPath = ../hosts/byob;
    };

    psychosocial = mkServer {
      hostPath = ../hosts/psychosocial;
    };

    spiders = mkServer {
      hostPath = ../hosts/spiders;
    };

    nero = mkServer {
      hostPath = ../hosts/nero;
    };

    # Installer ISO with SSH key baked in
    installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (
          { ... }:
          {
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINezFWDmtlGHBF674DcsNi+wDMrSp13pNX1lo4RcJTMm odin.nygard@vendanor.com"
            ];
            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "prohibit-password";
            };
          }
        )
      ];
    };
  };
}

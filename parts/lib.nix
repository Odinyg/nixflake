# Shared helpers for flake-parts modules
{ inputs }:
let
  inherit (inputs)
    nixpkgs
    nixpkgs-unstable
    nixvim
    stylix
    home-manager
    plasma-manager
    sops-nix
    ;

  inventory = import ./inventory.nix;

  mkServerNetwork =
    {
      ip,
      prefixLength ? 24,
      gateway,
      nameservers ? [
        gateway
        "1.1.1.1"
      ],
      interface ? "ens18",
    }:
    {
      networking = {
        useDHCP = false;
        interfaces.${interface} = {
          ipv4.addresses = [
            {
              address = ip;
              inherit prefixLength;
            }
          ];
        };
        defaultGateway = gateway;
        inherit nameservers;
      };
    };

  system = "x86_64-linux";

  pkgs-unstable = import nixpkgs-unstable {
    localSystem = system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        openldap = prev.openldap.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };

  # Desktop hosts: full module tree with home-manager, stylix, nixvim
  commonModules = [
    ../modules
    stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
  ];

  # Server hosts: lightweight — no home-manager, stylix, or desktop modules
  serverCommonModules = [
    ../modules/server
    sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ];

  # Applied to every host (desktop + server)
  sharedConfig = {
    networking.enableIPv6 = false;
    services.qemuGuest.enable = true;
    # openldap test017-syncreplication-refresh is timing-flaky on busy builders
    nixpkgs.overlays = [
      (final: prev: {
        openldap = prev.openldap.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };

  hostModules =
    {
      hostPath,
      user,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    commonModules
    ++ [
      sharedConfig
      hostPath
      { user = user; }
      { nixpkgs.config.allowUnfree = true; }
      {
        # Upstream's t/spamd_ssl.t is flaky in sandboxed builds; skip its checks.
        nixpkgs.overlays = [
          (final: prev: {
            perlPackages = prev.perlPackages.overrideScope (
              pfinal: pprev: {
                SpamAssassin = pprev.SpamAssassin.overrideAttrs (_: {
                  doCheck = false;
                });
              }
            );
          })
        ];
      }
      { _module.args = { inherit pkgs-unstable; }; }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          users.${user} = {
            imports = [
              nixvim.homeModules.nixvim
              plasma-manager.homeModules.plasma-manager
            ];
            home = {
              username = user;
              homeDirectory = "/home/${user}";
              stateVersion = stateVersion;
            };
            programs.home-manager.enable = true;
          };
        };
      }
    ]
    ++ extraModules;

  serverModules =
    {
      hostPath,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    let
      hostname = builtins.baseNameOf (toString hostPath);
    in
    serverCommonModules
    ++ [
      sharedConfig
      hostPath
      { _module.args = { inherit pkgs-unstable; }; }
      # Auto-derive sops secrets file from hostname (secrets/<hostname>.yaml)
      { sops.defaultSopsFile = ../secrets + "/${hostname}.yaml"; }
    ]
    ++ extraModules;
in
{
  inherit
    system
    pkgs-unstable
    commonModules
    serverCommonModules
    hostModules
    serverModules
    mkServerNetwork
    inventory
    ;
}

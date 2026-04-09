{
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.hermes-agent.nixosModules.default
  ];

  environment.systemPackages = [ pkgs.gh ];

  networking = {
    hostName = "nero";
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "10.10.30.115";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.10.30.1";
    nameservers = [
      "10.10.30.1"
      "1.1.1.1"
    ];
  };

  server.disko = {
    enable = true;
    disk = "/dev/sda";
  };

  server.second-brain = {
    enable = true;
    projectDir = "/home/odin/projects/Brain";
    matrix.homeserver = "http://10.10.30.111:6167";
    matrix.userId = "@brain:pytt.io";
    matrix.notifyRoom = "!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q";
    flush = {
      enableServer = true;
      port = 8765;
    };
  };

  sops.secrets."hermes-env" = {
    owner = "hermes";
    mode = "0400";
  };

  # Override the upstream hermes-agent package to add matrix-nio (no e2e).
  # The upstream nix build excludes [matrix] because python-olm (libolm
  # bindings, required only by [e2e]) is broken on macOS. Plain matrix-nio
  # works fine on Linux. We layer it in via PYTHONPATH from a tiny nixpkgs
  # python env so the venv built by uv2nix stays untouched.
  services.hermes-agent =
    let
      upstream = inputs.hermes-agent.packages.${pkgs.system}.default;
      # Use stable nixpkgs for matrix-nio — unstable currently has a broken
      # dep chain (sphinx-9 incompatible with python 3.11).
      pkgs-stable = import inputs.nixpkgs { inherit (pkgs) system; };
      matrixEnv = pkgs-stable.python311.withPackages (ps: [ ps.matrix-nio ]);
    in
    {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [ config.sops.secrets."hermes-env".path ];
      package = pkgs.symlinkJoin {
        name = "hermes-agent-with-matrix";
        paths = [ upstream ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in hermes hermes-agent hermes-acp; do
            if [ -e $out/bin/$bin ]; then
              wrapProgram $out/bin/$bin \
                --prefix PYTHONPATH : ${matrixEnv}/${pkgs.python311.sitePackages}
            fi
          done
        '';
      };
      settings = {
        model = {
          base_url = "http://10.10.10.10:11434/v1";
          default = "gemma4:26b";
        };
        discord = {
          require_mention = false;
        };
      };
      documents."SOUL.md" = builtins.readFile ./hermes-soul.md;
    };

  system.stateVersion = "25.05";
}

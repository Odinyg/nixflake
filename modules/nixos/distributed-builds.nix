{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.distributedBuilds;
in
{
  options.distributedBuilds = {
    enable = lib.mkEnableOption "distributed builds over Tailscale";
    
    isBuilder = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host acts as a build server";
    };
    
    builderHost = lib.mkOption {
      type = lib.types.str;
      default = "station";
      description = "Hostname of the build server (reachable via Tailscale)";
    };
    
    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Maximum number of parallel jobs on the builder";
    };
    
    cachePort = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Port for the binary cache server";
    };
    
    sshKey = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "SSH key path for connecting to builder (auto-detected if null)";
    };
    
    sshUser = lib.mkOption {
      type = lib.types.str;
      default = "none";
      description = "SSH user for connecting to builder (on the builder machine)";
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Builder configuration (for station)
    (lib.mkIf cfg.isBuilder {
      # Enable SSH for remote builds
      services.openssh = {
        enable = true;
        settings = {
          PubkeyAuthentication = true;
          PasswordAuthentication = false;
        };
      };
      
      # Set up nix-serve for binary cache
      services.nix-serve = {
        enable = true;
        port = cfg.cachePort;
        openFirewall = true;
      };
      
      # Allow builds from trusted users
      nix.settings = {
        trusted-users = [ "root" "@wheel" cfg.sshUser ];
      };
      
      # Open firewall for Tailscale subnet
      networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedTCPPorts = [ 22 cfg.cachePort ];
      };
    })
    
    # Client configuration (for other hosts)
    (lib.mkIf (!cfg.isBuilder) (let
      # Auto-detect the primary user and their SSH key
      primaryUser = builtins.head (builtins.attrNames (lib.filterAttrs (n: u: u.isNormalUser) config.users.users));
      actualSshKey = if cfg.sshKey != null then cfg.sshKey else "/home/${primaryUser}/.ssh/id_ed25519";
    in {
      # Configure distributed builds
      nix.distributedBuilds = true;
      
      nix.buildMachines = [{
        hostName = cfg.builderHost;
        system = "x86_64-linux";
        maxJobs = cfg.maxJobs;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
        sshUser = cfg.sshUser;
        sshKey = actualSshKey;
      }];
      
      # Configure binary cache
      nix.settings = {
        substituters = [
          "http://${cfg.builderHost}:${toString cfg.cachePort}"
        ];
        trusted-substituters = [
          "http://${cfg.builderHost}:${toString cfg.cachePort}"
        ];
        trusted-public-keys = [
          # This will need to be replaced with the actual public key from nix-serve
          # Get it from station with: cat /var/lib/nix-serve/cache-priv-key.pem | nix-store --generate-binary-cache-key station /dev/stdin /dev/stdout
        ];
        
        # Prefer remote builds for large derivations
        builders-use-substitutes = true;
        
        # Fallback to local if builder is unavailable
        fallback = true;
        connect-timeout = 5;
      };
      
      # SSH client configuration for builder connection
      programs.ssh.extraConfig = ''
        Host ${cfg.builderHost}
          HostName ${cfg.builderHost}
          User ${cfg.sshUser}
          IdentityFile ${actualSshKey}
          ConnectTimeout 5
          StrictHostKeyChecking accept-new
      '';
    }))
  ]);
}
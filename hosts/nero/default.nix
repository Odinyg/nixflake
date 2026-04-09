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

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
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

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    container = {
      enable = true;
      backend = "podman";
      extraVolumes = [ "/var/lib/hermes/vault:/var/lib/hermes/vault:ro" ];
    };
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    environment = {
      # No-space path — paths with spaces tripped up the LLM's tool calls.
      OBSIDIAN_VAULT_PATH = "/var/lib/hermes/vault";
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
    documents."USER.md" = ''
      # Operational context for Hermes on nero

      ## Obsidian / Brain vault

      The user's obsidian-style knowledge vault is mounted **read-only** at:

          /var/lib/hermes/vault

      (also available as `$OBSIDIAN_VAULT_PATH`). Brain (a separate
      agent) owns writes — you must NEVER attempt to write to this path,
      only read/search it.

      When the user asks about "notes", "the vault", "obsidian", "daily
      log", or names a file like `HABITS.md`, `MEMORY.md`, `HEARTBEAT.md`,
      you should look there first using terminal tools, e.g.:

          find /var/lib/hermes/vault -iname '*habits*'
          grep -rli 'keyword' /var/lib/hermes/vault --include='*.md'
          cat /var/lib/hermes/vault/HABITS.md

      Top-level layout: `daily/`, `archive/`, `decisions/`, `drafts/`,
      `knowledge/`, plus root-level `HABITS.md`, `MEMORY.md`,
      `HEARTBEAT.md`, `README.md`.

      ## Companion services on this host

      - **Brain** (second-brain) owns the vault, runs the matrix bot
        `@brain:pytt.io`, handles daily logs, GitHub/Todoist/Mealie/
        HomeAssistant/Wger integrations, and the flush server on :8765.
      - **You** (`@hermes:pytt.io`) are the broader-purpose agent. You can
        read the vault but Brain owns the canonical write path.

      Defer to Brain for things in its scope (daily log appends, matrix
      notifications via second-brain channels, the flush pipeline).
      Take ownership of everything else.
    '';
  };

  # Install matrix-nio inside the hermes container after start. Idempotent:
  # apt + pip are no-ops once present in the writable layer. Survives container
  # recreates because the unit re-runs on every start.
  systemd.services.hermes-agent.serviceConfig.ExecStartPost = [
    "${pkgs.writeShellScript "hermes-install-matrix-nio" ''
      set -eu
      for i in 1 2 3 4 5 6 7 8 9 10; do
        if ${pkgs.podman}/bin/podman exec hermes-agent true 2>/dev/null; then
          break
        fi
        sleep 2
      done
      ${pkgs.podman}/bin/podman exec hermes-agent bash -c '
        set -eu
        if ! python3 -c "import nio" 2>/dev/null; then
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq python3-pip
          python3 -m pip install --break-system-packages matrix-nio
        fi
      '
    ''}"
  ];

  # Read-only bind mount so hermes (which runs as `hermes`, not `odin`) can
  # read the obsidian/brain vault. Path has no space because LLM tool calls
  # repeatedly tripped on the default "Obsidian Vault" name.
  systemd.tmpfiles.rules = [
    "d /var/lib/hermes 0755 hermes hermes -"
    "d /var/lib/hermes/vault 0755 root root -"
  ];
  fileSystems."/var/lib/hermes/vault" = {
    device = "/home/odin/projects/Brain-Vault";
    options = [
      "bind"
      "ro"
    ];
  };

  system.stateVersion = "25.05";
}

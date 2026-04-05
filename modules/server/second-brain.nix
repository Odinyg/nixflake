{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.second-brain;
in
{
  options.server.second-brain = {
    enable = lib.mkEnableOption "Second Brain — AI-powered operational command center";

    projectDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/second-brain";
      description = "Path to the Second Brain project directory (git clone)";
    };

    sync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable git auto-pull sync timer";
      };
      remote = lib.mkOption {
        type = lib.types.str;
        default = "origin";
        description = "Git remote name to pull from";
      };
      branch = lib.mkOption {
        type = lib.types.str;
        default = "master";
        description = "Git branch to pull";
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* *:0/5:00";
        description = "systemd calendar expression for sync schedule (default: every 5 min)";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "odin";
      description = "User to run services as (must own projectDir and .venv)";
    };

    matrix = {
      homeserver = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:6167";
        description = "Matrix homeserver URL";
      };
      userId = lib.mkOption {
        type = lib.types.str;
        default = "@brain:pytt.io";
        description = "Matrix user ID for the bot";
      };
    };

    heartbeat = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable heartbeat timer (every 30 min during active hours)";
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 07..19:00,30:00";
        description = "systemd calendar expression for heartbeat schedule";
      };
    };

    reflection = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable daily reflection timer";
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 08:00:00";
        description = "systemd calendar expression for daily reflection";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # --- Secrets ---
    sops.secrets = {
      second_brain_matrix_token = { };
      second_brain_todoist_token = { };
      second_brain_github_token = { };
      second_brain_mealie_url = { };
      second_brain_mealie_token = { };
      second_brain_wger_url = { };
      second_brain_wger_token = { };
      second_brain_homeassistant_url = { };
      second_brain_homeassistant_token = { };
    };

    sops.templates."second-brain-env".content = ''
      MATRIX_HOMESERVER=${cfg.matrix.homeserver}
      MATRIX_USER_ID=${cfg.matrix.userId}
      MATRIX_ACCESS_TOKEN=${config.sops.placeholder.second_brain_matrix_token}
      TODOIST_API_TOKEN=${config.sops.placeholder.second_brain_todoist_token}
      GITHUB_TOKEN=${config.sops.placeholder.second_brain_github_token}
      MEALIE_URL=${config.sops.placeholder.second_brain_mealie_url}
      MEALIE_API_TOKEN=${config.sops.placeholder.second_brain_mealie_token}
      WGER_URL=${config.sops.placeholder.second_brain_wger_url}
      WGER_TOKEN=${config.sops.placeholder.second_brain_wger_token}
      HOMEASSISTANT_URL=${config.sops.placeholder.second_brain_homeassistant_url}
      HOMEASSISTANT_TOKEN=${config.sops.placeholder.second_brain_homeassistant_token}
      CLAUDE_PROJECT_DIR=${cfg.projectDir}
      CLAUDE_INVOKED_BY=systemd
    '';

    # --- Matrix Bot Service ---
    systemd.services.second-brain-bot = {
      description = "Second Brain — Matrix bot with Agent SDK";
      after = [
        "conduit.service"
        "network-online.target"
      ];
      requires = [ "conduit.service" ];
      wants = [ "network-online.target" ];
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${pkgs.bash}/bin/bash ${cfg.projectDir}/.claude/scripts/run.sh ${cfg.projectDir}/.claude/chat/bot.py";
        EnvironmentFile = config.sops.templates."second-brain-env".path;
        Restart = "on-failure";
        RestartSec = 10;

        # Sandboxing (relaxed — needs project dir access)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        ReadWritePaths = [
          cfg.projectDir
        ];
      };
    };

    # --- Heartbeat Service + Timer ---
    systemd.services.second-brain-heartbeat = lib.mkIf cfg.heartbeat.enable {
      description = "Second Brain — Heartbeat check";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${pkgs.bash}/bin/bash ${cfg.projectDir}/.claude/scripts/run.sh ${cfg.projectDir}/.claude/scripts/heartbeat.py --force";
        EnvironmentFile = config.sops.templates."second-brain-env".path;

        # Sandboxing
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ReadWritePaths = [
          cfg.projectDir
        ];
      };
    };

    systemd.timers.second-brain-heartbeat = lib.mkIf cfg.heartbeat.enable {
      description = "Second Brain — Heartbeat timer (every 30 min, active hours)";
      partOf = [ "homelab.target" ];
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.heartbeat.calendar;
        Persistent = true;
        RandomizedDelaySec = "2min";
      };
    };

    # --- Reflection Service + Timer ---
    systemd.services.second-brain-reflection = lib.mkIf cfg.reflection.enable {
      description = "Second Brain — Daily reflection";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${pkgs.bash}/bin/bash ${cfg.projectDir}/.claude/scripts/run.sh ${cfg.projectDir}/.claude/scripts/memory_reflect.py --verbose";
        EnvironmentFile = config.sops.templates."second-brain-env".path;

        # Sandboxing
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ReadWritePaths = [
          cfg.projectDir
        ];
      };
    };

    systemd.timers.second-brain-reflection = lib.mkIf cfg.reflection.enable {
      description = "Second Brain — Daily reflection timer (08:00)";
      partOf = [ "homelab.target" ];
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.reflection.calendar;
        Persistent = true;
      };
    };

    # --- Git Sync Service + Timer ---
    systemd.services.second-brain-sync = lib.mkIf cfg.sync.enable {
      description = "Second Brain — Git pull sync";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
      };

      path = [ pkgs.git pkgs.openssh ];

      script = ''
        # Record HEAD before pull
        OLD_HEAD=$(git rev-parse HEAD)

        git pull --ff-only ${cfg.sync.remote} ${cfg.sync.branch} || exit 0

        NEW_HEAD=$(git rev-parse HEAD)

        # Restart bot if code changed
        if [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
          echo "Code updated ($OLD_HEAD → $NEW_HEAD), restarting bot..."
          systemctl restart second-brain-bot || true
        fi
      '';
    };

    systemd.timers.second-brain-sync = lib.mkIf cfg.sync.enable {
      description = "Second Brain — Git sync timer (every 5 min)";
      partOf = [ "homelab.target" ];
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.sync.calendar;
        Persistent = true;
      };
    };
  };
}

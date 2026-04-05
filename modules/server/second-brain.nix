{
  config,
  lib,
  pkgs,
  inputs,
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
      notifyRoom = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Matrix room ID for heartbeat notifications (e.g. !abc:example.com)";
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
    # --- System packages ---
    environment.systemPackages = [
      pkgs.uv
      inputs.claude-code.packages.${pkgs.system}.default
    ];

    # --- nix-ld (required for uv-managed Python on NixOS) ---
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];

    # --- Venv setup (runs once, then after every sync) ---
    systemd.services.second-brain-venv = {
      description = "Second Brain — Create/update Python venv";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      unitConfig = {
        # Only run if projectDir exists
        ConditionPathExists = "${cfg.projectDir}/requirements-chat.txt";
      };

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        RemainAfterExit = true;
      };

      path = [ pkgs.uv pkgs.git ];

      script = ''
        if [ ! -d .venv ]; then
          uv venv .venv --python 3.12
        fi
        uv pip install -r requirements.txt -r requirements-chat.txt -r requirements-search.txt
      '';
    };

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
      MATRIX_NOTIFY_ROOM=${cfg.matrix.notifyRoom}
      CLAUDE_PROJECT_DIR=${cfg.projectDir}
      CLAUDE_INVOKED_BY=systemd
    '';

    # --- Matrix Bot Service ---
    systemd.services.second-brain-bot = {
      description = "Second Brain — Matrix bot with Agent SDK";
      after = [
        "conduit.service"
        "network-online.target"
        "second-brain-venv.service"
      ];
      requires = [ "conduit.service" "second-brain-venv.service" ];
      wants = [ "network-online.target" ];
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];

      # bash in PATH so Agent SDK hooks (#!/usr/bin/env bash) work
      path = [ pkgs.bash pkgs.coreutils ];

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

      path = [ pkgs.bash pkgs.coreutils ];

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

      path = [ pkgs.bash pkgs.coreutils ];

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

      path = [ pkgs.git pkgs.openssh pkgs.coreutils ];

      script = ''
        # Git identity for auto-commits
        git config user.name "Second Brain (sugar)" 2>/dev/null || true
        git config user.email "brain@pytt.io" 2>/dev/null || true

        # --- Commit local changes (daily logs, state files) ---
        if [ -n "$(git status --porcelain)" ]; then
          git add -A
          git commit -m "auto: sync from sugar $(date -Iseconds)" || true
        fi

        # --- Pull remote changes (rebase local auto-commits on top) ---
        OLD_HEAD=$(git rev-parse HEAD)
        OLD_REQS=$(cat requirements-chat.txt requirements-search.txt 2>/dev/null | md5sum)

        git pull --rebase ${cfg.sync.remote} ${cfg.sync.branch} || {
          echo "Pull --rebase failed, aborting rebase and retrying next cycle"
          git rebase --abort 2>/dev/null || true
          exit 0
        }

        # --- Push (local commits + rebased auto-commits) ---
        git push ${cfg.sync.remote} ${cfg.sync.branch} || echo "Push failed, will retry next cycle"

        NEW_HEAD=$(git rev-parse HEAD)

        if [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
          echo "Code updated ($OLD_HEAD → $NEW_HEAD)"

          # Rebuild venv if requirements changed
          NEW_REQS=$(cat requirements-chat.txt requirements-search.txt 2>/dev/null | md5sum)
          if [ "$OLD_REQS" != "$NEW_REQS" ]; then
            echo "Requirements changed, rebuilding venv..."
            systemctl restart second-brain-venv || true
          fi

          echo "Restarting bot..."
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

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aiWorker;

  aiWorkerScript = pkgs.writeShellScript "ai-worker" ''
    set -u

    FORGEJO_URL="''${FORGEJO_URL:-https://git.pytt.io}"
    WORK_DIR="''${AI_WORK_DIR:-$HOME/ai-workbench}"
    POLL_INTERVAL="''${POLL_INTERVAL:-30}"
    PROCESSED_FILE="$WORK_DIR/.processed-issues"

    mkdir -p "$WORK_DIR"
    touch "$PROCESSED_FILE"

    log() { echo "[$(date '+%H:%M:%S')] $*"; }

    process_issue() {
      local repo_full="$1" issue_number="$2" issue_title="$3" issue_body="$4"
      local repo_name repo_dir branch

      repo_name=$(echo "$repo_full" | ${pkgs.coreutils}/bin/cut -d/ -f2)
      repo_dir="$WORK_DIR/$repo_name"
      branch="ai/issue-''${issue_number}"

      log "Processing: $repo_full#$issue_number - $issue_title"

      if [ -d "$repo_dir/.git" ]; then
        cd "$repo_dir"
        ${pkgs.git}/bin/git fetch origin
        ${pkgs.git}/bin/git checkout main
        ${pkgs.git}/bin/git reset --hard origin/main
      else
        ${pkgs.git}/bin/git clone "''${FORGEJO_URL}/''${repo_full}.git" "$repo_dir"
        cd "$repo_dir"
      fi

      ${pkgs.git}/bin/git checkout -b "$branch" 2>/dev/null || ${pkgs.git}/bin/git checkout "$branch"

      ${pkgs.curl}/bin/curl -s -X POST "''${FORGEJO_URL}/api/v1/repos/''${repo_full}/issues/''${issue_number}/comments" \
        -H "Authorization: token ''${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"body\": \"AI worker picked up this task. Working on it now...\"}" > /dev/null

      log "Running claude..."
      claude -p "You are working in the repo at $(pwd). Complete this task:

    ''${issue_title}

    ''${issue_body}" --allowedTools "Edit,Write,Bash,Read,Glob,Grep" 2>&1 || {
        log "ERROR: claude CLI failed"
        ${pkgs.curl}/bin/curl -s -X POST "''${FORGEJO_URL}/api/v1/repos/''${repo_full}/issues/''${issue_number}/comments" \
          -H "Authorization: token ''${FORGEJO_TOKEN}" \
          -H "Content-Type: application/json" \
          -d "{\"body\": \"AI worker failed to process this task. Check logs.\"}" > /dev/null
        return 1
      }

      if ${pkgs.git}/bin/git diff --quiet && ${pkgs.git}/bin/git diff --cached --quiet; then
        log "No changes made"
        ${pkgs.curl}/bin/curl -s -X POST "''${FORGEJO_URL}/api/v1/repos/''${repo_full}/issues/''${issue_number}/comments" \
          -H "Authorization: token ''${FORGEJO_TOKEN}" \
          -H "Content-Type: application/json" \
          -d "{\"body\": \"AI agent analyzed the issue but made no file changes.\"}" > /dev/null
        return 0
      fi

      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git commit -m "ai: ''${issue_title}" --author="AI Agent <ai@git.pytt.io>" || true
      ${pkgs.git}/bin/git push -u origin "$branch" --force

      ${pkgs.curl}/bin/curl -s -X POST "''${FORGEJO_URL}/api/v1/repos/''${repo_full}/pulls" \
        -H "Authorization: token ''${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
          \"title\": \"AI: ''${issue_title}\",
          \"body\": \"Closes #''${issue_number}\n\nAI-generated changes for: ''${issue_title}\",
          \"head\": \"''${branch}\",
          \"base\": \"main\"
        }" > /dev/null

      ${pkgs.curl}/bin/curl -s -X POST "''${FORGEJO_URL}/api/v1/repos/''${repo_full}/issues/''${issue_number}/comments" \
        -H "Authorization: token ''${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"body\": \"AI agent created a PR with proposed changes. Please review.\"}" > /dev/null

      log "Done - PR created for $repo_full#$issue_number"
    }

    log "AI Worker started - polling Forgejo every ''${POLL_INTERVAL}s"
    log "Work directory: $WORK_DIR"

    while true; do
      # Search all repos the user owns for open issues with ai-task label
      REPOS=$(${pkgs.curl}/bin/curl -s "''${FORGEJO_URL}/api/v1/user/repos?limit=50" \
        -H "Authorization: token ''${FORGEJO_TOKEN}" | ${pkgs.jq}/bin/jq -r '.[].full_name' 2>/dev/null || true)

      for repo in $REPOS; do
        ISSUES=$(${pkgs.curl}/bin/curl -s "''${FORGEJO_URL}/api/v1/repos/$repo/issues?labels=ai-task&state=open&limit=10" \
          -H "Authorization: token ''${FORGEJO_TOKEN}" 2>/dev/null || true)

        echo "$ISSUES" | ${pkgs.jq}/bin/jq -c '.[]?' 2>/dev/null | while IFS= read -r issue; do
          ISSUE_NUM=$(echo "$issue" | ${pkgs.jq}/bin/jq -r '.number')
          KEY="''${repo}#''${ISSUE_NUM}"

          # Skip already processed issues
          if ${pkgs.gnugrep}/bin/grep -qF "$KEY" "$PROCESSED_FILE" 2>/dev/null; then
            continue
          fi

          ISSUE_TITLE=$(echo "$issue" | ${pkgs.jq}/bin/jq -r '.title')
          ISSUE_BODY=$(echo "$issue" | ${pkgs.jq}/bin/jq -r '.body')

          log "Found: $KEY - $ISSUE_TITLE"
          echo "$KEY" >> "$PROCESSED_FILE"
          process_issue "$repo" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_BODY"
        done
      done

      sleep "$POLL_INTERVAL"
    done
  '';
in
{
  options.aiWorker = {
    enable = lib.mkEnableOption "AI task worker for Forgejo";
    workDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.user}/ai-workbench";
      description = "Directory for AI work repos";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.user}.systemd.user.services.ai-worker = {
      Unit = {
        Description = "AI Task Worker - polls Forgejo for ai-task issues and runs Claude";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${aiWorkerScript}";
        Restart = "always";
        RestartSec = 10;
        Environment = [
          "AI_WORK_DIR=${cfg.workDir}"
          "FORGEJO_URL=https://git.pytt.io"
          "POLL_INTERVAL=30"
        ];
        EnvironmentFile = "%h/.config/ai-worker/env";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

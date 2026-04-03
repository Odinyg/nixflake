{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ai-worker;

  aiWorkerScript = pkgs.writeShellScript "ai-worker" ''
    set -euo pipefail

    NTFY_TOPIC="''${NTFY_TOPIC:-https://ntfy.pytt.io/ai-tasks/json}"
    FORGEJO_URL="''${FORGEJO_URL:-https://git.pytt.io}"
    WORK_DIR="''${AI_WORK_DIR:-$HOME/ai-workbench}"

    mkdir -p "$WORK_DIR"

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

    log "AI Worker started - listening on ntfy topic: ai-tasks"
    log "Work directory: $WORK_DIR"

    ${pkgs.curl}/bin/curl -s -N "$NTFY_TOPIC" | while read -r line; do
      IS_LABEL_EVENT=$(echo "$line" | ${pkgs.jq}/bin/jq -r 'select(.action == "label") | .issue.number // empty' 2>/dev/null || true)

      if [ -n "''${IS_LABEL_EVENT:-}" ]; then
        LABEL_NAME=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.label.name // empty' 2>/dev/null || true)
        if [ "$LABEL_NAME" = "ai-task" ]; then
          REPO=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.repository.full_name' 2>/dev/null)
          ISSUE_NUM=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.issue.number' 2>/dev/null)
          ISSUE_TITLE=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.issue.title' 2>/dev/null)
          ISSUE_BODY=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.issue.body' 2>/dev/null)

          process_issue "$REPO" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_BODY" &
        fi
      fi
    done
  '';
in
{
  options.services.ai-worker = {
    enable = lib.mkEnableOption "AI task worker for Forgejo";
    workDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/ai-workbench";
      description = "Directory for AI work repos";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.ai-worker = {
      Unit = {
        Description = "AI Task Worker - processes Forgejo issues via Claude";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${aiWorkerScript}";
        Restart = "always";
        RestartSec = 10;
        Environment = [
          "AI_WORK_DIR=${cfg.workDir}"
          "NTFY_TOPIC=https://ntfy.pytt.io/ai-tasks/json"
          "FORGEJO_URL=https://git.pytt.io"
        ];
        EnvironmentFile = "%h/.config/ai-worker/env";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

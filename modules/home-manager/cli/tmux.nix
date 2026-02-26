{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.tmux;

  # Tmuxinator layout definitions (YAML)
  tmuxinatorLayouts = {
    universal = {
      name = "universal";
      yaml = ''
        name: <%= @args[0] || "dev" %>
        root: <%= @args[1] || "." %>
        windows:
          - editor:
              layout: main-vertical
              panes:
                - nvim
                -
      '';
    };

    dev-claude = {
      name = "dev-claude";
      yaml = ''
        name: <%= @args[0] || "dev-claude" %>
        root: <%= @args[1] || "." %>
        on_project_start: tmux set-environment -g TMUXINATOR_LAYOUT dev-claude
        windows:
          - code:
              layout: main-vertical
              panes:
                - nvim
                - claude
                - ""
      '';
    };

    monitor = {
      name = "monitor";
      yaml = ''
        name: <%= @args[0] || "monitor" %>
        root: <%= @args[1] || "." %>
        windows:
          - grid:
              layout: tiled
              panes:
                -
                -
                -
                -
      '';
    };

    git = {
      name = "git";
      yaml = ''
        name: <%= @args[0] || "git" %>
        root: <%= @args[1] || "." %>
        windows:
          - main:
              panes:
                - lazygit
      '';
    };

    debug = {
      name = "debug";
      yaml = ''
        name: debug-<%= @args[0] || "local" %>
        root: ~/debug/incidents/<%= @args[1] || Time.now.strftime('%Y-%m-%d') %>
        on_project_start: mkdir -p ~/debug/incidents/<%= @args[1] || Time.now.strftime('%Y-%m-%d') %>/logs ~/debug/incidents/<%= @args[1] || Time.now.strftime('%Y-%m-%d') %>/captures ~/debug/sessions
        startup_window: work
        windows:
          - work:
              layout: main-vertical
              panes:
                - remote:
                  - ssh <%= @args[0] || "localhost" %>
                - ai:
                  - claude
                - shell:
                  - ""
          - remote-logs:
              layout: even-vertical
              panes:
                - ssh <%= @args[0] || "localhost" %> journalctl -f -p warning
                - ssh <%= @args[0] || "localhost" %> journalctl -f
          - notes:
              panes:
                - nvim notes.md
      '';
    };
  };

  # Scaffold a new debug incident directory
  debugNew = pkgs.writeShellScriptBin "debug-new" ''
    name="''${1:?usage: debug-new <short-description> [host]}"
    host="''${2:-local}"
    today=$(date +%Y-%m-%d)
    now=$(date '+%Y-%m-%d %H:%M')
    dir="$HOME/debug/incidents/$today-$name"

    mkdir -p "$dir/logs" "$dir/captures"

    cat > "$dir/notes.md" <<EOF
    # Incident: $name

    **Date:** $now
    **Server:** $host
    **Duration:**

    ## Symptoms
    -

    ## Investigation
    -

    ## Root Cause


    ## Resolution


    ## Artifacts
    - \`logs/\` — downloaded log files
    - \`captures/\` — terminal session recordings
    EOF

    echo "Created: $dir"
    echo "Start session: tmuxinator start debug $host $today-$name"
  '';

  # Layout picker — fzf popup to start a tmuxinator project (prefix+L)
  layoutPicker = pkgs.writeShellScript "tmux-layout-picker" ''
    export PATH="${lib.makeBinPath [ pkgs.fzf pkgs.gawk pkgs.coreutils pkgs.tmuxinator ]}:$PATH"

    layout=$(printf '%s\n' \
      "universal    nvim + terminal" \
      "dev-claude   nvim + claude + terminal" \
      "monitor      4-pane grid" \
      "git          lazygit fullscreen" \
      "debug        ssh + claude + logs (host)" \
      | fzf --no-sort --border-label " tmuxinator " --prompt "  " \
      | awk '{print $1}')

    [ -z "$layout" ] && exit 0

    dir="''${1:-$(tmux display-message -p '#{pane_current_path}')}"
    name=$(basename "$dir")
    tmuxinator start "$layout" "$name" "$dir"
  '';

  # Rename helper for sesh picker (needs explicit /dev/tty for fzf execute)
  seshRename = pkgs.writeShellScript "sesh-rename" ''
    session="$1"
    [ -z "$session" ] && exit 0
    printf 'New name: ' > /dev/tty
    read -r name < /dev/tty
    [ -n "$name" ] && tmux rename-session -t "$session" "$name"
  '';

  # Sesh session picker (canonical pattern: run-shell + fzf-tmux)
  seshConnect = pkgs.writeShellScript "sesh-smart-connect" ''
    export PATH="${lib.makeBinPath [ pkgs.sesh pkgs.fzf pkgs.coreutils pkgs.gnused pkgs.tmuxinator ]}:$PATH"

    strip_icon() {
      LC_ALL=C sed $'s/^[\xee\xef][\x80-\xbf][\x80-\xbf] //'
    }

    session=$(sesh list -itTc | fzf-tmux -p 80%,70% \
        --no-sort --ansi --border-label " sesh " --prompt "  " \
        --header "  ^a all  ^t tmux  ^T muxinator  ^s remote  ^x zoxide  ^f find  ^r rename  ^d kill" \
        --preview-window "right:55%:border-left" \
        --preview "sesh preview {2..}" \
        --bind "tab:down,btab:up" \
        --bind "ctrl-a:change-prompt(  )+reload(sesh list -itTc)" \
        --bind "ctrl-t:change-prompt(  )+reload(sesh list -it)" \
        --bind "ctrl-T:change-prompt(  )+reload(sesh list -iT)" \
        --bind "ctrl-s:change-prompt(  )+reload(sesh list -ic)" \
        --bind "ctrl-x:change-prompt(  )+reload(sesh list -iz)" \
        --bind "ctrl-f:change-prompt(  )+reload(fd -H -d 2 -t d -E .Trash . ~)" \
        --bind "ctrl-r:execute(${seshRename} {2..})+reload(sesh list -itTc)" \
        --bind "ctrl-d:execute(tmux kill-session -t {2..})+reload(sesh list -itTc)" \
      | strip_icon)

    [ -z "$session" ] && exit 0
    sesh connect --tmuxinator "$session"
  '';
in
{
  options.tmux = {
    enable = lib.mkEnableOption "tmux terminal multiplexer";

    sessions = lib.mkOption {
      type = with lib.types; listOf attrs;
      default = [ ];
      description = ''
        Additional sesh session definitions. Each entry maps to a [[session]] in sesh.toml.
        Available fields: name, path, startup_command, startup_script.
      '';
      example = [
        {
          name = "myproject";
          path = "~/projects/myproject";
          startup_command = "nvim";
        }
      ];
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {

    home.packages = with pkgs; [ tmuxinator tmux-xpanes ansifilter debugNew ];

    # Tmuxinator project files
    xdg.configFile = lib.mapAttrs' (name: layout:
      lib.nameValuePair "tmuxinator/${name}.yml" { text = layout.yaml; }
    ) tmuxinatorLayouts;

    # fzf integration (required for sesh tmux popup)
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    # Sesh — smart session manager with fzf + zoxide
    programs.sesh = {
      enable = true;
      enableTmuxIntegration = false; # custom binding with layout picker
      settings = {
        session = cfg.sessions;
      };
    };

    programs.tmux = {
      enable = true;
      prefix = "C-Space";
      baseIndex = 1;
      resizeAmount = 10;
      shell = "${pkgs.zsh}/bin/zsh";
      mouse = true;
      aggressiveResize = true;
      clock24 = false;
      escapeTime = 0;
      terminal = "tmux-256color";
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      focusEvents = true;
      historyLimit = 50000;
      disableConfirmationPrompt = true;

      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        vim-tmux-navigator
        tmux-thumbs
        tmux-fzf
        fzf-tmux-url
        tmux-floax
        better-mouse-mode
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '10'
          '';
        }
        {
          plugin = logging;
          extraConfig = ''
            set -g @logging-path "$HOME/debug/sessions"
            set -g @screen-capture-path "$HOME/debug/sessions"
            set -g @save-complete-history-path "$HOME/debug/sessions"
          '';
        }
      ];

      extraConfig = ''
        unbind C-b
        unbind s          # free s from session tree (used by sesh)
        unbind $          # free $ from rename-session (use R instead)

        # Rename session (prefix+R)
        bind-key "R" command-prompt -I "#S" "rename-session -- '%%'"

        # Sesh session picker (prefix+s or Ctrl+f)
        bind-key "s" run-shell "${seshConnect}"
        bind -n C-f run-shell "${seshConnect}"

        # Tmuxinator layout picker (prefix+L)
        bind-key "L" display-popup -E -w 40% -h 35% "${layoutPicker} '#{pane_current_path}'"

        # Pane navigation (Alt+hjkl, no prefix needed)
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R

        # Select window by number (Alt+1-9, no prefix)
        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5

        # Copy mode pane navigation
        bind-key -T copy-mode-vi 'M-h' select-pane -L
        bind-key -T copy-mode-vi 'M-j' select-pane -D
        bind-key -T copy-mode-vi 'M-k' select-pane -U
        bind-key -T copy-mode-vi 'M-l' select-pane -R

        # Session/window switching
        bind Space last-window           # prefix+Space = last window
        bind C-Space last-window         # Ctrl held: Ctrl+Space, Ctrl+Space = last window
        bind BSpace switch-client -l     # prefix+BackSpace = last session
        bind C-BSpace switch-client -l   # Ctrl held: Ctrl+BackSpace = last session

        # Splits in current directory
        bind \\ split-window -h -c '#{pane_current_path}'
        bind - split-window -v -c '#{pane_current_path}'

        # New window in current directory
        bind c new-window -c '#{pane_current_path}'

        # True color + undercurl for kitty
        set -sa terminal-overrides ",xterm-kitty:Tc"
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

        # Extended keys for modifier passthrough
        set -s extended-keys on
        set -as terminal-features 'xterm*:extkeys'

        # Status bar
        set -g status-interval 1
        set -g automatic-rename on
        set -g automatic-rename-format '#{pane_current_command}'
        set -g renumber-windows on

        # Floax floating pane (prefix+p)
        set -g @floax-bind 'p'
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-change-path 'true'

        # Mouse improvements
        set -g @emulate-scroll-for-no-mouse-alternate-buffer "on"
        set -g @scroll-without-changing-pane "on"

        # Don't detach when closing a session — switch to next
        set -g detach-on-destroy off
      '';
    };

    home.shellAliases = {
      tm = "tmux";
      tms = "tmux new -s";
      tml = "tmux list-sessions";
      tma = "tmux attach -t";
      tmk = "tmux kill-session -t";
      mux = "tmuxinator";
      fleet = "xpanes --ssh station laptop";
    };
  };
}

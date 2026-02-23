{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.tmux;

  # Layout scripts for sesh session startup (receive session name as $1)
  layouts = {
    universal = pkgs.writeShellScript "tmux-layout-universal" ''
      s="''${1:-$(tmux display-message -p '#S')}"
      # Check for project-specific layout first
      session_path=$(tmux display-message -t "$s" -p '#{pane_current_path}')
      if [ -x "$session_path/.tmux-layout.sh" ]; then
        exec "$session_path/.tmux-layout.sh" "$s"
      fi
      # Default: nvim (top 70%) | terminal (bottom 30%)
      tmux split-window -v -l 30% -t "$s"
      tmux select-pane -t "$s:1.0"
      tmux send-keys -t "$s:1.0" "nvim" Enter
    '';

    dev-claude = pkgs.writeShellScript "tmux-layout-dev-claude" ''
      s="''${1:-$(tmux display-message -p '#S')}"
      # nvim (left 60%) | claude (right top 70%) + terminal (right bottom 30%)
      tmux split-window -h -l 40% -t "$s"
      tmux send-keys -t "$s:1.1" "claude" Enter
      tmux split-window -v -l 30% -t "$s:1.1"
      tmux select-pane -t "$s:1.0"
      tmux send-keys -t "$s:1.0" "nvim" Enter
    '';

    monitor = pkgs.writeShellScript "tmux-layout-monitor" ''
      s="''${1:-$(tmux display-message -p '#S')}"
      # 4-pane grid for watching logs/services
      tmux split-window -h -l 50% -t "$s"
      tmux split-window -v -l 50% -t "$s:1.1"
      tmux select-pane -t "$s:1.0"
      tmux split-window -v -l 50% -t "$s:1.0"
      tmux select-pane -t "$s:1.0"
    '';

    git = pkgs.writeShellScript "tmux-layout-git" ''
      s="''${1:-$(tmux display-message -p '#S')}"
      # Full-screen lazygit
      tmux send-keys -t "$s" "lazygit" Enter
    '';
  };

  # Map layout name to script path
  layoutCase = ''
    case "$layout" in
      dev-claude)  ${layouts.dev-claude} "$session" ;;
      monitor)     ${layouts.monitor} "$session" ;;
      git)         ${layouts.git} "$session" ;;
      *)           ${layouts.universal} "$session" ;;
    esac
  '';

  # Sesh session picker (canonical pattern: run-shell + fzf-tmux)
  seshConnect = pkgs.writeShellScript "sesh-smart-connect" ''
    export PATH="${lib.makeBinPath [ pkgs.sesh pkgs.fzf pkgs.coreutils pkgs.gnused ]}:$PATH"

    strip_icon() {
      LC_ALL=C sed $'s/^[\xee\xef][\x80-\xbf][\x80-\xbf] //'
    }

    session=$(sesh list -i | fzf-tmux -p 55%,60% \
        --no-sort --ansi --border-label " sesh " --prompt "  " \
        --header "  ^a all  ^t tmux  ^x zoxide  ^f find  ^d kill" \
        --bind "tab:down,btab:up" \
        --bind "ctrl-a:change-prompt(  )+reload(sesh list -i)" \
        --bind "ctrl-t:change-prompt(  )+reload(sesh list -it)" \
        --bind "ctrl-x:change-prompt(  )+reload(sesh list -iz)" \
        --bind "ctrl-f:change-prompt(  )+reload(fd -H -d 2 -t d -E .Trash . ~)" \
        --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(  )+reload(sesh list -i)" \
      | strip_icon)

    [ -z "$session" ] && exit 0
    sesh connect "$session"
  '';

  # Layout picker — apply a layout to the current session (prefix+L)
  layoutPicker = pkgs.writeShellScript "tmux-layout-picker" ''
    export PATH="${lib.makeBinPath [ pkgs.fzf pkgs.gawk pkgs.coreutils ]}:$PATH"

    session=$(tmux display-message -p '#S')

    layout=$(printf '%s\n' \
      "universal   nvim + terminal" \
      "dev-claude  nvim + claude + terminal" \
      "monitor     4-pane grid" \
      "git         lazygit fullscreen" \
      | fzf --no-sort --border-label " layout " --prompt "  " \
      | awk '{print $1}')

    [ -z "$layout" ] && exit 0

    ${layoutCase}
  '';
in
{
  options.tmux = {
    enable = lib.mkEnableOption "tmux terminal multiplexer";

    defaultLayout = lib.mkOption {
      type = lib.types.enum [
        "universal"
        "dev-claude"
        "none"
      ];
      default = "universal";
      description = "Default layout for new sesh sessions without their own startup script";
    };

    sessions = lib.mkOption {
      type = with lib.types; listOf attrs;
      default = [ ];
      description = ''
        Additional sesh session definitions. Each entry maps to a [[session]] in sesh.toml.
        Available fields: name, path, startup_command, startup_script.
        For startup_script, use one of the built-in layouts or a custom script path.
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
      ];

      extraConfig = ''
        unbind C-b
        unbind t          # free t from clock mode (used by sesh)

        # Sesh session picker (prefix+t)
        bind-key "t" run-shell "${seshConnect}"

        # Layout picker — apply layout to current session (prefix+L)
        bind-key "L" display-popup -E -w 40% -h 35% "${layoutPicker}"

        # Pane navigation (Alt+hjkl, no prefix needed)
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R

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
    };
  };
}

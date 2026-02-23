{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.tmux;

  # Layout scripts for sesh session startup
  layouts = {
    universal = pkgs.writeShellScript "tmux-layout-universal" ''
      # Check for project-specific layout first
      session_path=$(tmux display-message -p '#{pane_current_path}')
      if [ -x "$session_path/.tmux-layout.sh" ]; then
        exec "$session_path/.tmux-layout.sh"
      fi
      # Default: nvim (top 70%) | terminal (bottom 30%)
      tmux split-window -v -l 30%
      tmux select-pane -t 0
      tmux send-keys "nvim" Enter
    '';

    dev-claude = pkgs.writeShellScript "tmux-layout-dev-claude" ''
      # nvim (left 60%) | claude (right top 70%) + terminal (right bottom 30%)
      tmux split-window -h -l 40%
      tmux send-keys "claude" Enter
      tmux split-window -v -l 30%
      tmux select-pane -t 0
      tmux send-keys "nvim" Enter
    '';

    monitor = pkgs.writeShellScript "tmux-layout-monitor" ''
      # 4-pane grid for watching logs/services
      tmux split-window -h -l 50%
      tmux split-window -v -l 50%
      tmux select-pane -t 0
      tmux split-window -v -l 50%
      tmux select-pane -t 0
    '';

    git = pkgs.writeShellScript "tmux-layout-git" ''
      # Full-screen lazygit
      tmux send-keys "lazygit" Enter
    '';
  };
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
      enableTmuxIntegration = true;
      tmuxKey = "T";
      settings =
        {
          session = cfg.sessions;
        }
        // lib.optionalAttrs (cfg.defaultLayout != "none") {
          default_session = {
            startup_script = "${layouts.${cfg.defaultLayout}}";
          };
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
      clock24 = true;
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
        bind Space switch-client -l      # prefix+Space = last session
        bind BSpace last-window          # prefix+BackSpace = last window

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

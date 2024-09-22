{
  config,
  pkgs,
  lib,
  ...
}:

let
  tmux-sessionx = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-sessionx";
    version = "unstable-2023-01-06";
    src = pkgs.fetchFromGitHub {
      owner = "omerxx";
      repo = "tmux-sessionx";
      rev = "86efe3af2298c43c48480247677717b0d911d880";
      sha256 = "sha256-tzRtDKJ88Ch1zDgFUJM3BKACt3dDGWfEtqbhqifmqso";
    };
  };
  tmux-which-key= pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-which-key";
    version = "unstable-2023-01-06";
    src = pkgs.fetchFromGitHub {
      owner = "alexwforsythe";
      repo = "tmux-which-key";
      rev = "1f419775caf136a60aac8e3a269b51ad10b51eb6";
      sha256 = "sha256-X7FunHrAexDgAlZfN+JOUJvXFZeyVj9yu6WRnxMEA8E=";
    };
  };
in
{
  options = {
    tmux = {
      enable = lib.mkEnableOption {
        description = "Enable tmux.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.tmux.enable {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      resizeAmount = 10;
      shell = "${pkgs.zsh}/bin/zsh";
      aggressiveResize = true;
      clock24 = true;
      escapeTime = 0;
      terminal = "screen-256color";
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      shortcut = "a";
      plugins = with pkgs.tmuxPlugins; [
        tmux-sessionx
        sensible
        yank
        resurrect
        yank
        continuum
        vim-tmux-navigator
        tmux-thumbs
        tmux-fzf
        prefix-highlight
        fzf-tmux-url
        catppuccin
        tmux-which-key
      ];

      extraConfig = ''
        set -g mouse on
        bind-key C-a last-window
        set -g focus-events on
        set -g status-interval 1
        set -g automatic-rename
        set -g automatic-rename-format '#{pane_current_command}'
        set -g @catppuccin_flavour 'frappe'
        set -g @catppuccin_pane_border_status "top"
        bind \\ split-window -h -c '#{pane_current_path}'
        bind - split-window -v -c '#{pane_current_path}'
        set -s extended-keys on
        set -g xterm-keys on
        set -as terminal-features 'xterm*:extkeys'
        set -g @continuum-restore 'on'
        set -g @resurrect-strategy-nvim 'session'
        set -g @catppuccin_window_left_separator ""
        set -g @catppuccin_window_right_separator " "
        set -g @catppuccin_window_middle_separator " █"
        set -g @catppuccin_window_number_position "right"
        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_default_text "#W"
        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
        set -g @catppuccin_status_modules_right "directory meetings date_time"
        set -g @catppuccin_status_modules_left "session"
        set -g @catppuccin_status_left_separator  " "
        set -g @catppuccin_status_right_separator " "
        set -g @catppuccin_status_right_separator_inverse "no"
        set -g @catppuccin_status_fill "icon"
        set -g @catppuccin_status_connect_separator "no"
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

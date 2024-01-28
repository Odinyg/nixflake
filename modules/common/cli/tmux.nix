{ config, pkgs, lib, ... }: 

      let
      tmux-sessionx= pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-sessionx";
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "omerxx";
        repo = "tmux-sessionx";
        rev = "86efe3af2298c43c48480247677717b0d911d880";
        sha256 = "sha256-tzRtDKJ88Ch1zDgFUJM3BKACt3dDGWfEtqbhqifmqso";
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

  config.home-manager.users.none = lib.mkIf config.tmux.enable {
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
      nord   
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
    ];

    extraConfig = ''
      set -g mouse on
      bind-key C-a last-window
      set -g focus-events on
      set -g status-interval 1
      set -g automatic-rename
      set -g automatic-rename-format '#{pane_current_command}'
      bind \\ split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'
      set -g @sessionx-bind 'o'
      set -g @sessionx-window-height '85%'
      set -g @sessionx-window-width '75%'
      set -g @sessionx-zoxide-mode 'on'
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

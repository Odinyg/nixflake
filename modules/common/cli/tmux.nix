{ config, pkgs, lib, ... }: {
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

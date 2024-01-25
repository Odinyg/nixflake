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
    aggressiveResize = true;
    clock24 = true;
    escapeTime = 50;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    shortcut = "a";
    plugins = with pkgs.tmuxPlugins; [
      gruvbox
    ];

    extraConfig = ''
      # Enable mouse
      set -g mouse on

      # 2x C-a goes back and fourth between most recent windows
      bind-key C-a last-window

      # For neovim
      set -g focus-events on

      # Update the status line every seconds
      set -g status-interval 1

      # auto window rename
      set -g automatic-rename
      set -g automatic-rename-format '#{pane_current_command}'
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

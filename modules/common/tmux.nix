{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    # Rather than constraining window size to the maximum size of any client
    # connected to the *session*, constrain window size to the maximum size of any
    # client connected to *that window*. Much more reasonable.
    aggressiveResize = true;

    clock24 = true;

    # Allows for faster key repetition
    escapeTime = 50;

    keyMode = "vi";
    # Overrides the hjkl and HJKL bindings for pane navigation and resizing in VI mode
    customPaneNavigationAndResize = true;

    shortcut = "a";

    plugins = with pkgs.tmuxPlugins; [
      nord
      tpm
      tmux-sensible
    ];

    extraConfig = ''
      set -g mouse on
      bind-key C-a last-window
      set -g focus-events on
      set -g status-interval 1
      set -g base-index 1
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
}

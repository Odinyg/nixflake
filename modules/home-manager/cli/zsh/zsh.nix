{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    history.path = "${config.xdg.stateHome}/zsh_history";
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      doc = "$HOME/Documents";
    };

    initContent = ''
      # Stub compdef if completion system isn't loaded yet (fixes errors in non-interactive shells)
      if (( ! $+functions[compdef] )); then
        compdef() { : }
      fi
      export PATH=$PATH:/usr/local/bin

      # Disable XON/XOFF flow control so Ctrl+S works for forward search
      stty -ixon
      bindkey '^S' history-incremental-search-forward

      # Auto-launch tmux if not already inside tmux, not in a tty, and tmux is available
      if [[ -z "$TMUX" && -z "$INSIDE_EMACS" && -z "$VSCODE_RESOLVING_ENVIRONMENT" && "$TERM_PROGRAM" != "vscode" && -t 0 ]]; then
        if command -v tmux &>/dev/null; then
          # Attach to first detached session, or create a new one
          detached=$(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null | awk '$2 == "0" { print $1; exit }')
          if [[ -n "$detached" ]]; then
            exec tmux attach-session -t "$detached"
          else
            exec tmux new-session
          fi
        fi
      fi
    '';
    envExtra = ''
            source <(kubectl completion zsh)
      export AGE_PUBLIC=age1sy97xhs7my3793xjeyggvam25qhdv63f05h3f3ftevqfkjsh7cpqapg6f2
    '';
    oh-my-zsh = {
      enable = true;
      theme = "cloud";
      #    custom = "$HOME/.config/zsh/oh-my-zsh";
      plugins = [
        "fzf"
        "sudo"
        "git"
        "docker"
        "1password"
        "direnv"
        "kubectl"
        "kubectx"
        "fluxcd"
        "gh"
        "minikube"
        "ssh"
        "tldr"
        "zsh-interactive-cd"
        "zoxide"
        "tailscale"
      ];
    };
  };

  xdg.configFile."zsh/quotes".source = ./scripts/quotes;
  xdg.configFile."zsh/quote.sh" = {
    source = ./scripts/quote.sh;
    executable = true;
  };
  home.packages = with pkgs; [
    ueberzugpp
    fzf
    ripgrep
    bat
    fd
  ];

}

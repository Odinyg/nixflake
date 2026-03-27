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
      export PATH=$PATH:/usr/local/bin

      # Disable XON/XOFF flow control so Ctrl+S works for forward search
      stty -ixon
      bindkey '^S' history-incremental-search-forward

      # Reset terminal state before each prompt to fix corruption from programs
      # that exit without restoring the terminal (e.g. Claude Code)
      precmd_reset_terminal() {
        stty sane 2>/dev/null
        printf '\e[?1l' 2>/dev/null
      }
      precmd_functions+=(precmd_reset_terminal)

      # SSH into modem with auto-filled password from 1Password
      modem() {
        sshpass -p "$(op item get w4zusfbv3ztnl4flzm2vrga6ki --fields password --reveal)" ssh -o StrictHostKeyChecking=no root@"$1"
      }

    '';
    envExtra = ''
      export AGE_PUBLIC=age1sy97xhs7my3793xjeyggvam25qhdv63f05h3f3ftevqfkjsh7cpqapg6f2
    '';
    oh-my-zsh = {
      enable = true;
      theme = "cloud";
      plugins = [
        "fzf"
        "sudo"
        "git"
        "docker"
        "1password"
        "direnv"
        "kubectl"
        "fluxcd"
        "gh"
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
    ripgrep
    bat
    fd
  ];

}

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

      # SSH into modem with auto-filled password from 1Password
      modem() {
        sshpass -p "$(op item get w4zusfbv3ztnl4flzm2vrga6ki --fields password --reveal)" ssh -o StrictHostKeyChecking=no root@"$1"
      }

    '';
    envExtra = ''
            source <(kubectl completion zsh)
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
    ripgrep
    bat
    fd
  ];

}

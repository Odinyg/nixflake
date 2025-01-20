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

    initExtra = '''';
    envExtra = ''
      source <(kubectl completion zsh)
      export TERM="xterm-256color"
    '';
    oh-my-zsh = {
      enable = true;
      theme = "cloud";
      #    custom = "$HOME/.config/zsh/oh-my-zsh";
      plugins = [
        "fzf"
        "tmux"
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
        "tmuxinator"
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
    #  kubectl-autocomplete
  ];

}

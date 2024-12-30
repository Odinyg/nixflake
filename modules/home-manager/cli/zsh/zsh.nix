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

    initExtra = ''
      $HOME/.config/zsh/quote.sh
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=*      r:|=*' 'l:|=* r:|=*'
      setopt NO_CASE_GLOB
      source <(kubectl completion zsh)
    '';
    envExtra = ''
      source <(kubectl completion zsh)
      export TERM="xterm-256color"
    '';
    oh-my-zsh = {
      enable = true;
      theme = "cloud";
      custom = "$HOME/.config/zsh/oh-my-zsh";
      plugins = [
        "fzf"
        "sudo"
        "git"
        "docker"
        "1password"
        "ripgrep"
        "direnv"
        "kubectl-autocomplete"
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
  ];

}

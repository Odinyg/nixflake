{ config, pkgs, ... }: {
   programs.zsh = {
    enable = true; 
    history.path = "${config.xdg.stateHome}/zsh_history";
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    
    dirHashes = {
    dl = "$HOME/Downloads";
    docs = "$HOME/Documents";
    doc = "$HOME/Documents";
    };

    programs.zsh.shellInit = ''
    $HOME/.config/zsh/quote.sh
    '';
    envExtra = ''
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
      ];
    };
  };


  xdg.configFile."zsh/quote.sh" = {
      source = ./scripts/quote.sh;
      executable = true;
      };
    home.packages = with pkgs; [
      ueberzugpp
      fzf
];

}

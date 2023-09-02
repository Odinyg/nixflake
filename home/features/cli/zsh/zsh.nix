{ config, home-manager,pkgs, ... }: {
   programs.zsh = {
    enable = true; 
    history.path = "${config.xdg.stateHome}/zsh_history";
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    dirHashes = {
    dl = "$HOME/Downloads";
    docs = "$HOME/Documents";
    doc = "$HOME/Documents";
    };
    envExtra = ''
    export PASS=$HOME/.secrets/pass

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
      ];
    };
  };


    home.packages = with pkgs; [
      ueberzugpp
      fzf
];

}

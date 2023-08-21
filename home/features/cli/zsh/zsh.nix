{ config, pkgs, ... }: {
   programs.zsh = {
    enable = true; 
    history.path = "${config.xdg.stateHome}/zsh_history";
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;






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
    # Prompt theme
    programs.starship = {
      enable = true;

      settings = {
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };



}

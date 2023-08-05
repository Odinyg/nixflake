{ pkgs, ... }: {
   programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "cloud";
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
}

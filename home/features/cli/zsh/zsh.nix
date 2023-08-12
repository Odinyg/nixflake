{ config, pkgs, ... }: {
   programs.zsh = {
    enable = true; 
    history.path = "${config.xdg.stateHome}/zsh_history";
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;



    shellAliases = {
    nixboot = "sudo nixos-rebuild boot --flake /home/none/nix/#myNixos";
    nixswitch = "sudo nixos-rebuild switch --flake /home/none/nix/#myNixos";
    };



  };
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


    home.packages = with pkgs; [
      ueberzugpp
      fzf

];
      initExtra = ''
        eval `gnome-keyring-daemon --start --components=ssh --daemonize 2> /dev/null`
        export SSH_AUTH_SOCK
      '';
    # Prompt theme
    starship = {
      enable = true;

      settings = {
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };



}

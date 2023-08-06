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
    shellAliases = {
    nixboot = "sudo nixos-rebuild boot --flake /home/none/nix/#myNixos";
    nixswitch = "sudo nixos-rebuild switch --flake /home/none/nix/#myNixos";
    };
  };
}

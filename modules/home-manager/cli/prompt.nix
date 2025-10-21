{ config, lib, ... }: {

  options = {
    prompt = {
      enable = lib.mkEnableOption {
        description = "Enable starship prompt";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.prompt.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        # Format configuration
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_status"
          "$kubernetes"
          "$docker_context"
          "$python"
          "$nodejs"
          "$golang"
          "$rust"
          "$nix_shell"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        # Character prompt
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        # Directory display
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };

        # Git branch
        git_branch = {
          format = "[$symbol$branch]($style) ";
          symbol = " ";
        };

        # Git status
        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          conflicted = "🏳";
          ahead = "⇡\${count}";
          behind = "⇣\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          untracked = "🤷";
          stashed = "📦";
          modified = "📝";
          staged = "[++($count)](green)";
          renamed = "👅";
          deleted = "🗑";
        };

        # Command duration
        cmd_duration = {
          min_time = 500;
          format = "took [$duration]($style) ";
        };

        # Kubernetes context
        kubernetes = {
          disabled = false;
          format = "[$symbol$context( ($namespace))]($style) ";
          symbol = "☸ ";
        };

        # Docker context
        docker_context = {
          format = "[$symbol$context]($style) ";
          symbol = "🐳 ";
        };

        # Programming languages
        python = {
          format = "[\${symbol}\${pyenv_prefix}(\${version} )(($virtualenv) )]($style)";
          symbol = "🐍 ";
        };

        nodejs = {
          format = "[$symbol($version )]($style)";
          symbol = "⬢ ";
        };

        golang = {
          format = "[$symbol($version )]($style)";
          symbol = "🐹 ";
        };

        rust = {
          format = "[$symbol($version )]($style)";
          symbol = "🦀 ";
        };

        # Nix shell indicator
        nix_shell = {
          format = "[$symbol$state( ($name))]($style) ";
          symbol = "❄️  ";
        };

        # Username/hostname (only show when SSH)
        username = {
          show_always = false;
          format = "[$user]($style)@";
        };

        hostname = {
          ssh_only = true;
          format = "[$hostname]($style) in ";
        };
      };
    };
  };
}

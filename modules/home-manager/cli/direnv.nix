{ config, lib, ... }:
{

  options = {
    direnv = {
      enable = lib.mkEnableOption "direnv automatic environment switching";
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.direnv.enable {

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;

      # Custom stdlib functions
      stdlib = ''
        # Layout for Python projects with virtualenv
        layout_python() {
          local python_version=''${1:-python3}
          [[ $# -gt 0 ]] && shift
          local venv_dir="''${1:-.venv}"

          if [[ ! -d "$venv_dir" ]]; then
            log_status "Creating virtualenv in $venv_dir"
            $python_version -m venv "$venv_dir"
          fi

          source "$venv_dir/bin/activate"
        }

        # Layout for Node.js projects with automatic nvm/node version
        layout_node() {
          local node_version="''${1:-}"
          if [[ -f .nvmrc ]]; then
            node_version=$(cat .nvmrc)
          fi

          if [[ -n "$node_version" ]]; then
            log_status "Using Node.js version: $node_version"
          fi

          PATH_add node_modules/.bin
        }

        # Layout for Go projects
        layout_go() {
          export GOPATH="$PWD/.go"
          export GOBIN="$GOPATH/bin"
          PATH_add "$GOBIN"
        }

        # Layout for Rust projects
        layout_rust() {
          export CARGO_HOME="$PWD/.cargo"
          export CARGO_TARGET_DIR="$PWD/target"
          PATH_add "$CARGO_HOME/bin"
        }

        # Load environment from .env file
        dotenv_if_exists() {
          if [[ -f .env ]]; then
            dotenv .env
          fi
        }
      '';
    };

    # Create example .envrc templates
    home.file.".config/direnv/templates/nix-flake.envrc" = {
      text = ''
        # Nix flake development environment
        use flake

        # Optionally load .env file
        dotenv_if_exists
      '';
    };

    home.file.".config/direnv/templates/python.envrc" = {
      text = ''
        # Python development environment
        use nix
        layout python python3

        # Optionally load .env file
        dotenv_if_exists
      '';
    };

    home.file.".config/direnv/templates/node.envrc" = {
      text = ''
        # Node.js development environment
        use nix
        layout node

        # Optionally load .env file
        dotenv_if_exists
      '';
    };

    home.file.".config/direnv/templates/go.envrc" = {
      text = ''
        # Go development environment
        use nix
        layout go

        # Optionally load .env file
        dotenv_if_exists
      '';
    };

    home.file.".config/direnv/templates/rust.envrc" = {
      text = ''
        # Rust development environment
        use nix
        layout rust

        # Optionally load .env file
        dotenv_if_exists
      '';
    };
  };
}

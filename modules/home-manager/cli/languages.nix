{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages;
in
{
  options = {
    languages = {
      enable = lib.mkEnableOption "programming language runtimes";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Programming Languages
      python3 # Python runtime
      go # Go programming language
      nodejs # Node.js runtime (includes npm)
      bun # JavaScript runtime and package manager

      # Shell Development Tools
      shellcheck # Shell script static analysis

      # Python Development Tools
      ruff # Python linter and formatter
      mypy # Python static type checker
      python3Packages.pytest # Python test framework
    ];
  };
}

{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.claudeSkills;
in
{
  options.claudeSkills.enable = lib.mkEnableOption "Claude Code user-level skills";

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.user} = {
      home.file.".claude/skills/rendercv".source = "${inputs.rendercv-skill}/skills/rendercv";
    };
  };
}

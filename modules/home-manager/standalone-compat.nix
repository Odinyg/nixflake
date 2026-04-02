{ lib, ... }:
{
  # Standalone Home-Manager Compatibility Layer
  #
  # ARCHITECTURE DECISION: Compatibility shim for legacy NixOS-integrated HM modules.
  #
  # Existing modules under modules/home-manager/ are written as NixOS modules that emit
  # Home Manager config through `config.home-manager.users.${config.user}` and also read
  # top-level NixOS options like `config.user` and `config.hyprland.*`.
  #
  # In standalone Home Manager, there is no `home-manager.users` wrapper because the
  # current module graph already is the user's Home Manager config. This shim recreates
  # the minimal option surface those legacy modules expect.
  #
  # Note: A pure merge-back shim (`config = lib.mkMerge (lib.attrValues config.home-manager.users)`) was
  # attempted first, including a `submoduleWith { freeformType = lib.types.anything; }` user type so
  # multiple legacy modules could merge under `home-manager.users.<name>`. In standalone HM that still
  # triggers module-system recursion when the shim both defines and consumes the same option tree.
  #
  # Current migration approach: keep this shim responsible for the shared option surface, and let pilot
  # legacy modules add a direct standalone branch while preserving their original NixOS behavior.
  #
  # NixOS behavior is unchanged because this file is only imported by standalone HM.
  options = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary user of the system";
    };

    hyprland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland window manager";
      };

      kanshi = {
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "Kanshi display profiles for dynamic display configuration";
        };
      };

      monitors = {
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional Hyprland monitor and workspace configuration";
        };
      };
    };

    home-manager.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [
            {
              freeformType = lib.types.anything;
            }
          ];
        }
      );
      default = { };
      description = "Home-manager user configurations collected in standalone mode";
    };
  };

}

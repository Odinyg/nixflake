# Hyprland mutable overrides learnings

- `just` script recipes need the shebang body to stay fully indented; unindented heredoc lines break parsing.
- Using `<<- 'OVERRIDE'` lets the Hyprland reset recipe keep all lines tab-indented while still writing a clean overrides file.
- `theme-promote hyprland` should stay manual-only: show current overrides, explain it is Nix attrs, and point edits into `modules/home-manager/desktop/hyprland/default.nix`.
- `$HOME` paths work across users and avoid hardcoded usernames in mutable desktop config helpers.

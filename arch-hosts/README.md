# Arch Linux Host Configurations

This directory contains home-manager configurations for Arch Linux (and other non-NixOS) systems.

## Directory Structure

```
arch-hosts/
├── README.md           # This file
├── example/            # Example configuration
│   └── home.nix       # Sample home-manager config
└── yourhostname/      # Your actual configurations
    └── home.nix       # Your home-manager config
```

## Creating a New Configuration

### Quick Method

```bash
# Copy the example
cp -r arch-hosts/example arch-hosts/$(hostname)

# Update username
sed -i "s/youruser/$USER/g" arch-hosts/$(hostname)/home.nix

# Customize further
vim arch-hosts/$(hostname)/home.nix
```

### Manual Method

1. **Create directory:**
   ```bash
   mkdir -p arch-hosts/yourhostname
   ```

2. **Create home.nix:**
   ```bash
   cat > arch-hosts/yourhostname/home.nix << 'EOF'
   { config, pkgs, lib, inputs, ... }:
   {
     imports = [
       ../../profiles/home-manager/base.nix
     ];

     home.username = "yourusername";
     home.homeDirectory = "/home/yourusername";
     home.stateVersion = "25.05";

     programs.home-manager.enable = true;

     # Enable modules you want
     hyprland.enable = true;
     neovim.enable = true;
     zsh.enable = true;
   }
   EOF
   ```

3. **Add to flake.nix:**
   
   Edit the `homeConfigurations` section in `flake.nix`:
   ```nix
   "yourusername@yourhostname" = mkStandaloneHomeConfig {
     username = "yourusername";
     stateVersion = "25.05";
     hostname = "yourhostname";
     extraModules = [ ./arch-hosts/yourhostname/home.nix ];
   };
   ```

4. **Build:**
   ```bash
   home-manager switch --flake .#yourusername@yourhostname
   ```

## Available Profiles

You can import different profiles in your `home.nix`:

- `../../profiles/home-manager/base.nix` - Base configuration with essential tools

## Module Configuration

### Enabling Modules

```nix
{
  # Desktop Environment
  hyprland.enable = true;
  
  # Terminal & CLI
  neovim.enable = true;
  zsh.enable = true;
  kitty.enable = true;
  zellij.enable = true;
  
  # Development
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;
  
  # Applications
  discord.enable = true;
  chromium.enable = true;
  firefox.enable = true;
  
  # Theme
  styling.enable = true;
  styling.theme = "nord";
  styling.polarity = "dark";
}
```

### Adding Packages

```nix
{
  home.packages = with pkgs; [
    htop
    ripgrep
    fd
    bat
    eza
  ];
}
```

### Custom Configuration

You can override any home-manager option:

```nix
{
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };
  
  programs.zsh = {
    shellAliases = {
      ll = "ls -la";
      update = "just upgrade";
    };
  };
}
```

## Multiple Configurations

You can have multiple configurations for the same user:

```
arch-hosts/
├── work/
│   └── home.nix      # Work setup
├── personal/
│   └── home.nix      # Personal setup
└── minimal/
    └── home.nix      # Minimal setup for servers
```

Then in `flake.nix`:
```nix
homeConfigurations = {
  "user@work" = mkStandaloneHomeConfig {
    extraModules = [ ./arch-hosts/work/home.nix ];
  };
  "user@personal" = mkStandaloneHomeConfig {
    extraModules = [ ./arch-hosts/personal/home.nix ];
  };
};
```

Switch between them:
```bash
home-manager switch --flake .#user@work
home-manager switch --flake .#user@personal
```

## System Requirements

These configurations assume you have installed via pacman:

**Required:**
- Hyprland (if using hyprland module)
- PipeWire (audio)
- NetworkManager (networking)
- Polkit (privilege escalation)

**Recommended:**
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk
- qt5-wayland, qt6-wayland
- bluez (Bluetooth)

See [ARCH-SETUP.md](../ARCH-SETUP.md) for complete installation instructions.

## Troubleshooting

### Module not found

Make sure you're importing from `../../modules/home-manager`:
```nix
imports = [
  ../../profiles/home-manager/base.nix
];
```

### Username mismatch

Ensure `home.username` matches your actual username:
```bash
echo $USER  # Check your username
```

### Build errors

Check syntax:
```bash
nix flake check
```

Verbose build:
```bash
home-manager switch --flake .#user@host --verbose
```

## Documentation

- **Quick Start:** [../ARCH-QUICKSTART.md](../ARCH-QUICKSTART.md)
- **Full Setup Guide:** [../ARCH-SETUP.md](../ARCH-SETUP.md)
- **Migration Guide:** [../NIXOS-TO-ARCH.md](../NIXOS-TO-ARCH.md)
- **Arch README:** [../README-ARCH.md](../README-ARCH.md)

## Examples

### Minimal Configuration

```nix
{ config, pkgs, ... }:
{
  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # Just the essentials
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;
}
```

### Full Workstation

```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [ ../../profiles/home-manager/base.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "25.05";

  # Everything enabled
  hyprland.enable = true;
  neovim.enable = true;
  zsh.enable = true;
  kitty.enable = true;
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;
  discord.enable = true;
  chromium.enable = true;
  development.enable = true;
  kubernetes.enable = true;
  
  styling.enable = true;
  styling.theme = "nord";
}
```

## Tips

1. **Start with the example:** Copy `example/home.nix` and modify
2. **Enable incrementally:** Start with basic modules, add more as needed
3. **Test before committing:** Use `home-manager build` to test without switching
4. **Version control:** Commit your configurations to git
5. **Document changes:** Add comments explaining your customizations

## Getting Help

- Check [example/home.nix](./example/home.nix) for a comprehensive example
- Read the [full setup guide](../ARCH-SETUP.md)
- Run `just --list` for available commands
- Use `nix flake check` to validate configuration

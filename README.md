# Kanata Darwin Nix

An opinionated Nix flake that provides [Kanata](https://github.com/jtroo/kanata) pre-built binaries, related tools, and a nix-darwin module for macOS.

Kanata is a cross-platform software keyboard remapper that improves keyboard comfort and usability with advanced customisation.

> **Note for Linux users**: This flake is macOS-only. For Linux, use the [kanata package from nixpkgs](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/kanata/package.nix) instead.

## Features

- Automatic updates via GitHub Actions (daily)
- macOS support (x86_64, aarch64)
- Direct downloads from official GitHub releases
- SHA256 checksum verification
- Binary cache via [Cachix](https://app.cachix.org/cache/ryoppippi) for faster builds
- **nix-darwin module** for automatic service management
- **kanata-vk-agent** for app-specific key mappings
- **Karabiner-DriverKit** virtual HID device driver

## Why Use This Instead of nixpkgs?

While Kanata is available in nixpkgs, this flake provides several advantages for macOS users:

### ⚡ Zero Build Time

- **Pre-built binaries**: Downloads official binaries directly - no Rust compilation needed
- **Instant installation**: Skip the lengthy cargo build process entirely
- **Identical to official releases**: Same binaries the Kanata maintainers ship

### 🚀 Always Up-to-Date

- **Daily automated updates**: GitHub Actions checks for new releases every day
- **No waiting for nixpkgs**: Get new Kanata versions immediately, not weeks later
- **Automatic hash verification**: SHA256 checksums fetched directly from releases

### 🍎 macOS-Specific Goodies

- **nix-darwin module**: Automatic launchd service management out of the box
- **kanata-vk-agent**: App-specific key mappings (not in nixpkgs!)
- **Karabiner-DriverKit**: Virtual HID driver installation handled automatically
- **Input Monitoring**: Symlinks in `/Applications` for permissions management

### 🎯 Simple Integration

- **One flake, everything included**: Kanata + vk-agent + driver + service module
- **Minimal dependencies**: Only requires nixpkgs

## Binary Cache (Cachix)

This overlay provides pre-built binaries via [Cachix](https://app.cachix.org/cache/ryoppippi). Using the binary cache avoids rebuilding packages locally and significantly speeds up installation.

### Setup Cachix

**Option 1: Using Cachix CLI**

```bash
cachix use ryoppippi
```

**Option 2: Manual Configuration**

Add to your Nix configuration:

```nix
# NixOS (configuration.nix)
nix.settings = {
  substituters = [ "https://ryoppippi.cachix.org" ];
  trusted-public-keys = [ "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=" ];
};

# Or in ~/.config/nix/nix.conf
# extra-substituters = https://ryoppippi.cachix.org
# extra-trusted-public-keys = ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=
```

**Option 3: In your flake.nix**

```nix
{
  nixConfig = {
    extra-substituters = [ "https://ryoppippi.cachix.org" ];
    extra-trusted-public-keys = [ "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=" ];
  };

  # ... rest of your flake
}
```

**Option 4: Using devenv**

```nix
{
  cachix.pull = [ "ryoppippi" ];
}
```

## Usage

### Quick Start

Try Kanata without installation:

```bash
# Run Kanata directly
nix run github:ryoppippi/kanata-darwin-nix -- --version

# Or enter a shell with Kanata available
nix shell github:ryoppippi/kanata-darwin-nix
kanata --version
```

### With Flakes

#### Simple usage

Add the overlay to your flake inputs:

```nix
{
  inputs = {
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };
}
```

Then use `pkgs.kanata` in your configuration after adding the overlay to your `pkgs`.

#### Add to nix-darwin (Simple)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };

  outputs = { nixpkgs, nix-darwin, kanata-darwin-nix, ... }: {
    darwinConfigurations.yourhostname = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ kanata-darwin-nix.overlays.default ];
          environment.systemPackages = [ pkgs.kanata ];
        })
      ];
    };
  };
}
```

#### Add to nix-darwin (With Service Module)

This overlay provides a nix-darwin module that automatically manages Kanata as a launchd service. It handles:

- Installing the Karabiner-DriverKit virtual HID device driver
- Creating symlinks in `/Applications` for Input Monitoring permissions
- Running Kanata as a launchd daemon
- Optionally running kanata-vk-agent for app-specific key mappings

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };

  outputs = { nixpkgs, nix-darwin, kanata-darwin-nix, ... }: {
    darwinConfigurations.yourhostname = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        kanata-darwin-nix.darwinModules.default
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ kanata-darwin-nix.overlays.default ];

          services.kanata = {
            enable = true;
            keyboards = {
              default = {
                configFile = ./kanata.kbd;
                port = 5829;
                vkAgent = {
                  enable = true;
                  blacklist = [
                    "com.hnc.Discord"
                    "com.openai.chat"
                  ];
                };
              };
            };
          };
        })
      ];
    };
  };
}
```

##### Multiple Keyboards

You can configure multiple keyboards with different settings. Each keyboard gets its own launchd daemon:

```nix
services.kanata = {
  enable = true;
  keyboards = {
    macbook = {
      configFile = ./keyboards/macbook.kbd;
      port = 5829;
      vkAgent = {
        enable = true;
        blacklist = [ "com.hnc.Discord" ];
      };
    };
    hhkb = {
      configFile = ./keyboards/hhkb.kbd;
      port = 5830;
      vkAgent.enable = true;
    };
  };
};
```

##### Service Module Options

| Option                                               | Type    | Description                         |
| ---------------------------------------------------- | ------- | ----------------------------------- |
| `services.kanata.enable`                             | bool    | Enable Kanata service               |
| `services.kanata.package`                            | package | Kanata package to use               |
| `services.kanata.vkAgentPackage`                     | package | kanata-vk-agent package             |
| `services.kanata.karabinerDriverKitPackage`          | package | Karabiner-DriverKit package         |
| `services.kanata.keyboards`                          | attrsOf | Keyboard configurations             |
| `services.kanata.keyboards.<name>.configFile`        | path    | Path to `.kbd` config file          |
| `services.kanata.keyboards.<name>.port`              | port    | TCP port for kanata                 |
| `services.kanata.keyboards.<name>.extraArgs`         | list    | Extra arguments for kanata          |
| `services.kanata.keyboards.<name>.vkAgent.enable`    | bool    | Enable vk-agent for this keyboard   |
| `services.kanata.keyboards.<name>.vkAgent.blacklist` | list    | Bundle IDs to exclude from vk-agent |
| `services.kanata.keyboards.<name>.vkAgent.extraArgs` | list    | Extra arguments for vk-agent        |

##### macOS Permissions

After enabling the service, you need to grant Input Monitoring permission:

1. Open **System Settings** > **Privacy & Security** > **Input Monitoring**
2. Add `/Applications/kanata`
3. If using vk-agent, also add `/Applications/kanata-vk-agent`

> **Note**: When kanata is updated, the nix store path changes and the symlink target changes. You may need to remove and re-add `/Applications/kanata` in Input Monitoring settings after updates.

#### Add to devShell

Use Kanata in a project-specific development environment.

**Method 1: Direct package reference (Recommended)**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };

  outputs = { nixpkgs, kanata-darwin-nix, ... }:
    let
      systems = [ "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              kanata-darwin-nix.packages.${system}.default
            ];
          };
        }
      );
    };
}
```

**Method 2: Using overlay**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };

  outputs = { nixpkgs, kanata-darwin-nix, ... }:
    let
      systems = [ "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ kanata-darwin-nix.overlays.default ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.kanata ];
          };
        }
      );
    };
}
```

#### Add to home-manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    kanata-darwin-nix.url = "github:ryoppippi/kanata-darwin-nix";
  };

  outputs = { nixpkgs, home-manager, kanata-darwin-nix, ... }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ kanata-darwin-nix.overlays.default ];
      };
      modules = [{
        home.packages = [ pkgs.kanata ];
      }];
    };
  };
}
```

### Without Flakes

```nix
let
  kanata-darwin-nix = import (builtins.fetchTarball {
    url = "https://github.com/ryoppippi/kanata-darwin-nix/archive/main.tar.gz";
  });
  pkgs = import <nixpkgs> {
    overlays = [ kanata-darwin-nix.overlays.default ];
  };
in
  pkgs.kanata
```

## Available Packages

| Package               | Description                                   |
| --------------------- | --------------------------------------------- |
| `kanata`              | Kanata keyboard remapper (pre-built binary)   |
| `kanata-vk-agent`     | Virtual key agent for app-specific mappings   |
| `karabiner-driverkit` | Karabiner-DriverKit virtual HID device driver |

When using the overlay, packages are available as `pkgs.kanata`, `pkgs.kanata-vk-agent`, and `pkgs.karabiner-driverkit`.

## How It Works

1. The `update.ts` script fetches the latest releases from GitHub API for all packages:
   - **kanata**: from [jtroo/kanata](https://github.com/jtroo/kanata)
   - **kanata-vk-agent**: from [devsunb/kanata-vk-agent](https://github.com/devsunb/kanata-vk-agent)
   - **karabiner-driverkit**: from [pqrs-org/Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)
2. It retrieves official SHA256 checksums and converts them to SRI format
3. GitHub Actions runs the update script daily and commits any changes
4. The flake provides pre-built binaries for all supported platforms

## Supported Platforms

- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

> **Linux users**: Use [nixpkgs kanata](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/kanata/package.nix) instead.

## Development

Development tooling (formatters, linters, git hooks) is separated into `dev/flake.nix` to keep the main flake minimal for consumers.

### Setup development environment

**Option 1: Using direnv (Recommended)**

If you have [direnv](https://direnv.net/) installed:

```bash
direnv allow
```

**Option 2: Manual**

Enter the development shell:

```bash
nix develop ./dev
```

This automatically installs git pre-commit hooks that run:

- **nixfmt-rfc-style** - Nix code formatter (RFC 166)
- **deadnix** - Dead code detection
- **statix** - Nix linter
- **typos** - Spell checker

### Update sources manually

```bash
./update.ts
```

### Test the overlay

```bash
nix build
./result/bin/kanata --version
```

### Run checks manually

```bash
# Format all Nix files
nix fmt ./dev

# Run all checks (formatting, linting)
nix flake check ./dev
```

## Related Projects

- [kanata](https://github.com/jtroo/kanata) - Official Kanata repository
- [kanata-vk-agent](https://github.com/devsunb/kanata-vk-agent) - Virtual key agent for app-specific mappings
- [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice) - Virtual HID device driver for macOS
- [nixpkgs kanata](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/kanata/package.nix) - Official nixpkgs package for Kanata

## Credits

- Kanata by [jtroo](https://github.com/jtroo)
- kanata-vk-agent by [devsunb](https://github.com/devsunb)
- Karabiner-DriverKit by [pqrs-org](https://github.com/pqrs-org)

## Licence

MIT

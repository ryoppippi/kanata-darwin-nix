# Kanata Overlay

A Nix flake overlay that provides pre-built [Kanata](https://github.com/jtroo/kanata) binaries from official GitHub releases.

Kanata is a cross-platform software keyboard remapper that improves keyboard comfort and usability with advanced customisation.

## Features

- Automatic updates via GitHub Actions (daily)
- Multi-platform support: Linux (x86_64) and macOS (x86_64, aarch64)
- Direct downloads from official GitHub releases
- SHA256 checksum verification
- Flake and non-flake support
- Binary cache via [Cachix](https://app.cachix.org/cache/ryoppippi) for faster builds

## Why Use This Overlay?

While Kanata is available in nixpkgs, this overlay provides several advantages:

### Faster Updates

- **Automated updates**: GitHub Actions checks for new releases daily
- **Latest binaries**: Get new releases quickly without waiting for nixpkgs updates

### Pre-built Binaries

- **No compilation**: Downloads pre-built binaries directly from official releases
- **Faster installation**: No need to compile Rust code locally
- **Consistent behaviour**: Same binaries as official releases

### Simplified Setup

- **Easy integration**: Simple overlay that works with any Nix setup
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
nix run github:ryoppippi/kanata-overlay -- --version

# Or enter a shell with Kanata available
nix shell github:ryoppippi/kanata-overlay
kanata --version
```

### With Flakes

#### Simple usage

Add the overlay to your flake inputs:

```nix
{
  inputs = {
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };
}
```

Then use `pkgs.kanata` in your configuration after adding the overlay to your `pkgs`.

#### Add to NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };

  outputs = { nixpkgs, kanata-overlay, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ kanata-overlay.overlays.default ];
          environment.systemPackages = [ pkgs.kanata ];
        })
      ];
    };
  };
}
```

#### Add to nix-darwin

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };

  outputs = { nixpkgs, nix-darwin, kanata-overlay, ... }: {
    darwinConfigurations.yourhostname = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ kanata-overlay.overlays.default ];
          environment.systemPackages = [ pkgs.kanata ];
        })
      ];
    };
  };
}
```

#### Add to devShell

Use Kanata in a project-specific development environment.

**Method 1: Direct package reference (Recommended)**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };

  outputs = { nixpkgs, kanata-overlay, ... }:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
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
              kanata-overlay.packages.${system}.default
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
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };

  outputs = { nixpkgs, kanata-overlay, ... }:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ kanata-overlay.overlays.default ];
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
    kanata-overlay.url = "github:ryoppippi/kanata-overlay";
  };

  outputs = { nixpkgs, home-manager, kanata-overlay, ... }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ kanata-overlay.overlays.default ];
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
  kanata-overlay = import (builtins.fetchTarball {
    url = "https://github.com/ryoppippi/kanata-overlay/archive/main.tar.gz";
  });
  pkgs = import <nixpkgs> {
    overlays = [ kanata-overlay.overlays.default ];
  };
in
  pkgs.kanata
```

## Available Packages

When using the overlay, the package is available as `pkgs.kanata`.

## How It Works

1. The `update.ts` script fetches the latest release from GitHub API
2. It retrieves official SHA256 checksums from the `sha256sums` file and converts them to SRI format
3. GitHub Actions runs the update script daily and commits any changes
4. The flake provides pre-built binaries for all supported platforms

## Supported Platforms

- `x86_64-linux`
- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

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

### Update sources manually

```bash
bun ./update.ts
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
- [nixpkgs kanata](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/kanata/package.nix) - Official nixpkgs package for Kanata

## Credits

- Kanata by [jtroo](https://github.com/jtroo)

## Licence

MIT

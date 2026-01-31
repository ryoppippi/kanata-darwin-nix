# Kanata Darwin Nix

This repository provides a Nix flake for [Kanata](https://github.com/jtroo/kanata) and related tools for macOS keyboard remapping.

> **Note**: This flake is macOS-only. For Linux, use [nixpkgs kanata](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/kanata/package.nix).

## Repository Structure

```
kanata-darwin-nix/
├── flake.nix              # Main flake with overlay, darwinModules, lib, and checks
├── flake.lock             # Locked dependencies
├── packages/
│   ├── kanata/
│   │   ├── default.nix    # Package wrapper
│   │   ├── package.nix    # Core package definition
│   │   └── sources.json   # Version and hashes
│   ├── kanata-vk-agent/
│   │   ├── default.nix
│   │   ├── package.nix
│   │   └── sources.json
│   └── karabiner-driverkit/
│       ├── default.nix
│       ├── package.nix
│       └── sources.json
├── modules/
│   └── darwin/
│       └── default.nix    # nix-darwin module for service management
├── tests/
│   └── basic.kbd          # Test kanata config for CI validation
├── update.ts              # Update script (Bun/TypeScript with Nix shebang)
├── dev/
│   └── flake.nix          # Development tools (formatters, linters)
├── .github/
│   ├── workflows/
│   │   ├── update.yaml    # Automated updates (daily)
│   │   └── check.yaml     # CI validation (includes config validation)
│   └── actions/
│       └── setup-nix/     # Reusable Nix setup action
├── README.md              # User documentation
├── CLAUDE.md              # This file
└── LICENSE                # MIT licence
```

## Packages

### kanata

Downloads pre-built binaries from [jtroo/kanata](https://github.com/jtroo/kanata) releases.

- **Platforms**: x86_64-darwin, aarch64-darwin
- **macOS variant**: Uses `cmd_allowed` binary (required for command key remapping)
- **sources.json** contains platform-specific URLs and SRI hashes

### kanata-vk-agent

Downloads pre-built binaries from [devsunb/kanata-vk-agent](https://github.com/devsunb/kanata-vk-agent) releases.

- **Platforms**: x86_64-darwin, aarch64-darwin
- **Purpose**: Enables app-specific key mappings via bundle ID blacklist

### karabiner-driverkit

Downloads `.pkg` installer from [pqrs-org/Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice) releases.

- **Platforms**: x86_64-darwin, aarch64-darwin
- **Purpose**: Virtual HID device driver required for Kanata on macOS

## Library Functions

### lib.checkKanataConfig

Validates Kanata configuration files using `kanata --check`. Returns a derivation that succeeds if the config is valid.

```nix
kanata-overlay.lib.checkKanataConfig {
  pkgs = nixpkgs.legacyPackages.aarch64-darwin;
  configFile = ./kanata.kbd;
  name = "my-kanata-config";  # optional
  kanataPackage = pkgs.kanata;  # optional, uses overlay's kanata by default
}
```

Used in flake checks to validate configs in CI.

## nix-darwin Module

Located at `modules/darwin/default.nix`. Provides `services.kanata` options:

### What It Does

1. **Installs Karabiner-DriverKit** via activation script (only if not already installed)
2. **Activates the driver** via Karabiner-VirtualHIDDevice-Manager
3. **Creates symlinks** in `/Applications` for Input Monitoring permissions
4. **Configures launchd daemons** for each keyboard configuration
5. **Configures launchd agents** for kanata-vk-agent (optional per keyboard)

### Key Implementation Details

- Kanata runs as a **system daemon** (`launchd.daemons`)
- kanata-vk-agent runs as a **user agent** (`launchd.agents`)
- Uses `/Applications/kanata` symlink for Input Monitoring permissions
- **Note**: When kanata updates, the nix store path changes and Input Monitoring permission must be re-granted
- Logs stored at `/var/log/kanata-*.log` (daemon) and `/tmp/kanata-vk-agent-*.log` (agent)

## update.ts

TypeScript script with Nix shebang that updates all three packages:

```typescript
#!/usr/bin/env nix
/*
#! nix shell --inputs-from . nixpkgs#bun nixpkgs#oxfmt -c bun
*/
```

Runs with Nix shebang - no need to install bun separately.

### Update Process

1. Fetches latest release from GitHub API for each repo
2. For kanata: Downloads `sha256sums` file and converts to SRI format
3. For kanata-vk-agent and karabiner-driverkit: Uses `nix-prefetch-url` to get hashes
4. Updates respective `sources.json` files

Run with: `./update.ts` or `bun ./update.ts`

## Common Tasks

### Building Packages

```bash
nix build .#kanata
nix build .#kanata-vk-agent
nix build .#karabiner-driverkit
```

### Updating to Latest Versions

```bash
./update.ts
nix build  # Verify all packages build
```

### Formatting

```bash
cd dev && nix fmt
```

### Running Checks

```bash
# Run config validation and package checks
nix flake check -L

# Run dev checks (formatting, linting)
cd dev && nix flake check -L
```

## Supported Platforms

- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

## GitHub Actions

- **update.yaml**: Runs daily to check for new releases of all packages
- **check.yaml**: Runs on PRs and pushes to validate formatting, build, and config validation (macOS only)

## Notes for Development

- The main flake has minimal dependencies (only nixpkgs)
- Development tools are in `dev/flake.nix` to avoid polluting the main flake
- Kanata on macOS requires the Karabiner-DriverKit VirtualHIDDevice driver
- The nix-darwin module handles driver installation automatically
- Input Monitoring permission must be granted manually via System Settings

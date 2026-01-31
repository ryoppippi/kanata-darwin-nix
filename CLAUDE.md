# Kanata Overlay

This repository provides a Nix flake overlay for [Kanata](https://github.com/jtroo/kanata), a cross-platform keyboard remapper.

## Repository Structure

```
kanata-overlay/
├── flake.nix          # Main flake with overlay export
├── flake.lock         # Locked dependencies
├── default.nix        # Package wrapper
├── package.nix        # Core package definition
├── sources.json       # Binary version and hashes
├── update.ts          # Update script (Bun/TypeScript)
├── dev/
│   └── flake.nix      # Development tools (formatters, linters)
├── .github/
│   ├── workflows/
│   │   ├── update.yaml  # Automated updates (every 6 hours)
│   │   └── check.yaml   # CI validation
│   └── actions/
│       └── setup-nix/   # Reusable Nix setup action
├── README.md          # User documentation
├── CLAUDE.md          # This file
└── LICENSE            # MIT licence
```

## Key Files

### sources.json

Contains the current version and platform-specific download URLs with SRI hashes:

```json
{
  "version": "1.10.1",
  "platforms": {
    "x86_64-linux": { "url": "...", "hash": "sha256-..." },
    "x86_64-darwin": { "url": "...", "hash": "sha256-..." },
    "aarch64-darwin": { "url": "...", "hash": "sha256-..." }
  }
}
```

### package.nix

Defines how the Kanata binary is fetched and installed:

- Downloads zip from GitHub releases
- Extracts the appropriate binary for the platform
- Uses `cmd_allowed` variant on macOS (required for Input Monitoring permission)
- Platform-specific binary names:
  - `x86_64-linux`: `kanata`
  - `x86_64-darwin`: `kanata_macos_cmd_allowed`
  - `aarch64-darwin`: `kanata_macos_cmd_allowed_arm64`

### update.ts

TypeScript script that:

1. Fetches latest release from GitHub API
2. Downloads `sha256sums` file from the release
3. Converts hex hashes to SRI format using `nix hash convert`
4. Updates `sources.json`

Run with: `bun ./update.ts`

## Common Tasks

### Building

```bash
nix build
./result/bin/kanata --version
```

### Updating to Latest Version

```bash
bun ./update.ts
nix build  # Verify it builds
```

### Formatting

```bash
cd dev && nix fmt
```

### Running Checks

```bash
cd dev && nix flake check -L
```

## Supported Platforms

- `x86_64-linux`
- `x86_64-darwin` (Intel Mac)
- `aarch64-darwin` (Apple Silicon)

Note: `aarch64-linux` is not included because Kanata does not provide official binaries for that platform.

## GitHub Actions

- **update.yaml**: Runs daily to check for new Kanata releases
- **check.yaml**: Runs on PRs and pushes to validate formatting and build

## Notes for Development

- The main flake has minimal dependencies (only nixpkgs) to keep consumer lock files clean
- Development tools are in `dev/flake.nix` to avoid polluting the main flake
- On macOS, Kanata requires the Karabiner-DriverKit VirtualHIDDevice driver
- The `cmd_allowed` binary variant is used on macOS to support command key remapping

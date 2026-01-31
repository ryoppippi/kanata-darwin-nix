{
  description = "Kanata keyboard remapper binaries and nix-darwin module for macOS and Linux.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      linuxSystems = [
        "x86_64-linux"
      ];
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      allSystems = linuxSystems ++ darwinSystems;
      forAllSystems = nixpkgs.lib.genAttrs allSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          isDarwin = builtins.elem system darwinSystems;
        in
        {
          kanata = pkgs.callPackage ./packages/kanata/package.nix { };
          default = self.packages.${system}.kanata;
        }
        // nixpkgs.lib.optionalAttrs isDarwin {
          kanata-vk-agent = pkgs.callPackage ./packages/kanata-vk-agent/package.nix { };
          karabiner-driverkit = pkgs.callPackage ./packages/karabiner-driverkit/package.nix { };
        }
      );

      overlays.default =
        _final: prev:
        {
          inherit (self.packages.${prev.system}) kanata;
        }
        // nixpkgs.lib.optionalAttrs (builtins.elem prev.system darwinSystems) {
          inherit (self.packages.${prev.system}) kanata-vk-agent;
          inherit (self.packages.${prev.system}) karabiner-driverkit;
        };

      darwinModules = {
        default = self.darwinModules.kanata;
        kanata = ./modules/darwin;
      };
    };
}

{
  description = "Kanata keyboard remapper packages and nix-darwin module for macOS.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forDarwinSystems = nixpkgs.lib.genAttrs darwinSystems;
    in
    {
      packages = forDarwinSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          kanata = pkgs.callPackage ./packages/kanata/package.nix { };
          kanata-vk-agent = pkgs.callPackage ./packages/kanata-vk-agent/package.nix { };
          karabiner-driverkit = pkgs.callPackage ./packages/karabiner-driverkit/package.nix { };
          default = self.packages.${system}.kanata;
        }
      );

      overlays.default = _final: prev: {
        inherit (self.packages.${prev.system}) kanata;
        inherit (self.packages.${prev.system}) kanata-vk-agent;
        inherit (self.packages.${prev.system}) karabiner-driverkit;
      };

      darwinModules = {
        default = self.darwinModules.kanata;
        kanata = ./modules/darwin;
      };

      lib = {
        checkKanataConfig =
          {
            pkgs,
            configFile,
            name ? "kanata-config",
            kanataPackage ? self.packages.${pkgs.system}.kanata,
          }:
          pkgs.runCommand name
            {
              nativeBuildInputs = [ kanataPackage ];
            }
            ''
              kanata --check --cfg ${configFile}
              touch $out
            '';
      };

      checks = forDarwinSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          kanata-config-basic = self.lib.checkKanataConfig {
            inherit pkgs;
            configFile = ./tests/basic.kbd;
            name = "kanata-config-basic";
          };
        }
      );
    };
}

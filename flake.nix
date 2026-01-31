{
  description = "Kanata keyboard remapper binaries for macOS and Linux.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          kanata = pkgs.callPackage ./default.nix { };
          default = self.packages.${system}.kanata;
        }
      );

      overlays.default = _final: prev: {
        kanata = self.packages.${prev.system}.default;
      };
    };
}

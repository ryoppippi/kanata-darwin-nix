{
  description = "Development environment for kanata-overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
              typos.enable = true;
            };
            settings.formatter.oxfmt = {
              command = "${pkgs.oxfmt}/bin/oxfmt";
              includes = [
                "*.json"
                "*.yaml"
                "*.yml"
                "*.md"
                "*.ts"
                "*.js"
              ];
            };
          };

          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./..;
            hooks = {
              treefmt = {
                enable = true;
                package = treefmtEval.config.build.wrapper;
              };
            };
          };
        in
        {
          formatter = treefmtEval.config.build.wrapper;

          devShells.default = pkgs.mkShellNoCC {
            packages = [
              treefmtEval.config.build.wrapper
              pkgs.typos
              pkgs.typos-lsp
            ];

            shellHook = ''
              ${pre-commit-check.shellHook}
            '';
          };
        };
    };
}

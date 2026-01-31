{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kanata;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.programs.kanata = {
    enable = mkEnableOption "kanata keyboard remapper (home-manager integration)";

    package = mkOption {
      type = types.package;
      default = pkgs.kanata;
      description = "The kanata package to use";
    };

    vkAgentPackage = mkOption {
      type = types.package;
      default = pkgs.kanata-vk-agent;
      description = "The kanata-vk-agent package to use";
    };

    enableVkAgent = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to create a symlink for kanata-vk-agent in ~/Applications";
    };
  };

  config = mkIf cfg.enable {
    home.file."Applications/Home Manager Apps/kanata".source = "${cfg.package}/bin/kanata";

    home.file."Applications/Home Manager Apps/kanata-vk-agent" = mkIf cfg.enableVkAgent {
      source = "${cfg.vkAgentPackage}/bin/kanata-vk-agent";
    };
  };
}

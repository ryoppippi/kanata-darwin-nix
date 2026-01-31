{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.kanata;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    mapAttrs'
    nameValuePair
    optionalString
    concatStringsSep
    attrValues
    ;

  keyboardModule = types.submodule {
    options = {
      configFile = mkOption {
        type = types.path;
        description = "Path to the kanata configuration file (.kbd)";
      };

      port = mkOption {
        type = types.port;
        description = "TCP port for kanata to listen on";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments to pass to kanata";
      };

      vkAgent = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable kanata-vk-agent for this keyboard";
        };

        blacklist = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "com.hnc.Discord"
            "com.openai.chat"
          ];
          description = "List of bundle IDs to blacklist from virtual key agent";
        };

        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra arguments to pass to kanata-vk-agent";
        };
      };
    };
  };
in
{
  options.services.kanata = {
    enable = mkEnableOption "kanata keyboard remapper";

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

    karabinerDriverKitPackage = mkOption {
      type = types.package;
      default = pkgs.karabiner-driverkit;
      description = "The Karabiner-DriverKit-VirtualHIDDevice package to use";
    };

    keyboards = mkOption {
      type = types.attrsOf keyboardModule;
      default = { };
      description = "Keyboard configurations";
      example = {
        macbook = {
          configFile = ./macbook.kbd;
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
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      # Install Karabiner-DriverKit-VirtualHIDDevice if not already installed
      if ! /usr/sbin/pkgutil --pkg-info org.pqrs.Karabiner-DriverKit-VirtualHIDDevice >/dev/null 2>&1; then
        echo "Installing Karabiner-DriverKit-VirtualHIDDevice..."
        /usr/sbin/installer -pkg ${cfg.karabinerDriverKitPackage} -target /
      fi

      # Activate the driver if not already active
      if [ -e "/Applications/.Karabiner-VirtualHIDDevice-Manager.app" ]; then
        echo "Activating Karabiner-VirtualHIDDevice driver..."
        /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate 2>/dev/null || true
      fi

      # Create symlinks in /Applications for permission management
      echo "Creating kanata symlink in /Applications..."
      ln -sf ${cfg.package}/bin/kanata /Applications/kanata

      ${optionalString (lib.any (kb: kb.vkAgent.enable) (attrValues cfg.keyboards)) ''
        echo "Creating kanata-vk-agent symlink in /Applications..."
        ln -sf ${cfg.vkAgentPackage}/bin/kanata-vk-agent /Applications/kanata-vk-agent
      ''}

      # Bootstrap and restart kanata services
      echo "Starting kanata services..."

      ${concatStringsSep "\n" (
        lib.mapAttrsToList (name: kb: ''
          /bin/launchctl bootstrap system /Library/LaunchDaemons/com.github.jtroo.kanata.${name}.plist 2>/dev/null || true
          ${optionalString kb.vkAgent.enable ''
            /bin/launchctl bootstrap gui/$(id -u) /Library/LaunchAgents/com.devsunb.kanata-vk-agent.${name}.plist 2>/dev/null || true
          ''}
        '') cfg.keyboards
      )}

      sleep 1

      ${concatStringsSep "\n" (
        lib.mapAttrsToList (name: _kb: ''
          /bin/launchctl kickstart -k system/com.github.jtroo.kanata.${name} 2>/dev/null || true
        '') cfg.keyboards
      )}

      ${concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: kb:
          optionalString kb.vkAgent.enable ''
            /bin/launchctl kickstart -k gui/$(id -u)/com.devsunb.kanata-vk-agent.${name} 2>/dev/null || true
          ''
        ) cfg.keyboards
      )}
    '';

    launchd.daemons = mapAttrs' (
      name: kb:
      nameValuePair "kanata-${name}" {
        serviceConfig = {
          Label = "com.github.jtroo.kanata.${name}";
          ProgramArguments = [
            "/Applications/kanata"
            "--cfg"
            (toString kb.configFile)
            "--port"
            (toString kb.port)
          ]
          ++ kb.extraArgs;
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/var/log/kanata-${name}.out.log";
          StandardErrorPath = "/var/log/kanata-${name}.err.log";
        };
      }
    ) cfg.keyboards;

    launchd.agents = lib.filterAttrs (_: v: v != null) (
      mapAttrs' (
        name: kb:
        nameValuePair "kanata-vk-agent-${name}" (
          if kb.vkAgent.enable then
            {
              serviceConfig = {
                Label = "com.devsunb.kanata-vk-agent.${name}";
                ProgramArguments = [
                  "/Applications/kanata-vk-agent"
                  "-p"
                  (toString kb.port)
                ]
                ++ (
                  if kb.vkAgent.blacklist != [ ] then
                    [
                      "-b"
                      (concatStringsSep "," kb.vkAgent.blacklist)
                    ]
                  else
                    [ ]
                )
                ++ kb.vkAgent.extraArgs;
                RunAtLoad = true;
                KeepAlive = true;
                StandardOutPath = "/tmp/kanata-vk-agent-${name}.out.log";
                StandardErrorPath = "/tmp/kanata-vk-agent-${name}.err.log";
              };
            }
          else
            null
        )
      ) cfg.keyboards
    );
  };
}

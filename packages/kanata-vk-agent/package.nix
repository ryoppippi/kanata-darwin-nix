{
  lib,
  stdenv,
  fetchzip,
}:
let
  platforms = import ../../platforms.nix;
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;
  sources = sourcesData.platforms;

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kanata-vk-agent";
  inherit version;

  src = fetchzip {
    inherit (source) url hash;
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src/kanata-vk-agent $out/bin/kanata-vk-agent
    runHook postInstall
  '';

  meta = with lib; {
    inherit version;
    description = "Virtual key agent for Kanata to enable app-specific key mappings on macOS";
    homepage = "https://github.com/devsunb/kanata-vk-agent";
    license = licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "kanata-vk-agent";
    inherit platforms;
    maintainers = with maintainers; [ ryoppippi ];
  };
}

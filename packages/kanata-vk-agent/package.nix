{
  lib,
  stdenv,
  fetchurl,
  gnutar,
}:
let
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

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ gnutar ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp kanata-vk-agent $out/bin/
    chmod +x $out/bin/kanata-vk-agent
    runHook postInstall
  '';

  meta = with lib; {
    inherit version;
    description = "Virtual key agent for Kanata to enable app-specific key mappings on macOS";
    homepage = "https://github.com/devsunb/kanata-vk-agent";
    license = licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "kanata-vk-agent";
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with maintainers; [ ryoppippi ];
  };
}

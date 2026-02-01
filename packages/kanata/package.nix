{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:
let
  platforms = import ../../platforms.nix;
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;
  sources = sourcesData.platforms;

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  binaryName =
    {
      "x86_64-darwin" = "kanata_macos_cmd_allowed";
      "aarch64-darwin" = "kanata_macos_cmd_allowed_arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "kanata";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack
    unzip $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${binaryName} $out/bin/kanata

    runHook postInstall
  '';

  dontStrip = true;

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/kanata --version

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = ./update.ts;
  };

  meta = with lib; {
    inherit version;
    description = "Improve keyboard comfort and usability with advanced customization";
    homepage = "https://github.com/jtroo/kanata";
    downloadPage = "https://github.com/jtroo/kanata/releases";
    changelog = "https://github.com/jtroo/kanata/releases/tag/v${version}";
    license = licenses.lgpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "kanata";
    inherit platforms;
    maintainers = with maintainers; [ ryoppippi ];
  };
}

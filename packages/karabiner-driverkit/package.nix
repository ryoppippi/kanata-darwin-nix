{
  lib,
  fetchurl,
}:
let
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version url hash;
in
fetchurl {
  inherit url hash;
  name = "Karabiner-DriverKit-VirtualHIDDevice-${version}.pkg";

  meta = with lib; {
    inherit version;
    description = "Karabiner-DriverKit-VirtualHIDDevice for macOS";
    homepage = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice";
    license = licenses.publicDomain;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = [ ];
  };
}

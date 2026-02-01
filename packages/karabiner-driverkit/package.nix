{
  lib,
  fetchurl,
}:
let
  platforms = import ../../platforms.nix;
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
    inherit platforms;
    maintainers = with maintainers; [ ryoppippi ];
  };
}

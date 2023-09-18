{ stdenv
, fetchFromGitHub
, wrapQtAppsHook
, cmake
, qtbase
, qtwebengine
, pipewire
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "discord-screenaudio";
  version = "1.8.2";

  src = fetchFromGitHub {
    owner = "maltejur";
    repo = "discord-screenaudio";
    rev = "761b40de5b77083388a235c42358adc84aa73bc7";
    hash = "sha256-59Lax4Mdrpxl7p5162rXIP+mFNmvnktxXKleqC8OGA8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
    qtbase
    qtwebengine
    pkg-config
  ];

  buildInputs = [
    pipewire
  ];

  preConfigure = ''
    # version.cmake either uses git tags or a version.txt file to get app version.
    # Since cmake can't access git tags, write the version to a version.txt ourselves.
    echo "${version}" > version.txt
  '';
}

{
  stdenv,
  cmake,
  extra-cmake-modules,
  kpipewire,
  qtx11extras,
  ki18n,
  kwidgetsaddons,
  knotifications,
  kcoreaddons,
  fetchpatch,
  fetchFromGitLab,
  pkg-config,
  wrapQtAppsHook,
  pipewire,
  xdg-desktop-portal
}:

stdenv.mkDerivation {
  name = "xwaylandvideobridge";
  version = "unstable";

  patches = [
    (fetchpatch {
      # fix on sway (and hyprland)
      url = "https://aur.archlinux.org/cgit/aur.git/plain/cursor-mode.patch?h=xwaylandvideobridge-cursor-mode-2-git";
      hash = "sha256-649kCs3Fsz8VCgGpZ952Zgl8txAcTgakLoMusaJQYa4=";
    })
  ];

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "system";
    repo = "xwaylandvideobridge";
    rev = "9b27c3fc67bcdd2b26332965130085fb37606824";
    hash = "sha256-GbCKwfG0RYtFraBFCsX7xDz71kr1lDRasuP2zVnMrWc=";
  };

  nativeBuildInputs = [
    wrapQtAppsHook
    pkg-config
    cmake
    extra-cmake-modules
    kpipewire
    qtx11extras
    ki18n
    kwidgetsaddons
    knotifications
    kcoreaddons
  ];

  buildInputs = [
    pipewire
    xdg-desktop-portal
  ];
}

{ lib
, rustPlatform
, fetchFromGitHub
, makeWrapper
, pkg-config
, installShellFiles
, openssl
, stdenv
, udev
, libva
, mesa
, libnotify
, xorg
, cups
, pciutils
, libcanberra-gtk3
, extraLibs ? [ ]
, nixosTests
}:

rustPlatform.buildRustPackage rec {
  pname = "firefoxpwa";
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "filips123";
    repo = "PWAsForFirefox";
    rev = "v${version}";
    hash = "sha256-Uhr848H+7a9Qy3XJPKi0mPOU2RZtJSjpCCPJtSJ+6Ys=";
  };

  sourceRoot = "${src.name}/native";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "data-url-0.3.0" = "sha256-ZJBRkd4s47ywYnGbzxsQyr0JRgjAXZryVthszKJreTU=";
      "mime-0.4.0-a.0" = "sha256-LjM7LH6rL3moCKxVsA+RUL9lfnvY31IrqHa9pDIAZNE=";
      "web_app_manifest-0.0.0" = "sha256-G+kRN8AEmAY1TxykhLmgoX8TG8y2lrv7SCRJlNy0QzA=";
    };
  };

  preConfigure = ''
    sed -i 's;version = "0.0.0";version = "${version}";' Cargo.toml
    sed -zi 's;name = "firefoxpwa"\nversion = "0.0.0";name = "firefoxpwa"\nversion = "${version}";' Cargo.lock
    sed -i $'s;DISTRIBUTION_VERSION = \'0.0.0\';DISTRIBUTION_VERSION = \'${version}\';' userchrome/profile/chrome/pwa/chrome.jsm
  '';

  nativeBuildInputs = [ makeWrapper pkg-config installShellFiles ];
  buildInputs = [ openssl ];

  FFPWA_EXECUTABLES = ""; # .desktop entries generated without any store path references
  FFPWA_SYSDATA = "${placeholder "out"}/share/firefoxpwa";
  completions = "target/${stdenv.targetPlatform.config}/release/completions";

  gtk_modules = map (x: x + x.gtkModule) [ libcanberra-gtk3 ];
  libs = let libs = lib.optionals stdenv.isLinux [ udev libva mesa libnotify xorg.libXScrnSaver cups pciutils ] ++ gtk_modules ++ extraLibs; in lib.makeLibraryPath libs + ":" + lib.makeSearchPathOutput "lib" "lib64" libs;

  postInstall = ''
    # Manifest
    sed -i "s!/usr/libexec!$out/bin!" manifests/linux.json
    install -Dm644 manifests/linux.json $out/lib/mozilla/native-messaging-hosts/firefoxpwa.json

    installShellCompletion --cmd firefoxpwa \
      --bash $completions/firefoxpwa.bash \
      --fish $completions/firefoxpwa.fish \
      --zsh $completions/_firefoxpwa

    # UserChrome
    mkdir -p $out/share/firefoxpwa/userchrome/
    cp -r userchrome/* "$out/share/firefoxpwa/userchrome"

    wrapProgram $out/bin/firefoxpwa \
      --prefix LD_LIBRARY_PATH ':' "$libs" \
      --suffix-each GTK_PATH ':' "$gtk_modules"
  '';

  passthru.tests.firefoxpwa = nixosTests.firefoxpwa;

  meta = with lib; {
    description = "A tool to install, manage and use Progressive Web Apps (PWAs) in Mozilla Firefox";
    homepage = "https://github.com/filips123/PWAsForFirefox";
    license = licenses.mpl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ camillemndn ];
  };
}

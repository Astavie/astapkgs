{ pkgs, ... }:

{
  odin = pkgs.llvmPackages_13.stdenv.mkDerivation rec {
    pname = "odin";
    version = "dev-2023-05";

    src = pkgs.fetchFromGitHub {
      owner = "odin-lang";
      repo = "Odin";
      rev = version;
      sha256 = "sha256-qEewo2h4dpivJ7D4RxxBZbtrsiMJ7AgqJcucmanbgxY=";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper which
    ];

    LLVM_CONFIG = "${pkgs.llvmPackages_13.llvm.dev}/bin/llvm-config";

    postPatch = ''
      sed -i build_odin.sh \
        -e 's/^GIT_SHA=.*$/GIT_SHA=/' \
        -e 's/LLVM-C/LLVM/' \
        -e 's/framework System/lSystem/'
      patchShebangs build_odin.sh
    '';

    dontConfigure = true;

    buildFlags = [
      "release"
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp odin $out/bin/odin

      mkdir -p $out/share
      cp -r core $out/share/core
      cp -r vendor $out/share/vendor

      wrapProgram $out/bin/odin \
        --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs.llvmPackages_13; [
          bintools
          llvm
          clang
          lld
        ])} \
        --set-default ODIN_ROOT $out/share
    '';
  };
  ols = pkgs.stdenv.mkDerivation {
    pname = "ols";
    version = "20230421";

    src = pkgs.fetchFromGitHub {
      owner = "DanielGavin";
      repo = "ols";
      rev = "fd136199897d5e5c87f6f1fbfd076ed18e41d7b7";
      sha256 = "sha256-lRoDSc2bZSuXTam3Q5OOlSD6YAobCFKNRbtQ41Qx5EY=";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];

    buildInputs = with pkgs; [
      odin
    ];

    postPatch = ''
      patchShebangs build.sh
    '';

    buildPhase = ''
      ./build.sh
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp ols $out/bin
      wrapProgram $out/bin/ols --set-default ODIN_ROOT ${pkgs.odin}/share
    '';
  };
}

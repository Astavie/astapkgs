{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;

  inputs.fenix.url = github:nix-community/fenix;
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [ self.overlays.default ];
    };
    toolchain = system: fenix.packages.${system}.minimal.toolchain;
  in {
    overlays.default = final: prev: {
      # ---- ODIN ----
      odin = final.llvmPackages_13.stdenv.mkDerivation rec {
        pname = "odin";
        version = "dev-2023-05";

        src = final.fetchFromGitHub {
          owner = "odin-lang";
          repo = "Odin";
          rev = version;
          sha256 = "sha256-qEewo2h4dpivJ7D4RxxBZbtrsiMJ7AgqJcucmanbgxY=";
        };

        nativeBuildInputs = with final; [
          makeWrapper which
        ];

        LLVM_CONFIG = "${final.llvmPackages_13.llvm.dev}/bin/llvm-config";

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
            --prefix PATH : ${final.lib.makeBinPath (with final.llvmPackages_13; [
              bintools
              llvm
              clang
              lld
            ])} \
            --set-default ODIN_ROOT $out/share
        '';
      };
      ols = final.stdenv.mkDerivation {
        pname = "ols";
        version = "20230421";

        src = final.fetchFromGitHub {
          owner = "DanielGavin";
          repo = "ols";
          rev = "fd136199897d5e5c87f6f1fbfd076ed18e41d7b7";
          sha256 = "sha256-lRoDSc2bZSuXTam3Q5OOlSD6YAobCFKNRbtQ41Qx5EY=";
        };

        nativeBuildInputs = with final; [
          makeWrapper
        ];

        buildInputs = with final; [
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
          wrapProgram $out/bin/ols --set-default ODIN_ROOT ${final.odin}/share
        '';
      };

      # ---- STARDUST ----
      wivrn-server = final.stdenv.mkDerivation rec {
        pname = "wivrn-server";
        version = "v0.4";

        src = final.fetchFromGitHub {
          owner = "Meumeu";
          repo = "WiVRn";
          rev = version;
          sha256 = "sha256-ZszjBF6xtReNOUxKdbCoZTnzP6sWO7YmUricVjJEcCY=";
        };

        nativeBuildInputs = with final; [
          cmake pkg-config
        ];

        buildInputs = with final; [
          vulkan-headers vulkan-loader systemd ffmpeg eigen avahi pulseaudio glslang freetype ninja nlohmann_json python3 openxr-loader libGL xorg.libXrandr libdrm libva

          # nvidia
          cudaPackages.cudatoolkit
          (linuxPackages.nvidia_x11.override { libsOnly = true; })
        ];

        cmakeFlags = [
          "-GNinja"
          "-DWIVRN_BUILD_CLIENT=OFF"
          "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
          "-DGIT_DESC=${version}"
          "-DFETCHCONTENT_SOURCE_DIR_BOOSTPFR=${final.fetchFromGitHub {
            owner = "boostorg";
            repo = "pfr";
            rev = "2.0.3";
            sha256 = "sha256-vtmRzcCPwNFsV92PuqIuMnV3z4aHevOImcvvubURrqQ=";
          }}"
          "-DFETCHCONTENT_SOURCE_DIR_MONADO=${final.fetchgit {
            url = "https://gitlab.freedesktop.org/monado/monado";
            rev = "3046a5eee4105c4d1c07bc466d6e3a0bb749df42";
            sha256 = "sha256-nm56IiNr/LYxhkG1bBhNdbL4jIbO+BN30dIjF1N2DJE=";
          }}"
        ];

        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/share
          cp server/wivrn-server $out/bin
          cp _deps/monado-build/src/xrt/targets/openxr/libopenxr_wivrn.so $out/share
        '';
      };

      wivrn-runtime = final.writeTextFile {
          name = "openxr_wivrn-dev.json";
          text = ''
            {
                "file_format_version": "1.0.0",
                "runtime": {
                    "library_path": "${final.wivrn-server}/share/libopenxr_wivrn.so"
                }
            }
          '';
      };

      wivrn-client-install = final.writeShellScriptBin "wivrn-client-install" ''
        client_file='${final.fetchurl {
          url = "https://github.com/Meumeu/WiVRn/releases/download/${final.wivrn-server.version}/WiVRn-oculus-release.apk";
          sha256 = "sha256-LWcTKcSbT0QdCHxxwlFH6ZODNt2kxqgoA+Scg5B5HkE=";
        }}'

        echo "Put on your Quest and authorize this machine to install the WiVRn client!"
        read -p '(press enter when done)'

        echo 'Installing client...'
        ${final.android-tools}/bin/adb install -r "$client_file"
      '';
    };
    packages."x86_64-linux" = {
      inherit (pkgs) odin ols marksman wivrn-server wivrn-client-install;
    };
  };
}

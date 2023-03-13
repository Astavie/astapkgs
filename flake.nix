{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;

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
      odin = prev.odin.overrideAttrs (self: prev: rec {
        version = "dev-2023-03";
        src = final.fetchFromGitHub {
          owner = "odin-lang";
          repo = "Odin";
          rev = version;
          sha256 = "sha256-SIU1VZgac0bL6byai2vMvgl3nrWZaU9Hn0wRqazzxn4=";
        };
        LLVM_CONFIG = "${final.llvm.dev}/bin/llvm-config";
        postPatch = ''
          sed -i 's/^GIT_SHA=.*$/GIT_SHA=/' build_odin.sh
          sed -i 's/^have_which$//' build_odin.sh
          patchShebangs build_odin.sh
        '';
      });
      ols = final.stdenv.mkDerivation {
        pname = "ols";
        version = "20230313";

        src = final.fetchFromGitHub {
          owner = "DanielGavin";
          repo = "ols";
          rev = "cba92b209574d68a054c5108672535162017ffba";
          sha256 = "sha256-VDvtNSG7OV4OXCVmtYTGpRmlynPC0KLMB88rLoZhoBk=";
        };

        buildInputs = [ final.odin ];

        postPatch = ''
          patchShebangs build.sh
        '';

        buildPhase = ''
          ./build.sh
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp ols $out/bin
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
          sha256 = "sha256-rhlxVI2hv66USF52C0VNG6QtJTaK893VRJZOyaxoQAM=";
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

      stardust-xr-server = (final.makeRustPlatform {
        cargo = toolchain final.system;
        rustc = toolchain final.system;
      }).buildRustPackage rec {
        pname = "stardust-xr-server";
        version = "20230313";

        src = final.fetchFromGitHub {
          owner = "StardustXR";
          repo = "server";
          rev = "643c4959fb3810e52c381ff633f14a848624151f";
          sha256 = "sha256-E5QH7bUdN8zscRYUsDbX3qKbxhhoBbIfrG4fF+a3WO8=";
        };

        cargoSha256 = "sha256-u9Nygffa6/vKI+GIQVyWo/GpxVTOg/xI7rLY388KatU=";

        postPatch = ''
          sk=/build/stardust-xr-server-${version}-vendor.tar.gz/stereokit-sys/StereoKit
          mkdir -p $sk/build/cpm
          cp ${final.fetchurl {
            url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.32.2/CPM.cmake";
            hash = "sha256-yDHlpqmpAE8CWiwJRoWyaqbuBAg0090G8WJIC2KLHp8=";
          }} $sk/build/cpm/CPM_0.32.2.cmake
        '';

        CPM_SOURCE_CACHE = "./build";

        nativeBuildInputs = with final; [
          cmake pkg-config llvmPackages.libcxxClang
        ];

        buildInputs = with final; [
          openxr-loader libGL mesa xorg.libX11 fontconfig libxkbcommon
        ];

        LIBCLANG_PATH = "${final.libclang.lib}/lib";
      };

      # ---- OTHER ----
      marksman = final.buildDotnetModule rec {
        pname = "marksman";
        baseName = pname;
        version = "2022-12-28";
        VersionString = "c67a6fc";
        
        src = final.fetchFromGitHub {
          owner = "artempyanykh";
          repo = "marksman";
          rev = version;
          sha256 = "sha256-IOmAOO45sD0TkphbHWLCXXyouxKNJoiNYHXV/bw0xH4=";
        };
        
        projectFile = "Marksman/Marksman.fsproj";
        nugetDeps = ./marksman-deps-oIV8Eh.nix;
      };
    };
    packages."x86_64-linux" = {
      inherit (pkgs) odin ols marksman wivrn-server wivrn-client-install stardust-xr-server;
    };
  };
}

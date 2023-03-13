{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
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

        buildInputs = with final; [
          cmake pkg-config vulkan-headers vulkan-loader systemd ffmpeg eigen x264 avahi pulseaudio glslang shaderc freetype ninja nlohmann_json python3 openxr-loader libGL xorg.libXrandr libdrm libva
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
          mkdir -p $out/lib
          cp server/wivrn-server $out/bin
          cp openxr_wivrn-dev.json $out/lib
        '';
      };

      wivrn-install = final.writeShellScriptBin "wivrn-install" ''
        client_file='${final.fetchurl {
          url = "https://github.com/Meumeu/WiVRn/releases/download/${final.wivrn-server.version}/WiVRn-oculus-release.apk";
          sha256 = "sha256-LWcTKcSbT0QdCHxxwlFH6ZODNt2kxqgoA+Scg5B5HkE=";
        }}'

        echo "Setting WiVRn as the default OpenXR runtime..."
        mkdir -p ~/.config/openxr/1/
        ln --symbolic --force ${final.wivrn-server}/lib/openxr_wivrn-dev.json ~/.config/openxr/1/active_runtime.json

        echo "Put on your Quest and authorize this machine to install the WiVRn client!"
        read -p '(press enter when done)'

        echo 'Installing client...'
        ${final.android-tools}/bin/adb install -r "$client_file"
      '';

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
    packages.x86_64-linux = {
      inherit (pkgs) odin ols marksman wivrn-server wivrn-install;
    };
  };
}

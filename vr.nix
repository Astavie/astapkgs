{ pkgs, ... }:

rec {
  wivrn-server = pkgs.stdenv.mkDerivation rec {
    pname = "wivrn-server";
    version = "v0.5";

    src = pkgs.fetchFromGitHub {
      owner = "Meumeu";
      repo = "WiVRn";
      rev = version;
      sha256 = "sha256-oi3DSn80kdhXKTa+q9vrreDuTYhm40+oZY03npy2Eac=";
    };

    nativeBuildInputs = with pkgs; [
      cmake pkg-config
    ];

    buildInputs = with pkgs; [
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
      "-DFETCHCONTENT_SOURCE_DIR_BOOSTPFR=${pkgs.fetchFromGitHub {
        owner = "boostorg";
        repo = "pfr";
        rev = "2.0.3";
        sha256 = "sha256-vtmRzcCPwNFsV92PuqIuMnV3z4aHevOImcvvubURrqQ=";
      }}"
      "-DFETCHCONTENT_SOURCE_DIR_MONADO=${pkgs.fetchgit {
        url = "https://gitlab.freedesktop.org/monado/monado";
        rev = "e9475b13137db2cca8571576b5381a70fb8180a5";
        sha256 = "sha256-9EgXrxgbFtln+gQU/DI1yceJWSEC16aZyt2jGzFdvDM=";
      }}"
    ];

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share
      cp server/wivrn-server $out/bin
      cp _deps/monado-build/src/xrt/targets/openxr/libopenxr_wivrn.so $out/share
    '';
  };

  wivrn-runtime = pkgs.writeTextFile {
      name = "openxr_wivrn-dev.json";
      text = ''
        {
            "file_format_version": "1.0.0",
            "runtime": {
                "library_path": "${wivrn-server}/share/libopenxr_wivrn.so"
            }
        }
      '';
  };

  wivrn-client-install = pkgs.writeShellScriptBin "wivrn-client-install" ''
    client_file='${pkgs.fetchurl {
      url = "https://github.com/Meumeu/WiVRn/releases/download/${wivrn-server.version}/WiVRn-oculus-release.apk";
      sha256 = "sha256-LWcTKcSbT0QdCHxxwlFH6ZODNt2kxqgoA+Scg5B5HkE=";
    }}'

    echo "Put on your Quest and authorize this machine to install the WiVRn client!"
    read -p '(press enter when done)'

    echo 'Installing client...'
    ${pkgs.android-tools}/bin/adb install -r "$client_file"
  '';

  alvr-client-install = pkgs.writeShellScriptBin "alvr-client-install" ''
    client_file='${pkgs.fetchurl {
      url = "https://github.com/alvr-org/ALVR/releases/download/v20.6.1/alvr_client_android.apk";
      sha256 = "sha256-aHFnVs45H1eVd91vdWKzKoPoz+gqnkcX79ftvzrVn7s=";
    }}'

    echo "Put on your Quest and authorize this machine to install the ALVR client!"
    read -p '(press enter when done)'

    echo 'Installing client...'
    ${pkgs.android-tools}/bin/adb install -r "$client_file"
  '';

  alvr = pkgs.writeShellScriptBin "alvr" ''
    server_file='${pkgs.fetchurl {
      url = "https://github.com/alvr-org/ALVR/releases/download/v20.6.1/ALVR-x86_64.AppImage";
      sha256 = "sha256-IYw3D18xUGWiFu74c4d8d4tohZztAD6mmZCYsDNxR+A=";
    }}'
    ${pkgs.appimage-run}/bin/appimage-run "$server_file"
  '';
}

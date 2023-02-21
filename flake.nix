{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
  in {
    overlays.default = final: prev: {
      odin = prev.odin.overrideAttrs (self: prev: rec {
        version = "dev-2023-02";
        src = final.fetchFromGitHub {
          owner = "odin-lang";
          repo = "Odin";
          rev = version;
          sha256 = "sha256-E+XVyYbBGPG+Z2P08Vr/pS7Ry0ay0Z3tbDqLoOcPg4k=";
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
        version = "20230221";

        src = final.fetchFromGitHub {
          owner = "DanielGavin";
          repo = "ols";
          rev = "532f4bf07c5830276dc4fef9ec497bf917adc8d5";
          sha256 = "sha256-iF6t0MKgVrfqE0E24+OBz3BIAH3JZLpGFeXaf4F2jGU=";
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
      inherit (pkgs) odin ols marksman;
    };
  };
}

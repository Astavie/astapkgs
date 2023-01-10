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
        version = "dev-2022-10";
        src = final.fetchFromGitHub {
          owner = "odin-lang";
          repo = "Odin";
          rev = version;
          sha256 = "sha256-D6dhsIU2Hm1XQ4G44C0ukJEgiO4tTmZ7CIezWi9CdOY=";
        };
        LLVM_CONFIG = "${final.llvm.dev}/bin/llvm-config";
        postPatch = ''
          sed -i 's/^GIT_SHA=.*$/GIT_SHA=/' build_odin.sh
          patchShebangs build_odin.sh
        '';
      });
      ols = final.stdenv.mkDerivation {
        pname = "ols";
        version = "20221027";

        src = final.fetchFromGitHub {
          owner = "DanielGavin";
          repo = "ols";
          rev = "ab9c17b403527bc07d65d5c47ecb25bec423ddac";
          sha256 = "sha256-a6ii6r+zYfO8AJzrL4TWr6Qtze27CZV9MMrA+N8oX+M=";
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

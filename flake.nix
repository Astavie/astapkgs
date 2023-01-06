{
  inputs.nixpkgs.url = github:nixpkgs/nixos-22.11;

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in rec {
      odin = pkgs.odin.overrideAttrs (self: prev: rec {
        version = "dev-2022-10";
        src = pkgs.fetchFromGitHub {
          owner = "odin-lang";
          repo = "Odin";
          rev = version;
          sha256 = "sha256-D6dhsIU2Hm1XQ4G44C0ukJEgiO4tTmZ7CIezWi9CdOY=";
        };
        LLVM_CONFIG = "${pkgs.llvm.dev}/bin/llvm-config";
        postPatch = ''
          sed -i 's/^GIT_SHA=.*$/GIT_SHA=/' build_odin.sh
          patchShebangs build_odin.sh
        '';
      });
      ols = pkgs.stdenv.mkDerivation {
        pname = "ols";
        version = "20221027";

        src = pkgs.fetchFromGitHub {
          owner = "DanielGavin";
          repo = "ols";
          rev = "ab9c17b403527bc07d65d5c47ecb25bec423ddac";
          sha256 = "sha256-a6ii6r+zYfO8AJzrL4TWr6Qtze27CZV9MMrA+N8oX+M=";
        };

        buildInputs = [ odin ];

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
    };
  };
}

{ nixpkgs }:

{
  discocss = nixpkgs.discocss.overrideAttrs (old: {
    src = nixpkgs.fetchFromGitHub {
      owner = "bddvlpr";
      repo = "discocss";
      rev = "37f1520bc90822b35e60baa9036df7a05f43fab8";
      hash = "sha256-BFTxgUy2H/T92XikCsUMQ4arPbxf/7a7JPRewGqvqZQ=";
    };
  });
  xwaylandvideobridge = nixpkgs.libsForQt5.callPackage ./xwaylandvideobridge.nix { };
  discord-screenaudio = nixpkgs.qt6Packages.callPackage ./discord-screenaudio.nix { };
}

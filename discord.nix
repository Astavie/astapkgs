{ pkgs, ... }:

{
  discord-screenaudio = pkgs.qt6Packages.callPackage ./discord-screenaudio.nix { };
}

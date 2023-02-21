#!/bin/sh

echo "REVISIONS"
odin_version=`date +dev-%Y-%m`
echo "Odin: $odin_version"
ols_version=`date +%Y%m%d`
ols_rev=`git ls-remote https://github.com/DanielGavin/ols refs/tags/nightly | awk '{print $1}'`
echo "ols: $ols_rev"

echo -e "\nHASHES"
odin_hash=`nix run nixpkgs#nix-prefetch -- fetchFromGitHub --owner odin-lang --repo Odin --rev $odin_version 2>/dev/null | awk '{print $1}'`
echo "Odin: $odin_hash"
ols_hash=`nix run nixpkgs#nix-prefetch -- fetchFromGitHub --owner DanielGavin --repo ols --rev $ols_rev      2>/dev/null | awk '{print $1}'`
echo "ols: $ols_hash"

echo -e "\nUPDATING FLAKE"
sed -i ":a;N;\$!ba;s|version = [^;]*;|version = \"$odin_version\";|1" flake.nix
sed -i ":a;N;\$!ba;s|sha256 = [^;]*;|sha256 = \"$odin_hash\";|1" flake.nix

sed -i ":a;N;\$!ba;s|version = [^;]*;|version = \"$ols_version\";|2" flake.nix
sed -i ":a;N;\$!ba;s|rev = [^;]*;|rev = \"$ols_rev\";|2" flake.nix
sed -i ":a;N;\$!ba;s|sha256 = [^;]*;|sha256 = \"$ols_hash\";|2" flake.nix

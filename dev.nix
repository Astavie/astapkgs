{ pkgs, fenix }:

{
  dev = with pkgs; {
    odin = buildEnv {
      name = "odin-dev";
      paths = [
        odin
        ols
      ];
    };
    minecraft = buildEnv {
      name = "minecraft-dev";
      paths = [
        maven
        gradlew-hotswap
        java-language-server
        jetbrains.jdk
      ];
    };
    nodejs = buildEnv {
      name = "nodejs-dev";
      paths = [
        nodejs
        nodePackages.npm
        nodePackages.typescript-language-server
      ];
    };
    rust-nightly = buildEnv {
      name = "rust-dev";
      paths = [
        fenix.default.toolchain
        rust-analyzer
        bacon
      ];
    };
  };
}
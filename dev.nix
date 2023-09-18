{ nixpkgs, astapkgs, fenix }:

{
  dev = with nixpkgs; with astapkgs; {
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
        minecraft-language-server
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
        fenix.rust-analyzer
        bacon
        cargo-watch
      ];
    };
  };
}

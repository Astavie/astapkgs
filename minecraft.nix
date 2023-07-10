{ pkgs, ... }:

let
  hotswap-agent = with pkgs; maven.buildMavenPackage {
    pname = "hotswap-agent";
    version = "1.4.2-SNAPSHOT";

    src = fetchFromGitHub {
      owner = "HotswapProjects";
      repo = "HotswapAgent";
      rev = "783bdde4191a5e56ec59837cd8d13ed7ef43f842";
      sha256 = "sha256-pLIrUqjgsvC6fH/D2QZ/tb/Fla0RgRv1eThSTtLywX0=";
    };

    patches = [
      (pkgs.fetchpatch {
        # fix proxy crash
        url = "https://github.com/Astavie/HotswapAgent/commit/eeb0e95c863d5f975aebdd8146b46150df4d1902.patch";
        sha256 = "sha256-qVyngRJuxaOVgSrZzSNXAQF9VnRVDDFjif8nS/EUwaE=";
      })
    ];

    nativeBuildInputs = [ maven ];

    # use jetbrains jdk
    JAVA_HOME = "${jetbrains.jdk}";
    mvnFetchExtraArgs.JAVA_HOME = "${jetbrains.jdk}";

    dontConfigure = true;
    mvnFetchExtraArgs.dontConfigure = true;
    mvnParameters = "-DskipTests";
    mvnHash = "sha256-W5DtrSLki/fat6dwesoocODM6XvwqW8RZnFH5uQ5wIc=";

    installPhase = ''
      runHook preInstall

      mkdir $out
      cp hotswap-agent/target/hotswap-agent.jar $out/

      runHook postInstall
    '';
  };
in
{
  gradlew-hotswap = (pkgs.writeShellScriptBin "gradlew-hotswap" ''
    ./gradlew $@ -Dastavie.jvm="-XX:+AllowEnhancedClassRedefinition -javaagent:${hotswap-agent}/hotswap-agent.jar=autoHotswap=true,disablePlugin=Log4j2 --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED --add-opens=java.desktop/java.beans=ALL-UNNAMED"
  '');
  minecraft-language-server = with pkgs; (java-language-server.overrideAttrs (final: prev: {
    pname = "minecraft-language-server";

    patches = (prev.patches or []) ++ [
      (fetchpatch {
        # remove deprecated rangeLength
        url = "https://github.com/Astavie/java-language-server/commit/342b435decbc739b0d23da1bbe2e0cd376c9f299.patch";
        sha256 = "sha256-aK7HXwMQN4k64q2rXo2hcdaYFhhOIIQuJGy4tyAFYuc=";
      })
      (fetchpatch {
        # clamp lineLength to 0 or above
        url = "https://github.com/Astavie/java-language-server/commit/73c71f27aa0b9aa894432e43d195e444b8a616fd.patch";
        sha256 = "sha256-brFvRn+TkYmXQ3VfufeGkDDbHIxK1TMSh0TjlN/026Y=";
      })
      (fetchpatch {
        # continue response
        url = "https://github.com/Astavie/java-language-server/commit/409d28de5fa724ddd1f7bfa82a09d88dc89976bc.patch";
        sha256 = "sha256-x+yWWPtuTa4sJYFFPxKKJZNhSArF2rlQVWvZ3ZubIAE=";
      })
      (fetchpatch {
        # make debugger quiet
        url = "https://github.com/Astavie/java-language-server/commit/430a066b7d4100184e7073f713415374116b68b6.patch";
        sha256 = "sha256-v5nRVIUNTwHQ7mjTCmV+lVAVs5MhM3qRDVcKqr4KRgU=";
      })
      (fetchpatch {
        # gradle dependency support
        url = "https://github.com/Astavie/java-language-server/commit/63ce834a6d2637b9406591c1d4e9387b26ab8461.patch";
        sha256 = "sha256-bgQOWFIzt5R70dXr2Ecnlzc2K2nFe9c0ntiP3520Fyk=";
      })
    ];

    postInstall = (prev.postInstall or "") + ''
      makeWrapper $out/share/java/java-language-server/debug_adapter_linux.sh $out/bin/java-debug-adapter
    '';
  }));
}

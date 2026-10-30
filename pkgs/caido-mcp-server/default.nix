{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  targets = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-YlyqUKoYN5InsLSbQLFBMcnwvNYCGRj4wwhU1RGHsNU=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-a3m87VeJ5QLHsjlIDgfCBvLSiQFBGwG0BXTcGNcrsZE=";
    };
  };
  target = targets.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "caido-mcp-server";
  version = "4.4.0";
  src = fetchurl {
    url = "https://github.com/c0tton-fluff/caido-mcp-server/releases/download/v${finalAttrs.version}/caido-mcp-server-linux-${target.arch}";
    inherit (target) hash;
  };
  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/caido-mcp-server"
    runHook postInstall
  '';
  meta = {
    description = "MCP server for the Caido proxy";
    homepage = "https://github.com/c0tton-fluff/caido-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "caido-mcp-server";
    platforms = builtins.attrNames targets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

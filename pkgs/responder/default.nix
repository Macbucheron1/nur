{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:
python313Packages.buildPythonApplication rec {
  pname = "responder";
  version = "3.2.2.0";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "lgandx";
    repo = "Responder";
    rev = "fb29fe25db9135a9487c961783254b56a20f58ac";
    hash = "sha256-vzn+7w7RgAsCt1pOz53cvBE1F1U+NFE4c1MehwLoFeQ=";
  };

  nativeBuildInputs = [makeWrapper];

  dependencies = with python313Packages; [
    aioquic
    netifaces
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp -R . $out/share/Responder

    makeWrapper ${python313Packages.python.interpreter} $out/bin/responder \
      --add-flags "$out/share/Responder/Responder.py" \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --run "mkdir -p /tmp/Responder"

    # The source tree is read-only in the Nix store, so keep the runtime
    # state (logs and database) in a writable location.
    substituteInPlace $out/share/Responder/Responder.conf \
      --replace-fail "Responder-Session.log" "/tmp/Responder/Responder-Session.log" \
      --replace-fail "Poisoners-Session.log" "/tmp/Responder/Poisoners-Session.log" \
      --replace-fail "Analyzer-Session" "/tmp/Responder/Analyzer-Session" \
      --replace-fail "Config-Responder.log" "/tmp/Responder/Config-Responder.log" \
      --replace-fail "Responder.db" "/tmp/Responder/Responder.db"

    runHook postInstall
  '';

  meta = {
    description = "LLMNR, NBT-NS and MDNS poisoner, with built-in HTTP/SMB/MSSQL/FTP/LDAP rogue authentication server";
    homepage = "https://github.com/lgandx/Responder";
    changelog = "https://github.com/lgandx/Responder/blob/master/CHANGELOG.md";
    license = lib.licenses.gpl3Only;
    mainProgram = "responder";
    platforms = lib.platforms.linux;
  };
}

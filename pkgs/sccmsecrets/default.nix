{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:

let
  runtimePython = python313Packages.python.withPackages (
    ps: with ps; [
      beautifulsoup4
      cryptography
      pyasn1-modules
      requests
      requests-kerberos
      requests-ntlm
      requests-toolbelt
      typer
    ]
  );
in
python313Packages.buildPythonApplication {
  pname = "sccmsecrets";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "SCCMSecrets";
    rev = "5488158d097a7f76b879e0e5db7d9e123380fd7a";
    hash = "sha256-QrDhHNnMYaSeSgtmkGjyLlhicJX6v/wrY7jTBKBqX0c=";
  };

  format = "other";

  postPatch = ''
    substituteInPlace SCCMSecrets.py \
      --replace-fail '    banner = """' '    banner = r"""'
  '';

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -d "$out/share/sccmsecrets"
    cp -r ./*.py utils "$out/share/sccmsecrets/"
    makeWrapper ${runtimePython}/bin/python "$out/bin/sccmsecrets" \
      --add-flags "$out/share/sccmsecrets/SCCMSecrets.py"

    runHook postInstall
  '';

  meta = {
    description = "SCCM policies exploitation tool for credential harvesting and lateral movement";
    homepage = "https://github.com/synacktiv/SCCMSecrets";
    mainProgram = "sccmsecrets";
    platforms = lib.platforms.linux;
  };
}

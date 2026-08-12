{
  lib,
  python313Packages,
  fetchFromGitHub,
}:

python313Packages.buildPythonApplication rec {
  pname = "pkinittools";
  version = "unstable-2026-08-12";

  src = fetchFromGitHub {
    owner = "dirkjanm";
    repo = "PKINITtools";
    rev = "0f0cfa542b0348609ad494713e84744234b2d3b0";
    hash = "sha256-9aKcSe12jsCrjdqcH3w3/T3+DIce2KW08ukSRf5F+hE=";
  };

  # PKINITtools is a collection of standalone scripts rather than a Python
  # distribution. The Python application builder still gives the scripts a
  # reproducible interpreter and dependency environment.
  format = "other";

  dependencies = with python313Packages; [
    asn1crypto
    impacket
    minikerberos
    oscrypto
  ];

  installPhase = ''
    runHook preInstall
    for script in getnthash.py gets4uticket.py gettgtpkinit.py ntlmrelayx/httpattack.py; do
      install -Dm755 "$script" "$out/bin/$(basename "$script")"
    done
    runHook postInstall
  '';

  meta = {
    description = "Tools for Kerberos PKINIT and relaying to AD CS";
    homepage = "https://github.com/dirkjanm/PKINITtools";
    license = lib.licenses.mit;
    mainProgram = "gettgtpkinit.py";
    platforms = lib.platforms.linux;
  };
}

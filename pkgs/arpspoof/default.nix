{
  lib,
  python313Packages,
  makeWrapper,
}:

let
  runtimePython = python313Packages.python.withPackages (ps: [ ps.scapy ]);
in
python313Packages.buildPythonApplication rec {
  pname = "arpspoof";
  version = "unstable-2026-10-07";

  src = ./.;

  # Upstream is a standalone script rather than a Python distribution.
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  dontWrapPythonPrograms = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 arpspoof.py $out/share/arpspoof/arpspoof.py
    makeWrapper ${runtimePython}/bin/python $out/bin/arpspoof \
      --add-flags "$out/share/arpspoof/arpspoof.py"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/arpspoof" --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "ARP poisoning tool with an interactive command line interface";
    homepage = "https://github.com/ickerwx/arpspoof";
    mainProgram = "arpspoof";
    platforms = lib.platforms.linux;
  };
}

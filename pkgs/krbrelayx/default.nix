{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:

let
  src = fetchFromGitHub {
    owner = "dirkjanm";
    repo = "krbrelayx";
    rev = "10b45a33bc4361ec4a5546eea62db2e4244d3255";
    hash = "sha256-NnC14jVkWPhEtoGicTFMAef1/kHt8wZr6+Am4NQ4nUg=";
  };

  runtimePython = python313Packages.python.withPackages (ps: with ps; [
    dnspython
    impacket
    ldap3
    pyasn1
    pycryptodomex
    six
  ]);
in
python313Packages.buildPythonApplication {
  pname = "krbrelayx";
  version = "unstable-2026-03-11";

  inherit src;
  format = "other";

  postPatch = ''
    substituteInPlace printerbug.py \
      --replace-fail 'logging.info(version.BANNER)' 'print(version.BANNER, file=sys.stderr)'
  '';

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -d $out/lib/krbrelayx
    cp -R lib $out/lib/krbrelayx/

    for script in addspn.py dnstool.py krbrelayx.py printerbug.py; do
      install -Dm755 "$script" "$out/lib/krbrelayx/$script"
      makeWrapper ${runtimePython}/bin/python "$out/bin/$script" \
        --set PYTHONPATH "$out/lib/krbrelayx" \
        --add-flags "$out/lib/krbrelayx/$script"
    done

    PYTHONPATH="$out/lib/krbrelayx" ${runtimePython}/bin/python -c \
      'import lib.clients; import lib.servers; import lib.utils.kerberos'

    runHook postInstall
  '';

  meta = {
    description = "Kerberos relaying and unconstrained delegation abuse toolkit";
    homepage = "https://github.com/dirkjanm/krbrelayx";
    license = lib.licenses.mit;
    mainProgram = "krbrelayx.py";
    platforms = lib.platforms.linux;
  };
}

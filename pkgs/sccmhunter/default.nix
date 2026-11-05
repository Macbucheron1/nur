{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:

let
  # Upstream relies on the ly4k/ldap3 fork for TLS channel binding support.
  # impacket depends on stock ldap3, so alias it to the fork to keep a single
  # copy of the `ldap3` module in the environment (buildEnv rejects duplicates).
  python313 = python313Packages.python.override {
    packageOverrides = self: super: {
      ldap3 = super.ldap3-bleeding-edge;
      # The fork ships a different distribution name, which trips the runtime
      # dependency check of packages that declare a dependency on `ldap3`.
      impacket = super.impacket.overridePythonAttrs (_: {
        dontCheckRuntimeDeps = true;
      });
      ldapdomaindump = super.ldapdomaindump.overridePythonAttrs (_: {
        dontCheckRuntimeDeps = true;
      });
    };
  };

  runtimePython = python313.withPackages (
    ps: with ps; [
      cmd2
      cryptography
      impacket
      ldap3-bleeding-edge
      pandas
      pyasn1
      pyasn1-modules
      pycryptodome
      pyopenssl
      requests
      requests-ntlm
      requests-toolbelt
      rich
      tabulate
      typer
      urllib3
    ]
  );
in
python313Packages.buildPythonApplication {
  pname = "sccmhunter";
  version = "unstable-2026-10-28";

  src = fetchFromGitHub {
    owner = "garrettfoster13";
    repo = "sccmhunter";
    rev = "e32fe7469183b6c2e4a9dfd855dfb9a7c469d0a5";
    hash = "sha256-RbsqNpCg1tBMt9C1pl4A6VmFRQKZO9caTxGnkW+OQIc=";
  };

  # setup.py only declares the script and no packages, so `lib` would never be
  # installed into site-packages. Ship the sources as a directory instead and
  # let the wrapper put them on sys.path.
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -d "$out/share/sccmhunter"
    cp -r ./lib ./sccmhunter.py ./__init__.py "$out/share/sccmhunter/"
    makeWrapper ${runtimePython}/bin/python "$out/bin/sccmhunter" \
      --add-flags "$out/share/sccmhunter/sccmhunter.py"

    runHook postInstall
  '';

  # `checkPhase` runs as `installCheckPhase` here, i.e. after installation.
  doCheck = true;
  checkPhase = ''
    runHook preCheck

    PYTHONPATH="$out/share/sccmhunter" ${runtimePython.interpreter} -c 'import lib.commands.find, lib.commands.http, lib.commands.mssql, lib.commands.smb, lib.commands.relay, lib.commands.show, lib.commands.admin, lib.commands.dpapi'
    "$out/bin/sccmhunter" --help > /dev/null

    runHook postCheck
  '';

  meta = {
    description = "SCCM enumeration, credential harvesting and lateral movement toolkit";
    homepage = "https://github.com/garrettfoster13/sccmhunter";
    license = lib.licenses.gpl3Only;
    mainProgram = "sccmhunter";
    platforms = lib.platforms.linux;
  };
}

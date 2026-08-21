{
  lib,
  python313Packages,
  fetchFromGitHub,
  makeWrapper,
}:

let
  pythonDeps = with python313Packages; [
    chardet
    ldap3-bleeding-edge
    lxml
    pydantic
    smbprotocol
    typer
  ];
in
python313Packages.buildPythonApplication {
  pname = "group-policy-backdoor";
  version = "unstable-2025-12-07";

  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "GroupPolicyBackdoor";
    rev = "c5d935b01b8288fc81e19fd62ce8cb2d4ecaacea";
    hash = "sha256-+ZjQVECYvGIXAQlyRrvz4KEx9WNBlLsWu0GT80aqnQY=";
  };

  # Upstream is a script and a Python package without packaging metadata.
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  dependencies = pythonDeps;
  dontWrapPythonPrograms = true;

  patches = [ ./python-syntax-warnings.patch ];

  buildPhase = ''
    runHook preBuild
    PYTHONWARNINGS=error::SyntaxWarning ${python313Packages.python.interpreter} -m compileall -q .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/${python313Packages.python.sitePackages}"
    cp -r gpb "$out/${python313Packages.python.sitePackages}/"
    install -Dm644 config.py "$out/${python313Packages.python.sitePackages}/config.py"

    install -Dm644 gpb.py "$out/${python313Packages.python.sitePackages}/group_policy_backdoor_cli.py"
    makeWrapper ${python313Packages.python.interpreter} "$out/bin/gpb" \
      --add-flags "$out/${python313Packages.python.sitePackages}/group_policy_backdoor_cli.py" \
      --prefix PYTHONPATH : "$out/${python313Packages.python.sitePackages}:${python313Packages.makePythonPath pythonDeps}"
    ln -s gpb "$out/bin/gpb.py"

    mkdir -p "$out/share/GroupPolicyBackdoor"
    cp -r modules_templates "$out/share/GroupPolicyBackdoor/"

    runHook postInstall
  '';

  pythonImportsCheck = [
    "config"
    "gpb"
    "gpb.protocols.ldap"
    "gpb.protocols.smb"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/gpb" --help >/dev/null
    "$out/bin/gpb.py" gpo --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Modular framework for manipulating and exploiting Group Policy Objects";
    homepage = "https://github.com/synacktiv/GroupPolicyBackdoor";
    license = lib.licenses.mit;
    mainProgram = "gpb.py";
    platforms = lib.platforms.linux;
  };
}

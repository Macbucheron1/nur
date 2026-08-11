{
  lib,
  python313Packages,
  fetchFromGitHub,
  fetchurl,
}:

let
  devious-pypsrp = python313Packages.buildPythonPackage {
    pname = "devious-pypsrp";
    version = "1.0.1";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/source/d/devious-pypsrp/devious_pypsrp-1.0.1.tar.gz";
      hash = "sha256-+ollJs+AsNv/iKmNkq5H2YDXh1keDMJFzU1UFXJ7J5k=";
    };

    pyproject = true;
    build-system = [ python313Packages.setuptools ];

    dependencies = with python313Packages; [
      cryptography
      httpx
      psrpcore
      pyspnego
      requests
      gssapi
    ];

    pythonRelaxDeps = [ "httpcore" ];
  };
in
python313Packages.buildPythonApplication {
  pname = "devious-winrm";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "1upbyte";
    repo = "Devious-WinRM";
    rev = "v1.2.2";
    hash = "sha256-TeDQI2ds58YOJwbTPw/OcHpGvb4E14xo9RAF0uz5060=";
  };

  pyproject = true;
  build-system = [ python313Packages.setuptools ];

  dependencies = with python313Packages; [
    devious-pypsrp
    impacket
    prompt-toolkit
    pygments
    rich
    typer
  ];

  pythonRelaxDeps = [ "impacket" ];
  pythonImportsCheck = [ "devious_winrm" ];

  meta = {
    description = "A Pentester's Powershell Client";
    homepage = "https://github.com/1upbyte/Devious-WinRM";
    license = lib.licenses.mit;
    mainProgram = "devious-winrm";
  };
}

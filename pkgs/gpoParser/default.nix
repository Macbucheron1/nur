{
  lib,
  python313Packages,
  fetchFromGitHub,
}:

python313Packages.buildPythonApplication {
  pname = "gpoParser";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "gpoParser";
    rev = "5cfe7aa3556f7c9263620515a33f4ef7afb88c1b";
    hash = "sha256-Vt2L5X/dnn07y876cUnaBGF9jcGyjuYZimGoiDGwR8Q=";
  };

  pyproject = true;
  build-system = [ python313Packages.setuptools ];

  dependencies = with python313Packages; [
    ldap3-bleeding-edge
    chardet
    impacket
    ijson
    neo4j
  ];

  pythonRelaxDeps = [ "ldap3-bleeding-edge" ];
  pythonImportsCheck = [ "gpoParser" ];

  meta = {
    description = "Extract and analyze Active Directory Group Policy Objects";
    homepage = "https://github.com/synacktiv/gpoParser";
    license = lib.licenses.mit;
    mainProgram = "gpoParser";
  };
}

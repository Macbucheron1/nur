{
  lib,
  python313Packages,
  fetchFromGitHub,
}:

python313Packages.buildPythonApplication rec {
  pname = "exegol-history";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "ThePorgs";
    repo = "Exegol-history";
    rev = "737ee6ec3abab3c00f70a2247d7f74ce4e89a709";
    hash = "sha256-aZIFed908OjrUzOB/WF9mMLHr90jhoKU1JGxoIS/VnM=";
  };

  pyproject = true;
  build-system = [ python313Packages.uv-build ];

  # Nixpkgs may ship an older uv-build than the project's lower bound. The
  # backend API used here is compatible with the packaged version.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'uv_build>=0.10.7,<0.11.0' 'uv_build'
  '';

  dependencies = with python313Packages; [
    argcomplete
    pykeepass
    pyperclip
    psycopg
    pyyaml
    rich
    sqlalchemy
    textual
  ];

  pythonRelaxDeps = [
    "rich"
    "textual"
  ];

  # The application copies this file from the directory containing the
  # installed Python package on first startup.
  postInstall = ''
    install -Dm644 profile.sh "$out/${python313Packages.python.sitePackages}/profile.sh"
  '';

  pythonImportsCheck = [ "exegol_history" ];

  meta = {
    description = "TUI to manage compromised credentials and hosts during an engagement";
    homepage = "https://github.com/ThePorgs/Exegol-history";
    mainProgram = "exegol-history";
  };
}

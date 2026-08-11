{
  lib,
  python313Packages,
  fetchFromGitHub,
}:

python313Packages.buildPythonApplication rec {
  pname = "bhcli";
  version = "0.0.1.dev";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "exploide";
    repo = "bhcli";
    rev = "e38943ae89b09a1ba4dc65a2e0355978fe41477c";
    hash = "sha256-CdyNcmxR0PBek99GvalIT1+u1Lck5PT04ODSKhtRNps=";
  };

  build-system = [ python313Packages.hatchling ];

  dependencies = with python313Packages; [
    click
    prettytable
    requests
  ];

  pythonRelaxDeps = [ "click" ];

  meta = {
    description = "CLI tool to interact with the BloodHound CE API";
    homepage = "https://github.com/exploide/bhcli";
    license = lib.licenses.mit;
    mainProgram = "bhcli";
  };
}

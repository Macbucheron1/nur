{
  lib,
  python313Packages,
  fetchFromGitHub,
}:

python313Packages.buildPythonApplication rec {
  pname = "graphspy";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "RedByte1337";
    repo = "GraphSpy";
    rev = "5a74c8fafba5791629254eaca9bce3849d59c110";
    hash = "sha256-+WiEVxeg/4hOVu+EOT6/YH7N8YmaJfGQaVR0Sv93cjY=";
  };

  pyproject = true;
  build-system = [ python313Packages.uv-build ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'uv_build>=0.11.8,<0.12' 'uv_build'
  '';

  dependencies = with python313Packages; [
    fido2
    flask
    loguru
    pyjwt
    pyotp
    requests
    waitress
  ];

  pythonImportsCheck = [ "graphspy" ];

  meta = {
    description = "Initial Access and Post-Exploitation Tool for Entra ID and M365 with a browser-based GUI";
    homepage = "https://github.com/RedByte1337/GraphSpy";
    license = lib.licenses.bsd3;
    mainProgram = "graphspy";
    platforms = lib.platforms.linux;
  };
}

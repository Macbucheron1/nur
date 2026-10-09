{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication {
  pname = "webclientservicescanner";
  version = "0.1.0";

  pyproject = true;
  build-system = [ python313Packages.setuptools ];

  src = fetchFromGitHub {
    owner = "Hackndo";
    repo = "WebclientServiceScanner";
    rev = "f0a73e67a35402d1dc7d342ed8889d129c96a48c";
    hash = "sha256-XxtppcsAd8n/9Bs0IbrtzhU0ng3LTafAyIeWHwipkZw=";
  };

  dependencies = with python313Packages; [
    impacket
    netaddr
  ];

  pythonImportsCheck = [ "webclientservicescanner" ];

  meta = {
    description = "Check running WebClient services on multiple targets";
    homepage = "https://github.com/Hackndo/WebclientServiceScanner";
    license = lib.licenses.mit;
    mainProgram = "webclientservicescanner";
    platforms = lib.platforms.linux;
  };
}

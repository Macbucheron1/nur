{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication rec {
  pname = "adidnsdump";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "dirkjanm";
    repo = "adidnsdump";
    rev = "95adaf8ed278088217f08f88a15d12bb411dd2e8";
    hash = "sha256-mik1iRSakb+x5+w/eN9IGHUfIBKTjWem7cgJPrFD08U=";
  };

  pyproject = true;
  build-system = [ python313Packages.setuptools ];

  dependencies = with python313Packages; [
    dnspython
    impacket
    ldap3
  ];

  pythonImportsCheck = [ "adidnsdump" ];

  meta = {
    description = "Active Directory Integrated DNS dumping by any authenticated user";
    homepage = "https://github.com/dirkjanm/adidnsdump";
    license = lib.licenses.mit;
    mainProgram = "adidnsdump";
    platforms = lib.platforms.linux;
  };
}

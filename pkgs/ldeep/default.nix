{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication rec {
  pname = "ldeep";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "franc-pentest";
    repo = "ldeep";
    rev = "daaa90606b1ff195a2126b57603e4749203c70e6";
    hash = "sha256-oHIANuX6MVEg/dKwwGouwwfiGsHrFlzNnYHmCskbhkc=";
  };

  pyproject = true;
  build-system = [ python313Packages.pdm-backend ];

  env.PDM_BUILD_SCM_VERSION = version;

  dependencies = with python313Packages; [
    commandparse
    cryptography
    dnspython
    gssapi
    ldap3-bleeding-edge
    oscrypto
    pycryptodome
    pycryptodomex
    termcolor
    tqdm
  ];

  pythonRelaxDeps = [ "ldap3-bleeding-edge" ];

  pythonImportsCheck = [ "ldeep" ];

  meta = {
    description = "In-depth LDAP enumeration utility";
    homepage = "https://github.com/franc-pentest/ldeep";
    license = lib.licenses.mit;
    mainProgram = "ldeep";
    platforms = lib.platforms.linux;
  };
}

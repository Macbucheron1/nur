{
  lib,
  fetchFromGitHub,
  fetchPypi,
  python313Packages,
  symlinkJoin,
}:
let
  version = "0-unstable-2026-10-07";

  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "ROADtools";
    rev = "c91bac70494134cd54e3c694556a56ed32458458";
    hash = "sha256-7jErb+xNEtwDoG0hfNdngYLhSF0C9amfQsHRN9h9hcc=";
  };

  meta = {
    description = "Azure AD / Entra ID framework (roadrecon, roadtx)";
    homepage = "https://github.com/synacktiv/ROADtools";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };

  roadlib = python313Packages.buildPythonPackage {
    pname = "roadlib";
    inherit version src;
    sourceRoot = "${src.name}/roadlib";

    pyproject = true;
    build-system = [ python313Packages.setuptools ];

    dependencies = with python313Packages; [
      aiohttp
      cbor2
      cryptography
      pyjwt
      requests
      sqlalchemy
    ];

    pythonImportsCheck = [ "roadtools.roadlib" ];

    inherit meta;
  };

  # Fork of selenium-wire required by roadtx (nixpkgs' selenium-wire is broken)
  selenium-wire-roadtx = python313Packages.buildPythonPackage rec {
    pname = "selenium-wire-roadtx";
    version = "5.2.4";

    src = fetchPypi {
      pname = "selenium_wire_roadtx";
      inherit version;
      hash = "sha256-GkVbU0AIqFHjCJfUKyxol76CIcQ4Uqr24/viQIIw1XE=";
    };

    pyproject = true;
    build-system = [ python313Packages.setuptools ];

    dependencies = with python313Packages; [
      blinker
      brotli
      certifi
      h2
      hyperframe
      kaitaistruct
      pyasn1
      pyopenssl
      pyparsing
      pysocks
      ruamel-yaml
      selenium
      setuptools
      typing-extensions
      wsproto
      zstandard
    ];

    pythonImportsCheck = [ "seleniumwire" ];

    meta = {
      description = "Fork of selenium-wire used by roadtx";
      homepage = "https://github.com/dirkjanm/selenium-wire-roadtx";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  };

  roadrecon = python313Packages.buildPythonApplication {
    pname = "roadrecon";
    inherit version src;
    sourceRoot = "${src.name}/roadrecon";

    pyproject = true;
    build-system = [ python313Packages.setuptools ];

    dependencies = with python313Packages; [
      aiohttp
      fastapi
      openpyxl
      roadlib
      sqlalchemy
      uvicorn
      # plugins: bloodhound, road2timeline
      neo4j
      numpy
      pandas
      pyyaml
    ];

    pythonImportsCheck = [ "roadtools.roadrecon" ];

    meta = meta // {
      mainProgram = "roadrecon";
    };
  };

  roadtx = python313Packages.buildPythonApplication {
    pname = "roadtx";
    inherit version src;
    sourceRoot = "${src.name}/roadtx";

    pyproject = true;
    build-system = [ python313Packages.setuptools ];

    dependencies = with python313Packages; [
      pycryptodomex
      pyotp
      requests
      roadlib
      selenium
      selenium-wire-roadtx
      setuptools
      signxml
    ];

    pythonImportsCheck = [ "roadtools.roadtx" ];

    meta = meta // {
      mainProgram = "roadtx";
    };
  };
in
symlinkJoin {
  name = "roadtools-${version}";
  paths = [
    roadrecon
    roadtx
  ];

  passthru = {
    inherit
      roadlib
      roadrecon
      roadtx
      selenium-wire-roadtx
      ;
  };

  meta = meta // {
    mainProgram = "roadrecon";
  };
}

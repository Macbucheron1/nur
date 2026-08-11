{
  lib,
  python313Packages,
  fetchFromGitHub,
  fetchurl,
}:

let
  # Kreuzberg is not in nixpkgs yet. Use its abi3 wheel, which supports
  # Python 3.13 and the x86_64-linux system used by Nixploit.
  kreuzberg = python313Packages.buildPythonPackage {
    pname = "kreuzberg";
    version = "4.2.9";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/2f/ec/59f3e259d57b96412b8f47599190317f3733c9f72a467aef5f86e8302906/kreuzberg-4.2.9-cp310-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-jqQjYwWOZqpM0w2fInTBCNhzvIfBdTwF1fLZKGp6yFc=";
    };

    pythonImportsCheck = [ "kreuzberg" ];
  };
in
python313Packages.buildPythonApplication rec {
  pname = "manspider";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "blacklanternsecurity";
    repo = "MANSPIDER";
    rev = "dd76e9c9c460537828bb0143d23bba0b7c9f5185";
    hash = "sha256-0dyEobBmXH7cqUaEbvMNvUkkz4lovX6WUeG4xEawt4M=";
  };

  pyproject = true;
  build-system = [ python313Packages.hatchling ];

  dependencies = with python313Packages; [
    charset-normalizer
    impacket
    kreuzberg
  ];

  pythonImportsCheck = [ "man_spider" ];

  meta = {
    description = "SMB spider capable of searching file content";
    homepage = "https://github.com/blacklanternsecurity/MANSPIDER";
    license = lib.licenses.gpl3Only;
    mainProgram = "manspider";
  };
}

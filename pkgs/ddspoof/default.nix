{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:

let
  runtimePython = python313Packages.python.withPackages (
    ps: with ps; [
      click
      click-shell
      dnspython
      scapy
    ]
  );
in
python313Packages.buildPythonApplication rec {
  pname = "ddspoof";
  version = "unstable-2024-02-22";

  src = fetchFromGitHub {
    owner = "akamai";
    repo = "DDSpoof";
    rev = "1e4322220e32d3d63b98137aac45eba24d671a7b";
    hash = "sha256-Rxgzv20C1u3/batVvbYMWGddEXEWhIlrxzMSkR2qdHw=";
  };

  # Upstream ships standalone scripts rather than a Python distribution. They
  # import their sibling modules by absolute name (networking, sniffers, utils),
  # so the whole tree is installed in a single directory and the entry points
  # are run from there, which puts that directory on sys.path.
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  dontWrapPythonPrograms = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/ddspoof
    cp -r ddspoof.py dhcp_coerce.py spoofer_config.py networking sniffers utils \
      $out/share/ddspoof/
    for script in ddspoof.py dhcp_coerce.py; do
      makeWrapper ${runtimePython}/bin/python $out/bin/$script \
        --add-flags "$out/share/ddspoof/$script"
    done
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # click-shell keeps a history file under $HOME, which does not exist in the
    # build sandbox, and bytecode must not be written into the output.
    export HOME=$(mktemp -d)
    export PYTHONDONTWRITEBYTECODE=1
    "$out/bin/ddspoof.py" --help >/dev/null
    "$out/bin/dhcp_coerce.py" --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "DHCP DNS Dynamic Update attacks against Microsoft DHCP servers in AD environments";
    homepage = "https://github.com/akamai/DDSpoof";
    license = lib.licenses.asl20;
    mainProgram = "ddspoof.py";
    platforms = lib.platforms.linux;
  };
}

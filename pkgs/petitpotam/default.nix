{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication rec {
  pname = "petitpotam";
  version = "unstable-2024-08-15";

  src = fetchFromGitHub {
    owner = "topotam";
    repo = "PetitPotam";
    rev = "c5d5221dc5e6aac3bc7de97a34fa8d89c2f1900b";
    hash = "sha256-eaNnz/61gnBYJiyf4tpdRRTT0mYtRcafgFeUaVoucjY=";
  };

  format = "other";

  dependencies = [ python313Packages.impacket ];

  installPhase = ''
    runHook preInstall
    install -Dm755 PetitPotam.py $out/bin/petitpotam
    runHook postInstall
  '';

  meta = {
    description = "PoC to coerce Windows hosts to authenticate via MS-EFSRPC";
    homepage = "https://github.com/topotam/PetitPotam";
    license = lib.licenses.unfree;
    mainProgram = "petitpotam";
    platforms = lib.platforms.linux;
  };
}

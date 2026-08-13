{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  python313Packages,
}:

let
  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "bbs";
    rev = "7b2db3271334d65fa7f0de0723580ddb9f74248c";
    hash = "sha256-FqK0VnnQm2Jlv/0EY1cnvHuBD96BWbDi6si3J6zRhwA=";
  };

  bbscliPython = python313Packages.python.withPackages (ps: [ ps.pyparsing ]);
in
buildGoModule {
  pname = "bbs";
  version = "unstable-2026-07-27";

  inherit src;
  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -Dm755 ${src}/bbscli.py $out/share/bbs/bbscli.py
    makeWrapper ${bbscliPython}/bin/python $out/bin/bbscli \
      --add-flags "$out/share/bbs/bbscli.py"
  '';

  meta = {
    description = "Router for SOCKS and HTTP proxies";
    homepage = "https://github.com/synacktiv/bbs";
    license = lib.licenses.mit;
    mainProgram = "bbs";
    platforms = lib.platforms.linux;
  };
}

{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  krb5,
}:

rustPlatform.buildRustPackage rec {
  pname = "rusthound-ce";
  version = "2.5.23";

  src = fetchFromGitHub {
    owner = "g0h4n";
    repo = "RustHound-CE";
    rev = "271c0dc9f694170f15b0e73d42c6e3da3b93731a";
    hash = "sha256-gNYOsdvVWZ8UM6v3WG/KZM2qpR4Gl+h122fmTGBdD1s=";
  };

  cargoHash = "sha256-r400y54l8lzqhcy4/A6FD9Uj6UBXeT5bBOBGWPK11N4=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [ krb5 ];

  meta = {
    description = "Active Directory data ingestor for BloodHound Community Edition written in Rust";
    homepage = "https://github.com/g0h4n/RustHound-CE";
    license = lib.licenses.mit;
    mainProgram = "rusthound-ce";
    platforms = lib.platforms.linux;
  };
}

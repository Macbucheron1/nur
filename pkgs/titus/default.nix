{
  lib,
  buildGoModule,
  go_1_27,
  fetchFromGitHub,
  pkg-config,
  vectorscan,
}:

(buildGoModule.override { go = go_1_27; }) rec {
  pname = "titus";
  version = "1.2.9";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "titus";
    rev = "e317c1d186cc213d069a2ab71892649c042780ee";
    hash = "sha256-Z8flufvaUI+eA9PpYJihE3afZX1ZmvcnV9LORWVeNHc=";
  };

  vendorHash = "sha256-1kJeOd9laPbGBQP4hDKg5t4rVy0NqUG4QZj9LupV7+c=";

  subPackages = [ "cmd/titus" ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ vectorscan ];

  tags = [ "vectorscan" ];

  env.CGO_ENABLED = "1";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Integration tests need network access and fixtures.
  doCheck = false;

  meta = {
    description = "Secrets scanner with Hyperscan-accelerated detection rules";
    homepage = "https://github.com/praetorian-inc/titus";
    license = lib.licenses.asl20;
    mainProgram = "titus";
    platforms = lib.platforms.linux;
  };
}

{
  lib,
  buildGoModule,
  fetchFromGitHub,
  docker-client,
}:

buildGoModule rec {
  pname = "bloodhound-cli";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "SpecterOps";
    repo = "bloodhound-cli";
    rev = "v${version}";
    hash = "sha256-m6WXzgEGW1ClFMRswt2OM71t6zu0OyEcqrVUC1IkG9g=";
  };

  vendorHash = "sha256-FrZlVD7OKtd0nJQy3a2FR3qfrEyF6HpeTmnc0Jk1A2g=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/SpecterOps/BloodHound_CLI/cmd/config.Version=v${version}"
  ];

  nativeCheckInputs = [ docker-client ];
  preCheck = ''
    export HOME="$TMPDIR/test-home"
    mkdir -p "$HOME"
  '';
  # These integration tests require a running Docker daemon or GitHub access.
  checkFlags = [ "-skip=TestEvaluateDockerComposeStatus|TestGetRemoteBloodHoundCliVersion" ];

  postInstall = ''
    mv $out/bin/BloodHound_CLI $out/bin/bloodhound-cli
  '';

  meta = {
    description = "Install and manage BloodHound Community Edition";
    homepage = "https://github.com/SpecterOps/bloodhound-cli";
    license = lib.licenses.asl20;
    mainProgram = "bloodhound-cli";
    platforms = lib.platforms.linux;
  };
}

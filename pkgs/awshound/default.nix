{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule {
  pname = "awshound";
  version = "unstable-2026-09-30";

  src = fetchFromGitHub {
    owner = "AWSHound";
    repo = "AWSHound";
    rev = "0033783f96c76529e6025de0a65017790218c4ea";
    hash = "sha256-VDR045pcR322BSU3u4wKUznXjLNfVK/6WE+KrCuzkQ8=";
  };

  vendorHash = "sha256-hGrpxzqkCv8xsHlPR6d2k/5UxwqRwO27k7BzboXFYOw=";

  subPackages = [ "cmd/awshound" ];

  meta = {
    description = "AWS IAM data collector and BloodHound OpenGraph connector";
    homepage = "https://github.com/AWSHound/AWSHound";
    license = lib.licenses.asl20;
    mainProgram = "awshound";
    platforms = lib.platforms.linux;
  };
}

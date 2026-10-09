{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "iamhounddog";
  version = "unstable-2026-09-17";

  src = fetchFromGitHub {
    owner = "VirtueSecurity";
    repo = "IAMhounddog";
    rev = "6be267c86778205af8749eccce375b4a30f66570";
    hash = "sha256-/JWV2S4q3SzmeTvnce1JZfaNyVmHmCOtnG6cmkuxBeE=";
  };

  vendorHash = "sha256-K03LjpGv2AXNBPNvXZT42R+BlQNOIhviD7t1JDTtm9c=";

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = {
    description = "Identify privileged AWS principals and privilege escalation paths for BloodHound";
    homepage = "https://github.com/VirtueSecurity/IAMhounddog";
    # Upstream does not provide a license.
    license = lib.licenses.unfree;
    mainProgram = "IAMhounddog";
    platforms = lib.platforms.linux;
  };
}

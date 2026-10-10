{
  description = "Cybersecurity Packages";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      legacyPackages = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { inherit system; };
      });
      # Keep unsupported, broken and unfree packages available through
      # legacyPackages, but exclude them from the flake-checkable outputs.
      packages = forAllSystems (system: nixpkgs.lib.filterAttrs
        (_: pkg:
          nixpkgs.lib.isDerivation pkg
          && nixpkgs.lib.meta.availableOn { inherit system; } pkg
          && !(pkg.meta.broken or false)
          && builtins.all (license: license.free or true)
            (nixpkgs.lib.toList (pkg.meta.license or [ ])))
        self.legacyPackages.${system});
      overlays = import ./overlays;
      nixosModules = import ./nixos-modules;
      # homeModules = import ./home-modules;
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
    };
}

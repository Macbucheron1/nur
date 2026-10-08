# AGENTS.md

NUR (Nix User Repository) package set: cybersecurity/pentest tools packaged as a Nix flake and published to the NUR registry as `Macbucheron1/nur`. One tool per directory.

## Layout

- `pkgs/<name>/default.nix` — one package per dir; patches live alongside (e.g. `python-syntax-warnings.patch`).
- `default.nix` — top-level attrset. **Every new package must be registered here** with `pkgs.callPackage ./pkgs/<name> { }`.
- `flake.nix` — exposes `legacyPackages` (all attrs) and `packages` (derivations only), plus `overlays` / `nixosModules`.
- `overlays/flat.nix` (`pkgs.<name>`) and `overlays/nur.nix` (`pkgs.nur.<name>`) both re-import `default.nix`, so they need no per-package edits.
- `ci.nix` — auto-discovers buildable/cacheable outputs from `default.nix`; CI builds `cacheOutputs`. No per-package edits.
- `lib/`, `nixos-modules/` — mostly empty extension points.

Reserved names never treated as packages: `lib`, `overlays`, `nixosModules`, `homeModules`, `darwinModules`, `flakeModules`.

## Adding / updating a package

1. Create `pkgs/<name>/default.nix`.
2. Add `<name> = pkgs.callPackage ./pkgs/<name> { };` to `default.nix`.
3. Add a row to the README package table, linking the tool name to its upstream homepage (`meta.homepage`). That is the only README change required — do not add usage instructions or any other section.

No edits to `ci.nix` or the overlays are needed.

## Commands

- Build one: `nix build .#<name>` then run `./result/bin/<name>`.
- Validate the flake / evaluate everything: `nix flake check`.
- CI-parity build: `nix shell -f '<nixpkgs>' nix-build-uncached -c nix-build-uncached ci.nix -A cacheOutputs`.
- Format with `alejandra .` (the flake does not wire a `formatter`).
- `result*` symlinks are build artifacts and gitignored.

## Conventions / gotchas

- `nixpkgs-unstable` is pinned in `flake.lock`; CI also evaluates `nixos-unstable` and `nixos-26.05`.
- Python packages target `python313Packages` (Python 3.13) and `x86_64-linux`.
- Prefer standard builders: `buildPythonApplication` with `pyproject = true` + `build-system`. Use `format = "other"` plus a hand-written `installPhase` for upstreams that ship loose scripts (e.g. `petitpotam`, `pkinittools`, `krbrelayx`).
- `pythonRelaxDeps` is used to override upstream upper bounds; `pythonImportsCheck` is expected on Python packages.
- Derivation metadata sets `mainProgram` and (usually) `platforms = lib.platforms.linux`.
- Fetch sources are pinned to a `rev`; when bumping a rev you must also update the `hash` (and `cargoHash` / `vendorHash`, etc.).
- When upstream is compatible only with a newer/older backend than nixpkgs ships, patch it in `postPatch` (see `exegol-history` uv-build bound).

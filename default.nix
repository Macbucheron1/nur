# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `overlays`,
# `nixosModules`, `homeModules`, `darwinModules` and `flakeModules`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> { } }:

{
  # The `lib`, `overlays`, `nixosModules`, `homeModules`,
  # `darwinModules` and `flakeModules` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  # homeModules = { }; # Home Manager modules
  # darwinModules = { }; # nix-darwin modules
  # flakeModules = { }; # flake-parts modules
  overlays = import ./overlays; # nixpkgs overlays

  adidnsdump = pkgs.callPackage ./pkgs/adidnsdump { };
  awshound = pkgs.callPackage ./pkgs/awshound { };
  bbs = pkgs.callPackage ./pkgs/bbs { };
  bhcli = pkgs.callPackage ./pkgs/bhcli { };
  devious-winrm = pkgs.callPackage ./pkgs/devious-winrm { };
  exegol-history = pkgs.callPackage ./pkgs/exegol-history { };
  gpoParser = pkgs.callPackage ./pkgs/gpoParser { };
  graphspy = pkgs.callPackage ./pkgs/graphspy { };
  group-policy-backdoor = pkgs.callPackage ./pkgs/group-policy-backdoor { };
  iamhounddog = pkgs.callPackage ./pkgs/iamhounddog { };
  krbrelayx = pkgs.callPackage ./pkgs/krbrelayx { };
  manspider = pkgs.callPackage ./pkgs/manspider { };
  petitpotam = pkgs.callPackage ./pkgs/petitpotam { };
  pkinittools = pkgs.callPackage ./pkgs/pkinittools { };
  rusthound-ce = pkgs.callPackage ./pkgs/rusthound-ce { };
  sccmsecrets = pkgs.callPackage ./pkgs/sccmsecrets { };
  webclientservicescanner = pkgs.callPackage ./pkgs/webclientservicescanner { };
}

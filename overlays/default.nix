# Overlays provided by this repository.
#
# - `default` exposes every package at the top level (pkgs.<name>).
# - `nur` nests them under the `nur` namespace (pkgs.nur.<name>).
{
  default = import ./flat.nix;
  nur = import ./nur.nix;
}

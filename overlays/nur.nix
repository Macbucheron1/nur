# You can use this file as a nixpkgs overlay. Unlike ./flat.nix, which
# exposes the packages at the top level (pkgs.<name>), this overlay places
# them under the `nur` namespace so they can be referenced as
# `pkgs.nur.<name>`.
self: super: let
  isReserved = n: n == "lib" || n == "overlays" || n == "nixosModules" || n == "homeModules" || n == "darwinModules" || n == "flakeModules";
  nameValuePair = n: v: {
    name = n;
    value = v;
  };
  nurAttrs = import ../default.nix {pkgs = super;};
in {
  nur =
    builtins.listToAttrs
    (map (n: nameValuePair n nurAttrs.${n})
      (builtins.filter (n: !isReserved n)
        (builtins.attrNames nurAttrs)));
}

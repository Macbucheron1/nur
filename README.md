# nur-packages-template

A collection of cybersecurity packages, packaged as a [Nix flake](https://nixos.wiki/wiki/Flakes) so it can be consumed as a flake input.

## Contents

| Package                | Description                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| [adidnsdump](https://github.com/dirkjanm/adidnsdump)              | Active Directory Integrated DNS dumping by any authenticated user           |
| [bbs](https://github.com/synacktiv/bbs)                           | Router for SOCKS and HTTP proxies                                           |
| [bhcli](https://github.com/exploide/bhcli)                        | CLI tool to interact with the BloodHound CE API                             |
| [devious-winrm](https://github.com/1upbyte/Devious-WinRM)         | A pentester's PowerShell client                                             |
| [exegol-history](https://github.com/ThePorgs/Exegol-history)      | TUI to manage compromised credentials and hosts during an engagement        |
| [gpoParser](https://github.com/synacktiv/gpoParser)               | Extract and analyze Active Directory Group Policy Objects                   |
| [group-policy-backdoor](https://github.com/synacktiv/GroupPolicyBackdoor) | Modular framework for manipulating and exploiting Group Policy Objects |
| [manspider](https://github.com/blacklanternsecurity/MANSPIDER)    | SMB spider capable of searching file content                                |
| [petitpotam](https://github.com/topotam/PetitPotam)               | Coerce Windows hosts to authenticate via MS-EFSRPC                          |
| [pkinittools](https://github.com/dirkjanm/PKINITtools)            | Tools for Kerberos PKINIT and relaying to AD CS                             |
| [krbrelayx](https://github.com/dirkjanm/krbrelayx)                | Kerberos relaying and unconstrained delegation abuse toolkit                |
| [rusthound-ce](https://github.com/g0h4n/RustHound-CE)             | Active Directory data ingestor for BloodHound Community Edition             |

## Usage

### Run a package without installing

```console
$ nix run github:Macbucheron1/nur#adidnsdump -- --help
```

### Drop into a shell with a package available

```console
$ nix shell github:Macbucheron1/nur#adidnsdump
$ adidnsdump --help
```

### Add it as a flake input

Add the repository to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nur.url = "github:Macbucheron1/nur";
  };

  outputs = { self, nixpkgs, nur }: {
    # ...
  };
}
```

Then either reference the packages directly:

```nix
# per-system, e.g. using flake-utils
packages = {
  adidnsdump = nur.packages.${system}.adidnsdump;
};
```

or apply an overlay. Two overlays are provided:

- `nur.overlays.default` exposes every tool at the top level, i.e. `pkgs.<name>`.
- `nur.overlays.nur` nests them under the `nur` namespace, i.e. `pkgs.nur.<name>`.

```nix
{
  # Expose tools as pkgs.<name>
  nixpkgs.overlays = [ nur.overlays.default ];
  environment.systemPackages = [ pkgs.adidnsdump ];
}
```

```nix
{
  # Expose tools as pkgs.nur.<name>
  nixpkgs.overlays = [ nur.overlays.nur ];
  environment.systemPackages = [ pkgs.nur.adidnsdump ];
}
```

### Build from a checkout

```console
$ nix build .#adidnsdump
$ ./result/bin/adidnsdump --help
```

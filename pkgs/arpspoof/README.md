# arpspoof

An ARP poisoning tool with an interactive command line interface that lets you
add and remove targets on the fly.

## Usage

`arpspoof` sends raw ARP frames, so it needs root (or `CAP_NET_RAW` /
`CAP_NET_ADMIN`):

```console
$ sudo arpspoof -i eth0 -t 192.168.1.234 -g 192.168.1.1
...
arpspoof# help
add <IP>: add IP address to target list
del <IP>: remove IP address from target list
list: print all current targets
exit: stop poisoning and exit
arpspoof# exit
```

The `-t` and `-g` options are required; `-i` is useful when multiple interfaces
are connected. Targets may be plain IP addresses and/or CIDR subnets, e.g.
`-t 10.1.1.2,10.1.1.32,10.1.1.0/24`.

Once started, poisoning runs in the background and you are dropped into a
prompt where you can manage the target list:

- `add <IP>` / `del <IP>` modify the list of targets
- `list` prints all current targets and the gateway
- `exit` stops poisoning, restores the ARP caches and exits

### Options

| Flag | Description |
| --- | --- |
| `-i`, `--interface` | Interface to send from |
| `-t`, `--targets` | Comma-separated IP addresses and/or CIDR subnets (required) |
| `-g`, `--gateway` | IP address of the gateway (required) |
| `-v`, `--verbose` | Increase log verbosity (repeat for more) |
| `-q`, `--quiet` | Only log warnings and errors |
| `--log-file` | Also append logs to this file |

On exit, `arpspoof` restores the ARP caches of the gateway and the targets by
sending three correct ARP responses.

## Credits

This is a fork of [ickerwx/arpspoof](https://github.com/ickerwx/arpspoof)
ported to Python 3. Upstream only supported Python 2; the fork runs on Python 3
and adds CIDR target expansion, batched target resolution and a logging layer.

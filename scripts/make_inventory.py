#!/usr/bin/env python3
"""Generate an inventory from Terraform output, or an explicitly supplied IPv4."""
import argparse
import ipaddress
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--ip')
parser.add_argument('--output', default='hosts')
args = parser.parse_args()
address = args.ip or subprocess.run(
    ['terraform', 'output', '-raw', 'public_ip'],
    capture_output=True, text=True, check=True, timeout=30
).stdout.strip()
address = str(ipaddress.IPv4Address(address))
Path(args.output).write_text(f'[web]\n{address}\n', encoding='utf-8')
print(f'Inventory written to {args.output}: {address}')

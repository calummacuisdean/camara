#!/usr/bin/env python
""" Camara disk wiping script.

This script is used for bulk drive erase in addition to wiping single disks in
individual machines."""

import datetime
import subprocess

class SystemInfo:
    """Placeholder for system settings and information."""


def call(cmd):
    return subprocess.check_output(cmd, shell=True)



if __name__ == '__main__':
    print 'Camara Education disk wiping tool'


    print(datetime.datetime.now())

    barcode = raw_input('Please enter barcode: ').upper()
    barcode = ''.join(c for c in barcode if c.isalnum())

    print(barcode)

    system_info = SystemInfo()

    system_info.nwipe_version = call('nwipe --version')
    print system_info.nwipe_version
    system_info.free_memory = int(call("free | grep -w 'Mem' | awk '{print $2}'"))/1024
    print system_info.free_memory
    system_info.memsys = call("lshw -C memory -short | grep 'System' | awk '{print $3}'")
    print system_info.memsys












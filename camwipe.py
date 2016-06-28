#!/usr/bin/env python
""" Camara disk wiping script.

This script is used for bulk drive erase in addition to wiping single disks in
individual machines."""

import datetime
import subprocess

class SystemInfo:
    """Placeholder for system settings and information."""

    def __str__(self):
        s = '===== System info\n'
        for name in dir(self):
            if name.startswith('_'):
                    continue
            s += '%s: %s\n' % (name, getattr(self, name))

        return s


def call(cmd):
    try:
        return subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        print 'Error running %r: %s' % (cmd, e)
        return ''


if __name__ == '__main__':
    print 'Camara Education disk wiping tool'


    print(datetime.datetime.now())

    barcode = raw_input('Please enter barcode: ').upper()
    barcode = ''.join(c for c in barcode if c.isalnum())

    print(barcode)

    system_info = SystemInfo()

    system_info.nwipe_version = call('nwipe --version')
    system_info.free_memory = int(call("free | grep -w 'Mem' | awk '{print $2}'"))/1024
    system_info.memsys = call("lshw -C memory -short | grep 'System' | awk '{print $3}'")

    print system_info


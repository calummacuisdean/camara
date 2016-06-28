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
    print system_info.memsys

    system_info.procspeed = call("cat /proc/cpuinfo | grep -m 1 -i 'cpu mhz' | awk '{print $4, $2}'")
    system_info.procname = call("cat /proc/cpuinfo | grep -m 1 -i 'model name' | cut -d : -f 2")

    system_info.system_manufacturer = call("dmidecode -s system-manufacturer")
    system_info.system_serial_number = call("dmidecode -s system-serial-number")
    system_info.system_product_name = call("dmidecode -s system-product-name")
    system_info.chassis_asset_tag = call("dmidecode -s chassis-asset-tag")
    system_info.baseboard_asset_tag = call("dmidecode -s baseboard-asset-tag")
    system_info.baseboard_serial_number = call("dmidecode -s baseboard-serial-number")
    system_info.chassis_serial_number = call("dmidecode -s chassis-serial-number")
    system_info.chassis_asset_tag = call("dmidecode -s chassis-asset-tag")
    system_info.chassis_type = call("dmidecode -s chassis-type")
    system_info.system_uuid = call("dmidecode -s system-uuid")
    system_info.system_version = call("dmidecode -s system-version")








    print system_info


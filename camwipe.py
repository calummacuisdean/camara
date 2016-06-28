#!/usr/bin/env python
""" Camara disk wiping script.

This script is used for bulk drive erase in addition to wiping single disks in
individual machines."""

import datetime

if __name__ == '__main__':
    print 'Camara Education disk wiping tool'

    print(datetime.datetime.now())

    barcode = raw_input('Please enter barcode: ').upper()
    barcode = ''.join(c for c in barcode if c.isalnum())

    print(barcode)








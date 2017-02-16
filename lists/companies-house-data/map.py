#!/usr/bin/env python3

import io
import sys
import csv
import re
import zipfile

h = re.compile(' - ')
sep = '\t'

fields = ['industrial-classification', 'name', 'count']

print(sep.join(fields))

values = {}

for path in sys.argv[1:]:
    z = zipfile.ZipFile(path)
    f = z.open(z.infolist()[0], 'r')

    for row in csv.DictReader(io.TextIOWrapper(io.BytesIO(f.read()))):
        for n in [1, 2, 3, 4]:
            key = 'SICCode.SicText_%s' % (n)
            value = row.get(key, '')
            if value not in values:
                values[value] = 1
            else:
                values[value] = values[value] + 1

    z.close()

for value in sorted(values):
    if value != '' and value != 'None Supplied':
        (code, name) = h.split(value, 2)
        count = str(values[value])
        print(sep.join([code, name, count]))

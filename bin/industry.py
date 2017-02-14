#!/usr/bin/env python3

import re
import sys
import csv

fields = ['industry', 'parent-industry', 'name', 'start-date', 'end-date']
sep = '\t'

section = ''

industry = {}


for path in sys.argv[1:]:
    for row in csv.DictReader(open(path), delimiter=sep):

        if len(row['industry']) == 1:
            section = row['industry']
            row['parent-industry'] = ''
        else:
            code = re.sub("\D", "", row['industry'])
            if len(code) == 2:
                row['parent-industry'] = section
            else:
                row['parent-industry'] = code[:-1]

            row['industry'] = code

            # expand abbreviations
            row['name'] = row['name'].replace('n.e.c.', 'not elsewhere classified')

        industry[row['industry']] = row


print(sep.join(fields))
for code in sorted(industry):
    row = industry[code]
    print(sep.join([row.get(field, '') for field in fields]))

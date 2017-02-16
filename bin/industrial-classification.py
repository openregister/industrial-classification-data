#!/usr/bin/env python3

import re
import sys
import csv

fields = ['industrial-classification', 'parent-industrial-classification', 'name', 'name-cy', 'start-date', 'end-date']
sep = '\t'

section = ''

industrial_classification = {}


for path in sys.argv[1:]:
    for row in csv.DictReader(open(path), delimiter=sep):

        if len(row['industrial-classification']) == 1:
            section = row['industrial-classification']
            row['parent-industrial-classification'] = ''
        else:
            code = re.sub("\D", "", row['industrial-classification'])
            if len(code) == 2:
                row['parent-industrial-classification'] = section
            else:
                row['parent-industrial-classification'] = code[:-1]

            row['industrial-classification'] = code

            # expand abbreviations
            row['name'] = row['name'].replace('n.e.c.', 'not elsewhere classified')

        industrial_classification[row['industrial-classification']] = row


print(sep.join(fields))
for code in sorted(industrial_classification):
    row = industrial_classification[code]
    print(sep.join([row.get(field, '') for field in fields]))

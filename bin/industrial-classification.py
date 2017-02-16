#!/usr/bin/env python3

import re
import sys
import csv

fields = ['industrial-classification', 'parent-industrial-classification', 'name', 'name-cy', 'start-date', 'end-date']
sep = '\t'

section = ''

industrial_classification = {}
parents = {}

# read lists from the command line
for path in sys.argv[1:]:
    for row in csv.DictReader(open(path), delimiter=sep):

        code = row['industrial-classification']

        # set section
        if len(code) == 1:
            section = code
            parent = ''
        else:
            # compress punctuation from the code
            code = re.sub("\D", "", row['industrial-classification'])

            # make codes match those of Companies House
            if len(code) == 4:
                code = code + '0'

            # deduce parent code
            if len(code) == 2:
                parent = section
            elif len(code) == 5:
                if code[-1] == '0':
                    parent = code[:-2]
                else:
                    parent = code[:-1] + '0'
            else:
                parent = code[:-1]

        row['parent-industrial-classification'] = parent
        row['industrial-classification'] = code

        # expand abbreviations
        row['name'] = row['name'].replace('n.e.c.', 'not elsewhere classified')

        industrial_classification[row['industrial-classification']] = row


print(sep.join(fields))
for code in sorted(industrial_classification):
    row = industrial_classification[code]

    parent = row['parent-industrial-classification']
    if parent and parent not in industrial_classification:
        row['parent-industrial-classification'] = ''

    print(sep.join([row.get(field, '') for field in fields]))

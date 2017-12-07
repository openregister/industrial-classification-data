
import re
import sys
import csv

fields = ['industrial-classification', 'parent-industrial-classification', 'name', 'start-date', 'end-date']
sep = '\t'

section = ''

codes = {}
parents = {}

# make punctuated codes match those of Companies House
def n7e(code):
    if len(code) == 1:
        return code

    # compress punctuation from the code
    code = re.sub("\D", "", code)

    if len(code) == 4:
        code = code + '0'

    return code


def parent_n7e(code, section):
    code = n7e(code)
    if len(code) == 1:
        return ''

    if len(code) == 2:
        return section

    if len(code) == 5:
        if code[-1] == '0':
            return code[:-2]
        else:
            return code[:-1] + '0'

    return code[:-1]


section = '*ERROR*'
# read lists from the command line
for row in csv.DictReader(open(sys.argv[1]), delimiter=sep):
    code = n7e(row['industrial-classification'])

    # assumes spreadsheet is ordered into sections ..
    if len(code) == 1:
        section = row['industrial-classification']

    row['parent-code'] = parent_n7e(code, section)

    # expand abbreviations in text ..
    row['name'] = row['name'].replace('n.e.c.', 'not elsewhere classified')

    codes[code] = row


print(sep.join(fields))
for code in sorted(codes):
    row = codes[code]

    if row['parent-code'] in codes:
        row['parent-industrial-classification'] = codes[row['parent-code']]['industrial-classification']

    print(sep.join([row.get(field, '') for field in fields]))

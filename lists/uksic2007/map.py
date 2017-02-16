#!/usr/bin/env python3

import sys
from xlrd import open_workbook

sep = '\t'
fields = ['industrial-classification', 'name']
print(sep.join(fields))

#
#  read spreadsheet
#
book = open_workbook(sys.argv[1])
sheet = book.sheet_by_index(0)

ncols = sheet.ncols
for r in range(2, sheet.nrows):
    cells = [sheet.cell(r, c).value for c in range(0, ncols) if sheet.cell(r, c) != '']

    line = sep.join(cells).strip()

    if line != '' and sep in line:
        print(line)

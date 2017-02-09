#!/usr/bin/env python3

import sys
import re
from xlrd import open_workbook

sep = '\t'
fields = ['industry', 'name']
print(sep.join(fields))

#
#  read spreadsheet
#
book = open_workbook(sys.argv[1])
sheet = book.sheet_by_index(0)

ncols = sheet.ncols
for r in range(2, sheet.nrows):
    cells = [sheet.cell(r, c).value for c in range(0, ncols) if sheet.cell(r, c) != '']

    line = '\t'.join(cells).strip()

    if line != '':
        print(line)

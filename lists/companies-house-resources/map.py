#!/usr/bin/env python3

import sys
from bs4 import BeautifulSoup

path = {
    'name': sys.argv[1],
    'name-cy': sys.argv[2]
}
rows = {}

for name in path:
    soup = BeautifulSoup(open(path[name]).read(), "html.parser")
    soup.prettify()

    for table in soup.select('#sic-codes'):
        for tr in table.findAll('tr'):
            td = tr.findAll('td')
            if td:
                code = td[0].text.strip()
                code = code.replace('Section', '').replace('ADRAN', '').strip()

                row = rows.get(code, {})
                row['industrial-classification'] = code
                row[name] = td[1].text.strip()
                rows[code] = row


sep='\t'
fields = ['industrial-classification', 'name', 'name-cy']
print(sep.join(fields))

for code in sorted(rows):
    row = rows[code]
    print(sep.join([row.get(field, '') for field in fields]))

# Condensed SIC lists published at http://resources.companieshouse.gov.uk/sic/

list.tsv: data.html data-cy.html map.py
	python3 map.py data.html data-cy.html > $@

data.html:
	curl -sL 'http://resources.companieshouse.gov.uk/sic/' > $@

data-cy.html:
	curl -sL 'http://resources.companieshouse.gov.uk/welsh/sic/' > $@

init:
	pip install -r requirements.txt

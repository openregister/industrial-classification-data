# see https://www.ons.gov.uk/methodology/classificationsandstandards/ukstandardindustrialclassificationofeconomicactivities/uksic2007
XLS=http://www.ons.gov.uk/ons/guide-method/classifications/current-standard-classifications/standard-industrial-classification/sic-2007-summary-of-structure.xls

list.tsv:	data.xls map.py
	python3 map.py data.xls > $@

data.xls:
	curl -qsL $(XLS) > $@

clean::; rm -f data.xls list.tsv

init:
	pip install -r requirements.txt

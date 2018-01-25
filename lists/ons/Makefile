# see https://www.ons.gov.uk/methodology/classificationsandstandards/ukstandardindustrialclassificationofeconomicactivities/uksic2007
sic2007=http://www.ons.gov.uk/ons/guide-method/classifications/current-standard-classifications/standard-industrial-classification/sic-2007-summary-of-structure.xls
sic2003=http://www.ons.gov.uk/ons/guide-method/classifications/archived-standard-classifications/uk-standard-industrial-classification-1992--sic92-/uk-sic-2003-index.pdf

sic2007.xls:
	curl -qsL $(sic2007) > $@

sic2003.pdf:
	curl -qsL $(sic2003) > $@

clean::; rm -f sic2007.xls sic2003.pdf

init:
	pip install -r requirements.txt

LISTS=\
	lists/uksic2007/list.tsv \
	lists/companies-house-resources/list.tsv

data/industrial-classification/industrial-classification.tsv:	bin/industrial-classification.py $(LISTS)
	mkdir -p data/industrial-classification
	python3 bin/industrial-classification.py $(LISTS) > $@

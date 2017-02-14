LISTS=\
	lists/uksic2007/list.tsv \
	lists/companies-house-resources/list.tsv

data/industry/industry.tsv:	bin/industry.py $(LISTS)
	mkdir -p data/industry
	python3 bin/industry.py $(LISTS) > $@

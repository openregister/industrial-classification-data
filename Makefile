data/industry/industry.tsv:	bin/industry.py lists/sic2007/list.tsv
	mkdir -p data/industry
	python3 bin/industry.py < lists/sic2007/list.tsv > $@

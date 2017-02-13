#
#  Industry codes found in Companies House data
#
#  http://download.companieshouse.gov.uk/en_output.html
#
#  uses csvcut, part of csvkit http://csvkit.readthedocs.io/en/1.0.1/
#
DATE=2017-02-03
URL_PREFIX=http://download.companieshouse.gov.uk/BasicCompanyData-$(DATE)-part
URL_SUFFIX=_5.zip

PARTS=\
	cache/part1.zip\
	cache/part2.zip\
	cache/part3.zip\
	cache/part4.zip\
	cache/part5.zip

.PHONY: all flake8 prune out

all:	list.tsv

list.tsv:	$(PARTS) map.py
	./map.py $(PARTS) > $@


#
#  download data
#
cache/part1.zip:;	mkdir -p cache && curl -Ls "$(URL_PREFIX)1$(URL_SUFFIX)" > $@
cache/part2.zip:;	mkdir -p cache && curl -Ls "$(URL_PREFIX)2$(URL_SUFFIX)" > $@
cache/part3.zip:;	mkdir -p cache && curl -Ls "$(URL_PREFIX)3$(URL_SUFFIX)" > $@
cache/part4.zip:;	mkdir -p cache && curl -Ls "$(URL_PREFIX)4$(URL_SUFFIX)" > $@
cache/part5.zip:;	mkdir -p cache && curl -Ls "$(URL_PREFIX)5$(URL_SUFFIX)" > $@

#
#  clean
#
prune::
	rm -rf cache data

clean::
	rm -rf $(REGISTERS) $(COUNTRIES) data

#
#  python
#
init::
	pip3 install --upgrade -r requirements.txt

flake8::
	flake8 bin

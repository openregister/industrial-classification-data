# Industry register data

[Source data](data/industry/industry.tsv) for the proposed [industry register](http://industry.openregister.org), a list of standard industrial classification of economic activities (SIC 2007) codes
managed by [Office for National Statistics (ONS)](https://www.ons.gov.uk/) and used by [Companies House](https://www.gov.uk/government/organisations/companies-house)
as a part of the registration as the company's "nature of business".

Companies House bulk data includes up to four SIC values for each company.

The text for each code is presented by the [Companies House beta service](https://beta.companieshouse.gov.uk)
expanding abbreviations such as "n.e.c." to "not elsewhere classified".

## Source data

| List | Source |
| :---         |    :--- |
|[uksic2007](lists/uksic2007)|[ONS UK SIC 2007](https://www.ons.gov.uk/methodology/classificationsandstandards/ukstandardindustrialclassificationofeconomicactivities/uksic2007)|
|companies-house-govuk|[Companies House guidance on GOV.UK (PDF)](https://www.gov.uk/government/publications/standard-industrial-classification-of-economic-activities-sic)|
|[companies-house-data](lists/companies-house-data)|Codes used in [Companies House bulk data](http://download.companieshouse.gov.uk/en_output.html)|
|[companies-house-resources](lists/companies-house-resources)|[Companies House resources page](http://resources.companieshouse.gov.uk/sic/)|

## Fields

- industry — the Standard Industry Code (SIC)
- parent-industry — the parent Standard Industry Code (SIC)
- [name](http://field.alpha.openregister.org/field/name) — the name of the industry, in English
- [start-date](http://field.alpha.openregister.org/field/start-date) — date from which the code applied (optional)
- [end-date](http://field.alpha.openregister.org/field/end-date) — date after which the code no longer applies

## Hierarchy

The codes are hierarchical, divided into tiers:
* Section "A"
* Division "05"
* Group "05.1"
* Class "05.10"
* Code "05101"

The hierarchy has been modelled in the register using the parent-industry field as a link from the code to its class, from the class to its group, etc.

The complete hierarchy is included in the register, although a service should encourage users to record the finest (lowest-level) code as possible.

# Licence

The software in this project is covered by LICENSE file.

The register data is [© Crown copyright](http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/copyright-and-re-use/crown-copyright/)
and available under the terms of the [Open Government 3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) licence.

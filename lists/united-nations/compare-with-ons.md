Comparison of UN lists with ONS
================
Tue Feb 20 17:16:35 2018

First big difference: UN hierarchy is only four levels deep, whereas ONS
is five levels deep.

``` r
library(tidyverse)
library(Hmisc) # for mdb.get(). You must have mdb-tools installed on your system
library(here)

rev4un_path <- here("lists", "united-nations", "ISIC4_english.mdb")

rev4un <-
  mdb.get(rev4un_path, "tblTitles_English_ISICRev4") %>%
  as_tibble()

rev4ons_path <- here("data", "industrial-classification-2007.tsv")
rev4ons <- read_tsv(rev4ons_path)
```

    ## Parsed with column specification:
    ## cols(
    ##   `industrial-classification-2007` = col_character(),
    ##   name = col_character(),
    ##   parent = col_character(),
    ##   `start-date` = col_character(),
    ##   `end-date` = col_character()
    ## )

``` r
anti_join(rev4ons, rev4un, by = c("industrial-classification-2007" = "Code"))
```

    ## Warning: Column `industrial-classification-2007`/`Code` joining character
    ## vector and factor, coercing into character vector

    ## # A tibble: 1,079 x 5
    ##    `industrial-classification… name       parent   `start-date` `end-date`
    ##    <chr>                       <chr>      <chr>    <chr>        <chr>     
    ##  1 This division includes the… <NA>       industr… <NA>         <NA>      
    ##  2 99.00                       Activitie… industr… <NA>         <NA>      
    ##  3 99.0                        Activitie… industr… <NA>         <NA>      
    ##  4 98.20                       Undiffere… industr… <NA>         <NA>      
    ##  5 98.2                        Undiffere… industr… <NA>         <NA>      
    ##  6 98.10                       Undiffere… industr… <NA>         <NA>      
    ##  7 98.1                        Undiffere… industr… <NA>         <NA>      
    ##  8 97.00                       Activitie… industr… <NA>         <NA>      
    ##  9 97.0                        Activitie… industr… <NA>         <NA>      
    ## 10 96.09                       Other per… industr… <NA>         <NA>      
    ## # ... with 1,069 more rows

``` r
anti_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007"))
```

    ## Warning: Column `Code`/`industrial-classification-2007` joining factor and
    ## character vector, coercing into character vector

    ## # A tibble: 657 x 5
    ##    Sortorder Code  Description  ExplanatoryNoteInclusion ExplanatoryNoteE…
    ##        <int> <fct> <fct>        <fct>                    <fct>            
    ##  1        40 011   Growing of … This group includes the… ""               
    ##  2        50 0111  Growing of … "This class includes al… "This class excl…
    ##  3        60 0112  Growing of … "This class includes:\n… ""               
    ##  4        70 0113  Growing of … "This class includes:\n… "This class excl…
    ##  5        80 0114  Growing of … "This class includes:\n… "This class excl…
    ##  6        90 0115  Growing of … "This class includes:\n… ""               
    ##  7       110 0116  Growing of … "This class includes:\n… ""               
    ##  8       130 0119  Growing of … "This class includes th… "This class excl…
    ##  9       140 012   Growing of … This group includes the… ""               
    ## 10       150 0121  Growing of … "This class includes:\n… "This class excl…
    ## # ... with 647 more rows

``` r
inner_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007")) %>%
  select(Code, ons_name = name, un_name = Description)
```

    ## Warning: Column `Code`/`industrial-classification-2007` joining factor and
    ## character vector, coercing into character vector

    ## # A tibble: 109 x 3
    ##    Code  ons_name                          un_name                        
    ##    <chr> <chr>                             <fct>                          
    ##  1 A     Agriculture, forestry and fishing Agriculture, forestry and fish…
    ##  2 01    Crop and animal production, hunt… Crop and animal production, hu…
    ##  3 02    Forestry and logging              Forestry and logging           
    ##  4 03    Fishing and aquaculture           Fishing and aquaculture        
    ##  5 B     Mining and quarrying              Mining and quarrying           
    ##  6 05    Mining of coal and lignite        Mining of coal and lignite     
    ##  7 06    Extraction of crude petroleum an… Extraction of crude petroleum …
    ##  8 07    Mining of metal ores              Mining of metal ores           
    ##  9 08    Other mining and quarrying        Other mining and quarrying     
    ## 10 09    Mining support service activities Mining support service activit…
    ## # ... with 99 more rows

``` r
inner_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007")) %>%
  select(Code, ons_name = name, un_name = Description) %>%
  filter(ons_name != un_name)
```

    ## Warning: Column `Code`/`industrial-classification-2007` joining factor and
    ## character vector, coercing into character vector

    ## # A tibble: 9 x 3
    ##   Code  ons_name                          un_name                         
    ##   <chr> <chr>                             <fct>                           
    ## 1 22    Manufacture of rubber and plasti… Manufacture of rubber and plast…
    ## 2 39    Remediation activities and other… Remediation activities and othe…
    ## 3 43    Specialised construction activit… Specialized construction activi…
    ## 4 66    Activities auxiliary to financia… Activities auxiliary to financi…
    ## 5 79    Travel agency, tour operator and… Travel agency, tour operator, r…
    ## 6 94    Activities of membership organis… Activities of membership organi…
    ## 7 T     Activities of households as empl… Activities of households as emp…
    ## 8 U     Activities of extraterritorial o… Activities of extraterritorial …
    ## 9 99    Activities of extraterritorial o… Activities of extraterritorial …

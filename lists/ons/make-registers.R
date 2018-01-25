# Convert the 2003 pdf and 2007 xls into registers

library(tidyverse)
library(readxl)
library(tabulizer)
library(here)

source2003 <- here("lists", "ons", "sic2003.pdf")
source2007 <- here("lists", "ons", "sic2007.xls")

n_pages <- get_n_pages(source2003)

# Specifgy `pages` so that each page is in a separate element of a vector
source_text <- extract_text(source2003, pages = seq_len(n_pages))

tabulize <- function(x) {
  x %>%
  read_lines(skip = 4) %>%
  str_replace("^ +", "NA NA ") %>% # When col 3 wraps into the next line
  str_split_fixed(" +", 3) %>%
  as_tibble()
}

alphabetic <-
  source_text %>%
  .[2:236] %>%
  map_df(tabulize) %>%
  set_names("SIC2003", "SIC80", "Activity")

# TODO: scrape the numeric index too and compare

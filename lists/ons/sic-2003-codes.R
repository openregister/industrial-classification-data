# Convert the 2003 pdf and 2007 xls into registers

library(tidyverse)
library(readxl)
library(tabulizer)
library(here)

source_all_2003 <- here("lists", "ons", "uk-sic-2003.pdf")

n_pages <- get_n_pages(source_all_2003)

# Specifgy `pages` so that each page is in a separate element of a vector
source_text_all_2003 <- extract_text(source_all_2003, pages = seq_len(n_pages))

filter_codes <- function(x) {
  read_lines(x) %>%
    .[str_which(., "^Section [A-Z]|^[0-9]{2}.+[A-Z]")]
}

all_sic_2003 <-
  map(source_text_all_2003[27:52], filter_codes) %>%
  unlist() %>%
  str_replace("^Section ([A-Z])", "\\1") %>%
  str_split_fixed(" +", 2) %>%
  as_tibble() %>%
  set_names("sic2003", "name") %>%
  mutate(level = case_when(str_detect(sic2003, "^[0-9]{2}\\.[0-9]{1,2}/[0-9]$") ~ 3,
                           str_detect(sic2003, "^[0-9]{2}\\.[0-9]{1,2}$") ~ 2,
                           str_detect(sic2003, "^[0-9]{2}$") ~ 1,
                           str_detect(sic2003, "^[A-Z]$") ~ 0,
                           TRUE ~ NA_real_)) %>%
  # compute the parent of each code
  mutate(top_level = if_else(level == 0, sic2003, NA_character_)) %>%
  fill(top_level) %>%
  mutate(parent = case_when(level == 3 ~ str_sub(sic2003, 1L, str_locate(sic2003, "/")[, 1] -1L),
                            level == 2 ~ str_sub(sic2003, 1L, str_locate(sic2003, "\\.")[, 1] -1L),
                            level == 1 ~ top_level,
                            TRUE ~ NA_character_)) %>%
  select(sic2003, name, parent, level)

# Checks
filter(all_sic_2003, is.na(parent))
filter(all_sic_2003, str_detect(parent, "[A-Z]")) %>% print(n = Inf)
filter(all_sic_2003, !is.na(parent)) %>%
  anti_join(all_sic_2003, by = c("parent" = "sic2003")) # check that all parents exist

# Compare with sic2003 from the script "make-registers.R"
sic2003b <-
  all_sic_2003 %>%
  filter(level %in% 2:3) %>%
  mutate(sic2003 = normalize_sic2003(sic2003))

anti_join(sic2003b, sic2003)
anti_join(sic2003, sic2003b)

# Write

all_sic_2003 %>%
  rename(`industrial-classification-2003` = sic2003,
         `parent-industrial-classification` = parent) %>%
  select(-level) %>%
  mutate(`start-date` = NA,
         `end-date` = NA) %>%
  write_tsv(here("data", "industrial-classification-2003.tsv"), na = "")

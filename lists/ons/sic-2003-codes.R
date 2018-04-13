# Convert the 2003 pdf and 2007 xls into registers

library(tidyverse)
library(readxl)
library(tabulizer)
library(here)

source_all_2003 <- here("lists", "ons", "uk-sic-2003.pdf")

n_pages <- get_n_pages(source_all_2003)

# Specify `pages` so that each page is in a separate element of a vector
source_text_all_2003 <- extract_text(source_all_2003, pages = seq_len(n_pages))

filter_codes <- function(x) {
  read_lines(x) %>%
    .[str_which(., "^Section [A-Z]|^Subsection [A-Z]{2}|^[0-9]{2}.+[A-Z]")]
}

all_sic_2003 <-
  map(source_text_all_2003[27:52], filter_codes) %>%
  unlist() %>%
  str_replace("^Section ([A-Z])", "\\1") %>%
  str_replace("^Subsection ([A-Z]{2})", "\\1") %>%
  str_split_fixed(" +", 2) %>%
  as_tibble() %>%
  set_names("sic2003", "name") %>%
  mutate(level = case_when(str_detect(sic2003, "^[0-9]{2}\\.[0-9]{1,2}/[0-9]$") ~ 4,
                           str_detect(sic2003, "^[0-9]{2}\\.[0-9]{1,2}$") ~ 3,
                           str_detect(sic2003, "^[0-9]{2}$") ~ 2,
                           str_detect(sic2003, "^[A-Z]{2}$") ~ 1,
                           str_detect(sic2003, "^[A-Z]{1}$") ~ 0,
                           TRUE ~ NA_real_)) %>%
  # compute the parent of each code
  mutate(top_level = if_else(level == 0, sic2003, NA_character_)) %>%
  fill(top_level) %>%
  mutate(mezzanine_level = if_else(level == 1, sic2003, NA_character_)) %>%
  fill(mezzanine_level) %>%
  mutate(mezzanine_level = if_else(str_sub(mezzanine_level, 1L, 1L) == top_level,
                                   mezzanine_level,
                                   top_level)) %>%
  mutate(mezzanine_level = if_else(is.na(mezzanine_level),
                                   top_level,
                                   mezzanine_level)) %>%
  mutate(parent = case_when(level == 4 ~ str_sub(sic2003, 1L, str_locate(sic2003, "/")[, 1] -1L),
                            level == 3 ~ str_sub(sic2003, 1L, str_locate(sic2003, "\\.")[, 1] -1L),
                            level == 2 ~ mezzanine_level,
                            level == 1 ~ top_level,
                            TRUE ~ NA_character_)) %>%
  select(top_level, mezzanine_level, sic2003, name, parent, level) %>%
  mutate(top_level = if_else(top_level == sic2003, "", top_level),
         top_level = if_else(is.na(mezzanine_level), top_level, ""),
         mezzanine_level = if_else(mezzanine_level == sic2003, "", mezzanine_level),
         full_code = pmap_chr(list(top_level, mezzanine_level, sic2003),
                              paste0)) %>%
  select(sic2003, name, parent, level, full_code)

# Checks
filter(all_sic_2003, is.na(parent))
filter(all_sic_2003, str_detect(parent, "[A-Z]{1}")) %>% print(n = Inf)
filter(all_sic_2003, str_detect(parent, "[A-Z]{2}")) %>% print(n = Inf)
filter(all_sic_2003, !is.na(parent)) %>%
  anti_join(all_sic_2003, by = c("parent" = "sic2003")) # check that all parents exist

# Compare with sic2003 from the script "sic-2003-indices.R"
sic2003b <-
  all_sic_2003 %>%
  filter(level %in% 3:4) %>%
  mutate(sic2003 = normalize_sic2003(sic2003))

anti_join(sic2003b, sic2003)
anti_join(sic2003, sic2003b)

# Spell out the full codes all the way up the hierarchy
full_codes <-
  all_sic_2003 %>%
  select(parent = sic2003, full_parent_code = full_code) %>%
  left_join(all_sic_2003, ., by = "parent") %>%
  select(sic2003 = full_code, name, parent = full_parent_code, level)

# Write

full_codes %>%
  mutate(parent = if_else(is.na(parent),
                          parent,
                          paste0("industrial-classification-2003:", parent))) %>%
  rename(`industrial-classification-2003` = sic2003) %>%
  select(-level) %>%
  mutate(`start-date` = NA,
         `end-date` = NA) %>%
  arrange(desc(`industrial-classification-2003`)) %>%
  write_tsv(here("data", "industrial-classification-2003.tsv"), na = "")

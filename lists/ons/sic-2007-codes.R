library(tidyverse)
library(readxl)
library(unpivotr)
library(here)

path <- here("lists", "ons", "sic2007.xls")

get_parent <- function(x) {
  x$parent <- x[[as.character(x$parent_col)]]
  x
}

to_sentence_case <- function(x) {
  paste0(toupper(str_sub(x, 1L, 1L)),
         tolower(str_sub(x, 2L)))
}

sic2007 <-
  read_excel(path, skip = 3, col_names = FALSE) %>%
  tidy_table() %>%
  filter(!is.na(chr)) %>%
  group_by(row) %>%
  arrange(row, col) %>%
  summarise(first_col = first(col), code = chr[1], name = chr[2]) %>%
  mutate(first_col = as.integer(first_col - (first_col %/% 2))) %>%
  mutate(code2 = code, parent_col = first_col - 1L) %>%
  spread(first_col, code2) %>%
  fill(`1`, `2`, `3`, `4`, `5`) %>%
  group_by(row) %>%
  do(get_parent(.)) %>%
  ungroup() %>%
  select(code, name, parent) %>%
  # Convert allcaps to sentence case
  mutate(name = if_else(!str_detect(name, "[a-z]"),
                        to_sentence_case(name),
                        name),
         parent = if_else(is.na(parent),
                          parent,
                          paste0("industrial-classification-2007:", parent))) %>%
  rename(`industrial-classification-2007` = code) %>%
  mutate(`start-date` = NA,
         `end-date` = NA)

write_tsv(sic2007, here("data", "industrial-classification-2007.tsv"), na = "")

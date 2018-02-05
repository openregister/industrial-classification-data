library(tidyverse)
library(readxl)
library(here)

path <- here("lists", "ons",
             "correlationbetweensic2003tosic2007_tcm77-232024.xls")

sic2003 <- read_tsv(here("data", "industrial-classification-2003.tsv"))
sic2007 <- read_tsv(here("data", "industrial-classification-2007.tsv"))

`%na%` <- function(x, y) {
  if (is.na(x)) {
    y
  } else {
    x
  }
}

normalize_code <- function(x) {
  level1 <- str_sub(x, 1L, 2L)
  level2 <- str_sub(x, 3L, 4L)
  level3 <- str_sub(x, 5L, 5L)
  has_level_2 <- (as.integer(level2) > 0) %na% FALSE
  has_level_3 <- (as.integer(level3) > 0) %na% FALSE
  out <- level1
  if (has_level_2) { out <- paste0(out, ".", level2) }
  if (has_level_3) out <- paste0(out, "/", level3)
  out
}

maps <-
  read_excel(path) %>%
  set_names("sic2003", "sic2003activity", "sic2007", "sic2007activity") %>%
  mutate(sic2003 = map_chr(sic2003, normalize_code),
         sic2007 = map_chr(sic2007, normalize_code),
         sic2003activity = str_replace_all(sic2003activity, " +", " "),
         sic2007activity = str_replace_all(sic2007activity, " +", " "))

# All the codes in the maps are present in the classifications
anti_join(maps, sic2003, by = c("sic2003" = "industrial-classification-2003"))
anti_join(maps, sic2007, by = c("sic2007" = "industrial-classification-2007"))

# But not all the classifications are present in the maps
anti_join(sic2003, maps, by = c("industrial-classification-2003" = "sic2003"))
anti_join(sic2007, maps, by = c("industrial-classification-2007" = "sic2007"))

# Some that are present are spelled differently
maps %>%
  inner_join(sic2007, by = c("sic2007" = "industrial-classification-2007")) %>%
  filter(sic2007activity != name) %>%
  select(sic2007, sic2007activity, name)
maps %>%
  inner_join(sic2003, by = c("sic2003" = "industrial-classification-2003")) %>%
  filter(sic2003activity != name) %>%
  select(sic2003, sic2003activity, name)

# Some inconsistenciees: "other" vs "not elsewhere classified" vs "n.e.c"

# Write the maps as a register
maps %>%
  mutate(id = row_number(),
         sic2003 = paste0("industrial-classification-2003:", sic2003),
         sic2007 = paste0("industrial-classification-2007:", sic2007)) %>%
  select(id, sic2003, sic2007) %>%
  set_names(c("industrial-classification-correlation",
              "source-industrial-classification",
              "target-industrial-classification")) %>%
  mutate(`start-date` = NA,
         `end-date` = NA) %>%
  write_tsv(here("data", "industrial-classification-correlation.tsv"), na = "")

# TODO: compare spellings in more depth

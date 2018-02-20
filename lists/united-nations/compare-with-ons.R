#' ---
#' title: Comparison of UN lists with ONS
#' output: github_document
#' author: ''
#' ---

#' First big difference: UN hierarchy is only four levels deep, whereas ONS is
#' five levels deep.

library(tidyverse)
library(Hmisc) # for mdb.get(). You must have mdb-tools installed on your system
library(here)

rev4un_path <- here("lists", "united-nations", "ISIC4_english.mdb")

rev4un <-
  mdb.get(rev4un_path, "tblTitles_English_ISICRev4") %>%
  as_tibble()

rev4ons_path <- here("data", "industrial-classification-2007.tsv")
rev4ons <- read_tsv(rev4ons_path)

anti_join(rev4ons, rev4un, by = c("industrial-classification-2007" = "Code"))
anti_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007"))

inner_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007")) %>%
  select(Code, ons_name = name, un_name = Description)

inner_join(rev4un, rev4ons, by = c("Code" = "industrial-classification-2007")) %>%
  select(Code, ons_name = name, un_name = Description) %>%
  filter(ons_name != un_name)

# TODO: compare spellings in more depth.  A few hundred potential correlations
# are missed because they are written differently in each set, e.g.

# # A tibble: 195 x 3
#    sic2007 sic2007activity                                          name
#    <chr>   <chr>                                                    <chr>
#  1 01.25   Growing of other tree and bush fruit and nuts            Growing of other tree and bush fruits and nuts
#  2 01.62/9 Other support activities for animal production           Support activities for animal production (other than farm animal boarding and care) n.e.c.
#  3 02.10   "Silviculture and other forestry\nactivities"            Silviculture and other forestry activities
#  4 05.10/1 Deep coal mines                                          Mining of hard coal from deep coal mines (underground mining)
#  5 05.10/2 Open cast coal working                                   Mining of hard coal from open cast coal working (surface mining)
#  6 08.91   Mining of chemical and fertilizer minerals               Mining of chemical and fertiliser minerals
#  7 09.10   Support activities for petroleum and natural gas mining  Support activities for petroleum and natural gas extraction
#  8 09.10   Support activities for petroleum and natural gas mining  Support activities for petroleum and natural gas extraction
#  9 10.39   Processing and preserving of fruit and vegetables n.e.c. Other processing and preserving of fruit and vegetables
# 10 10.51/9 Manufacture of other milk products                       Manufacture of milk products (other than liquid milk and cream, butter, cheese) n.e.c.
# # ... with 185 more rows

# # A tibble: 1,301 x 4
#    sic2003 sic2003activity                                                        sic2007 sic2007activity
#    <chr>   <chr>                                                                  <chr>   <chr>
#  1 A01.11  Growing of cereals and other crops n.e.c.                              A01.11  Growing of cereals (except rice), leguminous crops and oil seeds
#  2 A01.12  Growing of vegetables, horticultural specialities and nursery products A01.11  Growing of cereals (except rice), leguminous crops and oil seeds
#  3 A01.11  Growing of cereals and other crops n.e.c.                              A01.12  Growing of rice
#  4 A01.11  Growing of cereals and other crops n.e.c.                              A01.13  Growing of vegetables and melons, roots and tubers
#  5 A01.12  Growing of vegetables, horticultural specialities and nursery products A01.13  Growing of vegetables and melons, roots and tubers
#  6 A01.11  Growing of cereals and other crops n.e.c.                              A01.14  Growing of sugar cane
#  7 A01.11  Growing of cereals and other crops n.e.c.                              A01.15  Growing of tobacco
#  8 A01.11  Growing of cereals and other crops n.e.c.                              A01.16  Growing of fibre crops
#  9 A01.11  Growing of cereals and other crops n.e.c.                              A01.19  Growing of other non-perennial crops
# 10 A01.12  Growing of vegetables, horticultural specialities and nursery products A01.19  Growing of other non-perennial crops

library(tidyverse)
library(readxl)
library(here)

path <- here("lists", "ons",
             "sicCorrelation2003to2007.xls")

sic2003 <-
  read_tsv(here("data", "industrial-classification-2003.tsv")) %>%
  mutate(full_code = `industrial-classification-2003`,
         `industrial-classification-2003` = str_replace(full_code,
                                                        "^[A-Z]{1,2}",
                                                        ""))

sic2007 <-
  read_tsv(here("data", "industrial-classification-2007.tsv")) %>%
  mutate(full_code = `industrial-classification-2007`,
         `industrial-classification-2007` = str_replace(full_code,
                                                        "^[A-Z]{1,2}",
                                                        ""))

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
  # Get the full 2003 codes back
  left_join(select(sic2003,
                   `industrial-classification-2003`,
                   full_code),
            by = c("sic2003" = "industrial-classification-2003")) %>%
  mutate(sic2003 = full_code) %>%
  select(-full_code) %>%
  left_join(select(sic2007,
                   `industrial-classification-2007`,
                   full_code),
            by = c("sic2007" = "industrial-classification-2007")) %>%
  mutate(sic2007 = full_code) %>%
  select(-full_code) %>%
  mutate(id = row_number(),
         sic2003 = paste0("industrial-classification-2003:", sic2003),
         sic2007 = paste0("industrial-classification-2007:", sic2007)) %>%
  select(id, sic2003, sic2007) %>%
  set_names(c("industrial-classification-correlation",
              "source",
              "target")) %>%
  mutate(`start-date` = NA,
         `end-date` = NA) %>%
  arrange(desc(`industrial-classification-correlation`)) %>%
  write_tsv(here("data", "industrial-classification-correlation.tsv"), na = "")


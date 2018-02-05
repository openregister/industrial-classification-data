# Convert the 2003 pdf and 2007 xls into registers

# TODO: check for "This code is no longer in use"

library(tidyverse)
library(readxl)
library(tabulizer)
library(here)

source2003 <- here("lists", "ons", "sic2003.pdf")
source2007 <- here("lists", "ons", "sic2007.xls")

n_pages <- get_n_pages(source2003)

# Specifgy `pages` so that each page is in a separate element of a vector
source_text <- extract_text(source2003, pages = seq_len(n_pages))

tabulize <- function(x, n_col) {
  if (!(n_col %in% 2:3)) {
    stop("n_col must be 2 or 3")
  }
  out <-
    x %>%
    str_replace_all("\n` +", "\n") %>% # Stray backtick
    str_replace_all("\n +(?=[0-9])", "\n") %>% # Stray leading space in 3221 Metal forming machine
    str_replace_all("-\n(?=[^0-9]) *", "-") %>% # When final col wraps with a hypen into the next line
    str_replace_all("\n(?=[^0-9]) *-", "-") %>% # When final col wraps into the next line with a hyphen
    str_replace_all("\n(?=[^0-9]) *", " ") %>% # When final col wraps into the next line
    read_lines() %>%
    str_split_fixed(" +", 2) %>%
    as_tibble()
  if (n_col == 3) {
    # Remove a stray space from within a sic80 field value "316 1" becomes
    # "3161"
    out <-
      out %>%
      mutate(V2 = str_replace(V2, "(?<=[0-9]{1,4}) (?=[0-9]+)", "")) %>%
      separate(V2, c("V2", "V3"), extra = "merge")
  }
  out
}

normalize_sic2003 <- function(x) {
  if (str_length(x) == 5L || !str_detect(x, "/")) {
    return(x)
  }
  slash_pos <- str_locate(x, "/")[1]
  y <- as.numeric(str_sub(x, 1L, slash_pos - 1L))
  z <- str_sub(x, slash_pos)
  paste0(sprintf("%02.2f", y), z)
}

alphabetic <-
  source_text %>%
  .[2:236] %>%
  map_chr(str_replace, "(.*\n){4}", "") %>%
  paste(collapse = "") %>%
  tabulize(n_col = 3) %>%
  set_names("sic2003", "sic80", "activity") %>%
  mutate(activity = str_trim(activity),
         activity = str_replace(activity, "Household utensils made of meta \\(manufacture\\)l", "Household utensils made of metal (manufacture)"), # spelling
         activity = str_replace(activity, " manufacture\\)", ""), # missing open-parenthesis
         activity = str_replace(activity, "(\\ \\([^\\)]*\\))+$", ""), # remove brackets, e.g. "Wool (fellmongery) (manufacture)"
         activity = str_replace(activity, " {2,}", " "), # double spaces
         activity = str_replace(activity, "\\.{2,}", "\\."), # double dots
         activity = str_replace(activity, "\\?", ""), # stray question mark
         activity = str_replace(activity, "\u0092", "'"), # curly quote
         activity = str_replace(activity, "ized", "ised"), # spelling
         activity = str_replace(activity, "Moblie telephones", "Mobile telephones"), # spelling
         activity = str_replace(activity, "Blacksmiths(?=[^'])", "Blacksmiths'"), # spelling
         activity = str_replace(activity, " \\.", ""), # stray space and full point
         activity = str_trim(activity)) %>% # again, to be sure
  filter(sic80 != "****") %>%
  mutate(sic80 = str_replace_all(sic80, " ", ""), # stray space
         sic80 = sprintf("%04i", as.integer(sic80)),
         sic2003 = map_chr(sic2003, normalize_sic2003))

numerical <-
  source_text %>%
  .[-1:-236] %>%
  map_chr(str_replace, "(.*\n){4}", "") %>%
  paste(collapse = "") %>%
  tabulize(n_col = 2) %>%
  set_names(c("code", "activity")) %>%
  mutate(activity = str_trim(activity),
         activity = str_replace(activity, "Household utensils made of meta \\(manufacture\\)l", "Household utensils made of metal (manufacture)"), # spelling
         activity = str_replace(activity, " manufacture\\)", ""), # missing open-parenthesis
         activity = str_replace(activity, "(\\ \\([^\\)]*\\))+$", ""), # remove brackets, e.g. "Wool (fellmongery) (manufacture)"
         activity = str_replace(activity, " {2,}", " "), # double spaces
         activity = str_replace(activity, "\\.{2,}", "\\."), # double dots
         activity = str_replace(activity, "\\?", ""), # stray question mark
         activity = str_replace(activity, "\u0092", "'"), # curly quote
         activity = str_replace(activity, "ized", "ised"), # spelling
         activity = str_replace(activity, "Moblie telephones", "Mobile telephones"), # spelling
         activity = str_replace(activity, "Blacksmiths(?=[^'])", "Blacksmiths'"), # spelling
         activity = str_replace(activity, " \\.", ""), # stray space and full point
         activity = str_trim(activity), # again, to be sure
         code = if_else(activity == "Installation of medical and surgical equipment and apparatus",
                        "3720", code),
         header = str_detect(code, "\\."),
         group = cumsum(header)) %>%
  group_by(group) %>%
  mutate(group_name = first(code)) %>%
  ungroup() %>%
  mutate(parent = if_else(header, str_sub(group_name, 1L, 2L), group_name)) %>%
  select(code, activity, parent, header) %>%
  filter(code != "****") %>%
  mutate(code = str_replace_all(code, " ", "")) # stray space

sic2003 <-
  numerical %>%
  filter(header) %>%
  rename(sic2003 = code) %>%
  # mutate(sic2003 = normalize_sic2003(sic2003)) %>%
  select(sic2003, activity)

sic80 <-
  numerical %>%
  filter(!header) %>%
  rename(sic80 = code, sic2003 = parent) %>%
  mutate(sic2003 = map_chr(sic2003, normalize_sic2003)) %>%
  select(sic2003, sic80, activity) %>%
  mutate(sic80 = sprintf("%04i", as.integer(sic80)))

# Compare the alphabetic and numerical versions.  Not bad.
anti_join(alphabetic, sic80) %>% distinct %>% print(n = Inf) %>% write_tsv(here("lists", "ons", "2003-bad-records-1.tsv"))
anti_join(sic80, alphabetic) %>% distinct %>% print(n = Inf) %>% write_tsv(here("lists", "ons", "2003-bad-records-2.tsv"))

filter(sic80, str_detect(activity, "Undifferentiated"))
filter(alphabetic, str_detect(activity, "Undifferentiated"))

# Is "Stall sales" really missing?  No, its code has been messed up, and I don't
# know what it ought to be.  The given code is "64 -5" in both places.
filter(sic80, str_detect(activity, "Stall sales"))
filter(alphabetic, str_detect(activity, "Stall sales"))

# Is "YMCA" really missing?  No, it has been misspelled
filter(sic80, str_detect(activity, "YMCA"))
filter(alphabetic, str_detect(activity, "YM A"))

# Is "Overall planning, structuring ..." really missing?  No, but it has a
# probable typo: its sic80 code should be 8395 rather than 8394
filter(alphabetic, str_detect(activity, "Overall planning, structuring"))
filter(sic80, str_detect(activity, "Overall planning, structuring"))
filter(alphabetic, sic80 == "8394", sic2003 == "74.14/3") %>% print(n = Inf)
filter(alphabetic, sic80 == "8395", sic2003 == "74.14/3") %>% print(n = Inf)
filter(sic80, sic80 == "8394", sic2003 == "74.14/3") %>% print(n = Inf)
filter(sic80, sic80 == "8395", sic2003 == "74.14/3") %>% print(n = Inf)

# Is "Yachts" really missing?  Yes
filter(alphabetic, str_detect(activity, "Yachts"))
filter(sic80, str_detect(activity, "Yachts"))

# Is "Travel and fancy goods importer" really missing?  No, but it has a
# probable typo: its sic2003 code should be 51.47/8, rather than 51.47
filter(alphabetic, str_detect(activity, "Travel and fancy goods importer"))
filter(sic80, str_detect(activity, "Travel and fancy goods importer"))
filter(alphabetic, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(alphabetic, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)

# Is "Travel and fancy goods exporter" really missing?  No, but it has a
# probable typo: its sic2003 code should be 51.47/8, rather than 51.47
filter(alphabetic, str_detect(activity, "Travel and fancy goods exporter"))
filter(sic80, str_detect(activity, "Travel and fancy goods exporter"))
filter(alphabetic, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(alphabetic, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)

# Is "Travel accessories" really missing?  No, but it has a probable typo: its
# sic2003 code should be 51.47/8, rather than 51.47
filter(alphabetic, str_detect(activity, "Travel accessories"))
filter(sic80, str_detect(activity, "Travel accessories"))
filter(alphabetic, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(alphabetic, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)

# Is "Cab for lorry" really missing?  Yes
filter(alphabetic, str_detect(activity, "Cab for lorry"))
filter(sic80, str_detect(activity, "Cab for lorry"))

# Is "Electro-cardiographs" really missing?  Yes
filter(alphabetic, str_detect(activity, "cardiographs"))
filter(sic80, str_detect(activity, "cardiographs"))

# Is "Repair and maintenance of cellular telephones" really missing?  No, but it
# has a typo: sic2003 should be 32.20/1 not 32.20/2
filter(alphabetic, str_detect(activity, "Repair and maintenance of cellular telephones"))
filter(sic80, str_detect(activity, "Repair and maintenance of cellular telephones"))
filter(alphabetic, sic80 == "3441", sic2003 == "32.20/1")
filter(alphabetic, sic80 == "3441", sic2003 == "32.20/2")

# Is "Multigraphing" really missing?  No, but it has a typo: sic80 should be
# 8396, not 8395
filter(alphabetic, str_detect(activity, "Multigraphing"))
filter(sic80, str_detect(activity, "Multigraphing"))
filter(alphabetic, sic80 == "8395", sic2003 == "74.85")
filter(alphabetic, sic80 == "8396", sic2003 == "74.85")

# Is "Ministry of Defence Headquarters" really missing?  No, but it has a typo:
# sic80 should be 9150, not 9111
filter(alphabetic, str_detect(activity, "Ministry of Defence Headquarters"))
filter(sic80, str_detect(activity, "Ministry of Defence Headquarters"))
filter(sic80, sic80 == "9111", sic2003 == "75.22")
filter(sic80, sic80 == "9151", sic2003 == "75.22")

# Is "Ironmonger" really missing?  No, but it has a typo: sic80 should be 6149,
# not 6148
# should be 3720 (no full point)
filter(alphabetic, str_detect(activity, "Ironmonger"))
filter(sic80, str_detect(activity, "Ironmonger"))
filter(sic80, sic80 == "6148", sic2003 == "51.54")
filter(sic80, sic80 == "6149", sic2003 == "51.54")

# Is "Fancy goods" really missing?  No, but it has a probable typo: its sic2003
# code should be 51.47/8, rather than 51.47
filter(alphabetic, str_detect(activity, "Fancy goods"))
filter(sic80, str_detect(activity, "Fancy goods"))
filter(alphabetic, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(alphabetic, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47") %>% print(n = Inf)
filter(sic80, sic80 == "6190", sic2003 == "51.47/8") %>% print(n = Inf)

# Is "Electrochemical apparatus ..." really missing?  No, but it has a probable
# typo: its sic2003 code should be 31.62, rather than 33.10.
filter(alphabetic, str_detect(activity, "Electrochemical apparatus"))
filter(sic80, str_detect(activity, "Electrochemical apparatus"))
filter(alphabetic, sic80 == "3435", sic2003 == "33.10") %>% print(n = Inf)
filter(sic80, sic80 == "3435", sic2003 == "33.10") %>% print(n = Inf)
filter(alphabetic, sic80 == "3435", sic2003 == "31.62") %>% print(n = Inf)
filter(sic80, sic80 == "3435", sic2003 == "31.62") %>% print(n = Inf)

# Is "Barley growing" really missing?  No, but it has a probable typo: its
# sic80 code should be 4270, rather than 4170
filter(alphabetic, str_detect(activity, "Barley growing"))
filter(sic80, str_detect(activity, "Barley growing"))

# Is "Dealing in financial ... " really missing?  No, it has wrapped over a page
# break, so the regexes have failed
filter(alphabetic, str_detect(activity, "Dealing in financial"))
filter(sic80, str_detect(activity, "Dealing in financial"))
filter(alphabetic, str_detect(activity, "fund management"))
filter(sic80, str_detect(activity, "fund management"))

# Is "Barley malting" really missing?  No, but it has a probable typo: its
# sic80 code should be 4270, rather than 4170
filter(alphabetic, str_detect(activity, "Barley malting"))
filter(sic80, str_detect(activity, "Barley malting"))
filter(alphabetic, sic80 == "4270", sic2003 == "15.97") %>% print(n = Inf)
filter(sic80, sic80 == "4270", sic2003 == "15.97") %>% print(n = Inf)
filter(alphabetic, sic80 == "4170", sic2003 == "15.97") %>% print(n = Inf)
filter(sic80, sic80 == "4170", sic2003 == "15.97") %>% print(n = Inf)

# Is "Cable for telecommunications" really missing?  Yes.
filter(alphabetic, str_detect(activity, "Cable for telecommunications"))
filter(sic80, activity == "Cable for telecommunications")

# Is "Dairy appliances and utensils" really missing?  No, but
# it has a probable typo: its sic2003 code should be 29.32, not 29.323
filter(alphabetic, str_detect(activity, "Dairy appliances and utensils"))
filter(sic80, activity == "Dairy appliances and utensils")
filter(alphabetic, sic80 == "3211", sic2003 == "29.32") %>% print(n = Inf)
filter(sic80, sic80 == "3211", sic2003 == "29.32") %>% print(n = Inf)
filter(alphabetic, sic80 == "3211", sic2003 == "29.323") %>% print(n = Inf)
filter(sic80, sic80 == "3211", sic2003 == "29.323") %>% print(n = Inf)

# Is "Cylindrical roller bearing" really missing?  No, but it has a probable
# typo: its sic80 code should be 3262, not 6262
filter(alphabetic, str_detect(activity, "Cylindrical roller bearing"))
filter(sic80, activity == "Cylindrical roller bearing")
filter(alphabetic, sic80 == "6262", sic2003 == "29.14") %>% print(n = Inf)
filter(sic80, sic80 == "6262", sic2003 == "29.14") %>% print(n = Inf)
filter(alphabetic, sic80 == "3262", sic2003 == "29.14") %>% print(n = Inf)
filter(sic80, sic80 == "3262", sic2003 == "29.14") %>% print(n = Inf)

# Is "Domestic hollow ... metal" really missing?  Yes.
filter(alphabetic, str_detect(activity, "Domestic hollow ware made of metal"))
filter(sic80, activity == "Domestic hollow ware made of metal")

# Is "Domestic hollow ... plastic" really missing?  No, but it has a probable
# typo: its sic2003 should be 25.24, not 28.75
filter(alphabetic, sic80 == "4836", sic2003 == "25.24") %>% print(n = Inf)
filter(sic80, sic80 == "4836", sic2003 == "25.24") %>% print(n = Inf)
filter(alphabetic, activity == "Domestic hollow ware made of plastic")
filter(sic80, activity == "Domestic hollow ware made of plastic")
filter(alphabetic, sic2003 == "25.24") %>% print(n = Inf)
filter(sic80, sic2003 == "25.24") %>% print(n = Inf)
filter(alphabetic, sic2003 == "28.75") %>% print(n = Inf)
filter(sic80, sic2003 == "28.75") %>% print(n = Inf)

# Is "Boxes made of plastic" really missing?  No, but it has a probable typo:
# its sic80 should be 4835, not 4724
filter(alphabetic, sic80 == "4835", sic2003 == "25.22") %>% print(n = Inf)
filter(sic80, sic80 == "4835", sic2003 == "25.22") %>% print(n = Inf)
filter(alphabetic, activity == "Boxes made of plastic")
filter(sic80, activity == "Boxes made of plastic")
filter(alphabetic, sic80 == "4724") %>% print(n = Inf)
filter(sic80, sic80 == "4724") %>% print(n = Inf)
filter(alphabetic, sic80 == "4835") %>% print(n = Inf)
filter(sic80, sic80 == "4835") %>% print(n = Inf)

# Is "Barley malting" really missing?  No, but it has a probable typo: its sic80
# should be 4270, not 4170.
filter(alphabetic, sic80 == "4270", sic2003 == "15.97") %>% print(n = Inf)
filter(sic80, sic80 == "4270", sic2003 == "15.97") %>% print(n = Inf)
filter(alphabetic, activity == "Barley malting")
filter(sic80, activity == "Barley malting")
filter(alphabetic, sic80 == "4270") %>% print(n = Inf)
filter(sic80, sic80 == "4270") %>% print(n = Inf)
filter(alphabetic, sic80 == "4170") %>% print(n = Inf)
filter(sic80, sic80 == "4170") %>% print(n = Inf)

# Is "Stout brewing" really missing? No, but it has a probable typo: its sic80
# should be 4270, not 4370
filter(alphabetic, sic80 == "4270", sic2003 == "15.96") %>% print(n = Inf)
filter(alphabetic, sic80 == "4370", sic2003 == "15.96") %>% print(n = Inf)
filter(sic80, sic80 == "4270", sic2003 == "15.96") %>% print(n = Inf)
filter(sic80, sic80 == "4370") %>% print(n = Inf)

# Is "Perfume" really missing?  No, but it has a probable typo: its sic80 should
# be 2582, not 2562
filter(alphabetic, sic80 == "2582", sic2003 == "24.52") %>% print(n = Inf)
filter(sic80, sic80 == "2582", sic2003 == "24.52") %>% print(n = Inf)
filter(alphabetic, activity == "Perfume")
filter(alphabetic, sic80 == "2562") %>% print(n = Inf)
filter(alphabetic, sic80 == "2582") %>% print(n = Inf)

# Is "Harvesting and drying of tobacco" really missing?  Yes.
filter(alphabetic, sic80 == "0100", sic2003 == "01.11") %>% print(n = Inf)
filter(sic80, sic80 == "0100", sic2003 == "01.11") %>% print(n = Inf)

glimpse(sic80)
glimpse(tail(sic80))

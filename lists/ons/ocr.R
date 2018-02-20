library(tidyverse)
library(magick)
library(here)

x <- image_read(here("lists", "ons", "sic1992indexes.pdf"))
y <- image_ocr(x)
image_ocr(x[1])
image_browse(x[1])
image_ocr(x[1])

library(quarto)

qmds <- list.files(
  here::here("examples"),
  pattern = "\\.qmd$",
  full.names = TRUE
)

sapply(qmds, quarto_render)

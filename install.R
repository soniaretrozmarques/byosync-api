# ================================================================
# 📦 Instalar dependências R no Render
# ================================================================
packages <- c(
  "plumber",
  "jsonlite",
  "glue"
)

install_if_missing <- function(p) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(packages, install_if_missing))

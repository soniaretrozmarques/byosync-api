# ================================================================
# 🚀 start.R — Ponto de entrada no Render
# ================================================================

library(plumber)
library(glue)

log_message <- function(msg) {
  cat(glue("[{Sys.time()}] {msg}\n"))
}

api_path <- file.path(getwd(), "api_relatorio.R")

log_message("🚀 Iniciando API BYOSync...")

pr <- plumber::plumb(api_path)

port <- as.numeric(Sys.getenv("PORT", 8000))
log_message(glue("🌐 Servidor ativo na porta {port}"))

pr$run(host = "0.0.0.0", port = port)

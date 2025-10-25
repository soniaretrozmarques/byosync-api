# start.R — Ponto de entrada no Render

library(plumber)
library(glue)

log_message <- function(msg) {
  cat(glue("[{Sys.time()}] {msg}\n"))
}

log_message("🚀 Iniciando API BYOSync...")

# Plumba o ficheiro da API
pr <- plumber::plumb("api_relatorio.R")

# Define porta (Render usa variável de ambiente PORT)
port <- as.numeric(Sys.getenv("PORT", 8000))

log_message(glue("🌐 Servidor ativo na porta {port}"))
pr$run(host = "0.0.0.0", port = port)

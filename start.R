#!/usr/bin/env Rscript
# ================================================================
# 🚀 start.R — Ponto de entrada no Render
# ================================================================

library(plumber)
library(glue)

# Função de log
log_message <- function(msg) cat(glue("[{Sys.time()}] {msg}\n"))

# Caminho absoluto da API
api_path <- file.path(getwd(), "api_relatorio.R")

log_message("🚀 Iniciando API BYOSync...")

# Plumba o ficheiro da API
pr <- plumber::plumb(api_path)

# Porta definida pelo Render
port <- as.numeric(Sys.getenv("PORT", 8000))

log_message(glue("🌐 Servidor ativo na porta {port}"))

flush.console()

# Executa o servidor
pr$run(host = "0.0.0.0", port = port)

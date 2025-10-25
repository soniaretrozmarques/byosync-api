# ================================================================
# 🌐 API ByoSync — Geração automática de relatórios (para Render)
# ================================================================

library(plumber)
library(jsonlite)
library(glue)

# Caminho para o script principal
R_SCRIPT_PATH <- file.path(getwd(), "byosync_automacao.R")

# Diretório de logs
LOG_DIR <- file.path(getwd(), "logs")
if (!dir.exists(LOG_DIR)) dir.create(LOG_DIR, recursive = TRUE)

# ================================================================
# 🧠 Função auxiliar: escrever logs
# ================================================================
log_message <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- glue("[{timestamp}] {msg}\n")
  cat(line)
  write(line, file = file.path(LOG_DIR, "api_log.txt"), append = TRUE)
}

# ================================================================
# 🧩 Endpoint principal — /run_report
# ================================================================
# Exemplo:
# POST https://teu-render.onrender.com/run_report
# {
#   "tester_id": "T01",
#   "email": "teste@byosync.pt"
# }
# ================================================================

#* @post /run_report
#* @serializer json
#* @param req:body
function(req, res) {
  tryCatch({
    if (is.null(req$postBody) || req$postBody == "") {
      stop("O corpo da requisição (JSON) está vazio!")
    }

    payload <- jsonlite::fromJSON(req$postBody)
    tester_id <- payload$tester_id %||% "NA"
    tester_email <- payload$email %||% "NA"

    log_message(glue("📩 Nova submissão recebida: {tester_id} ({tester_email})"))

    cmd <- glue('Rscript "{R_SCRIPT_PATH}" --tester_id "{tester_id}" --email "{tester_email}"')
    log_message(glue("🚀 Executando comando: {cmd}"))

    output <- system(cmd, intern = TRUE)
    log_message(glue("📄 Saída do Rscript:\n{paste(output, collapse = '\n')}"))

    res$status <- 200
    list(
      status = "ok",
      message = glue("Relatório gerado com sucesso para {tester_id}"),
      output = output
    )

  }, error = function(e) {
    log_message(glue("❌ Erro: {e$message}"))
    res$status <- 500
    list(status = "erro", message = e$message)
  })
}

# ================================================================
# 🚀 Execução no Render (porta automática)
# ================================================================
port <- as.numeric(Sys.getenv("PORT", 8000))
pr <- plumber::plumb("api_relatorio.R")
pr$run(host = "0.0.0.0", port = port)


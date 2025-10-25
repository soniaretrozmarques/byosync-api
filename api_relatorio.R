# ==========================================================
# api_relatorio.R
# API para geração automática de relatórios BYOSync
# ==========================================================

library(plumber)
library(glue)

#------------------------------------------------------------
# Função auxiliar de log
#------------------------------------------------------------
log_message <- function(msg) {
  cat(glue("[{Sys.time()}] {msg}\n"))
}

#------------------------------------------------------------
# Endpoint principal: /gerar_relatorio
#------------------------------------------------------------

#* @apiTitle BYOSync Relatório API
#* @apiDescription Gera relatórios automáticos para testers.

#* @post /gerar_relatorio
#* @param tester_id:string O ID do tester
#* @param tester_email:string Email do tester
#* @serializer unboxedJSON
function(req, res) {
  # Lê parâmetros da query ou do body
  tester_id <- if (!is.null(req$args$tester_id)) req$args$tester_id else if (!is.null(req$body$tester_id)) req$body$tester_id else "NA"
  tester_email <- if (!is.null(req$args$tester_email)) req$args$tester_email else if (!is.null(req$body$tester_email)) req$body$tester_email else "NA"

  log_message(glue("📥 Requisição recebida para tester_id={tester_id}, email={tester_email}"))

  R_SCRIPT_PATH <- "scripts/gerar_relatorio.R"

  cmd <- glue('Rscript "{R_SCRIPT_PATH}" --tester_id "{tester_id}" --email "{tester_email}"')
  log_message(glue("🚀 Executando comando: {cmd}"))

  output <- tryCatch({
    system(cmd, intern = TRUE)
  }, error = function(e) {
    log_message(glue("❌ Erro ao executar script: {e$message}"))
    res$status <- 500
    return(list(
      status = "erro",
      message = e$message
    ))
  })

  log_message(glue("📄 Saída do Rscript:\n{paste(output, collapse = '\n')}"))

  res$status <- 200
  list(
    status = "ok",
    message = glue("Relatório gerado com sucesso para tester {tester_id}"),
    output = output
  )
}


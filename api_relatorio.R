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
function(req, res, tester_id, tester_email) {
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

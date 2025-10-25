# api_relatorio.R
library(plumber)
library(glue)

#* @apiTitle BYOSync Relatório API
#* @apiDescription Gera relatórios automáticos para testers.

#* @post /gerar_relatorio
#* @param tester_id O ID do tester
#* @param tester_email Email do tester
function(req, res, tester_id, tester_email) {
  log_message <- function(msg) cat(glue("[{Sys.time()}] {msg}\n"))
  
  R_SCRIPT_PATH <- "scripts/gerar_relatorio.R"
  
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
} 

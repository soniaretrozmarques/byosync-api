#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(glue)
  library(blastula)
})

# Lê argumentos
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  val <- sub(paste0("--", flag, "="), "", args[grepl(paste0("--", flag, "="), args)])
  if (length(val) == 0) return(NA)
  return(val)
}

tester_id <- get_arg("tester_id")
email <- get_arg("email")

# Diretório de saída
output_dir <- "reports"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat(glue("📊 Gerando relatório para tester: {tester_id} | email: {email}\n"))

# Simula geração do relatório
Sys.sleep(2)
output_path <- file.path(output_dir, glue("relatorio_{tester_id}.txt"))

conteudo <- glue("
Relatório BYOSync
==================
Tester: {tester_id}
Email: {email}
Data: {Sys.time()}

✅ Relatório criado com sucesso!
")

writeLines(conteudo, con = output_path)
cat(glue("📁 Arquivo salvo: {output_path}\n"))

# Enviar e-mail com blastula
tryCatch({
  email_msg <- compose_email(
    body = md(glue("
Olá {tester_id},

O seu relatório foi gerado com sucesso ✅

Pode encontrar o ficheiro em anexo.

Cumprimentos,  
**Equipa BYOSync**
    "))
  )

  smtp_send(
    email = email_msg,
    from = "byosync@outlook.com",        # ⚠️ substitui pelo e-mail do servidor
    to = email,
    subject = glue("Relatório BYOSync — {tester_id}"),
    credentials = creds(
      user = "byosync@outlook.com",       # ⚠️ substitui
      provider = "outlook",
      use_ssl = TRUE
    ),
    attachments = output_path
  )

  cat(glue("📨 E-mail enviado para {email}\n"))
}, error = function(e) {
  cat(glue("⚠️ Falha ao enviar e-mail: {e$message}\n"))
})

flush.console()

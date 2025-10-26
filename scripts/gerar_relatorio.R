#!/usr/bin/env Rscript

# ================================================================
# 📊 BYOSync — Script de geração automática de relatórios
# ================================================================

suppressPackageStartupMessages({
  library(glue)
  library(blastula)
  library(dotenv)
})

# ------------------------------------------------------------
# 🔧 Carregar variáveis de ambiente (.env ou Render)
# ------------------------------------------------------------
if (file.exists(".env")) {
  dotenv::load_dot_env(".env")
}

SENDGRID_API_KEY <- Sys.getenv("SENDGRID_API_KEY")
SMTP_FROM <- Sys.getenv("SMTP_FROM", "byosync.health@gmail.com")

# ------------------------------------------------------------
# 🧠 Ler argumentos da linha de comando
# ------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  # Suporta argumentos no formato --flag=value
  match_eq <- grep(paste0("^--", flag, "="), args, value = TRUE)
  if (length(match_eq) > 0) {
    return(sub(paste0("^--", flag, "="), "", match_eq))
  }
  # Suporta formato --flag value
  match_space <- which(args == paste0("--", flag))
  if (length(match_space) > 0 && length(args) >= match_space + 1) {
    return(args[match_space + 1])
  }
  return(NA)
}

tester_id <- get_arg("tester_id")
email <- get_arg("email")

if (is.na(tester_id) || is.na(email)) {
  stop("❌ Argumentos 'tester_id' e 'email' são obrigatórios!")
}

# ------------------------------------------------------------
# 📁 Diretório de saída
# ------------------------------------------------------------
output_dir <- "reports"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat(glue("📊 Gerando relatório para tester: {tester_id} | email: {email}\n"))

# ------------------------------------------------------------
# 🧩 Simular a geração do relatório
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# ✉️ Enviar e-mail via SendGrid (usando blastula)
# ------------------------------------------------------------
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
    from = SMTP_FROM,
    to = email,
    subject = glue("Relatório BYOSync — {tester_id}"),
    credentials = creds(
      host = "smtp.sendgrid.net",
      port = 587,
      user = "apikey",
      password = Sys.getenv("SENDGRID_API_KEY"),
      use_ssl = TRUE
    ),
    attachments = output_path
  )

  cat(glue("📨 E-mail enviado com sucesso para {email}\n"))
}, error = function(e) {
  cat(glue("⚠️ Falha ao enviar e-mail: {e$message}\n"))
})

flush.console()

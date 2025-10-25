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

SMTP_USER <- Sys.getenv("SMTP_USER", "byosync@outlook.com")
SMTP_PASS <- Sys.getenv("SMTP_PASS", "")
SMTP_PROVIDER <- Sys.getenv("SMTP_PROVIDER", "outlook")
SMTP_FROM <- Sys.getenv("SMTP_FROM", "byosync@outlook.com")

# ------------------------------------------------------------
# 🧠 Lê argumentos da linha de comando
# ------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  # aceita argumentos do tipo "--flag=valor" OU "--flag valor"
  val <- NA
  if (any(grepl(paste0("^--", flag, "="), args))) {
    val <- sub(paste0("^--", flag, "="), "", args[grepl(paste0("^--", flag, "="), args)])
  } else if (any(grepl(paste0("^--", flag, "$"), args))) {
    idx <- which(grepl(paste0("^--", flag, "$"), args))
    if (length(args) > idx) val <- args[idx + 1]
  }
  return(ifelse(length(val) == 0, NA, val))
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
# 🧩 Simula a geração do relatório
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
# ✉️ Enviar e-mail com blastula (seguro via credenciais .env)
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
  user = SMTP_USER,
  provider = SMTP_PROVIDER,
  use_ssl = TRUE
),
    attachments = output_path
  )

  cat(glue("📨 E-mail enviado para {email}\n"))
}, error = function(e) {
  cat(glue("⚠️ Falha ao enviar e-mail: {e$message}\n"))
})

flush.console()

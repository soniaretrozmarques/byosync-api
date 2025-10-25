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

SMTP_USER <- Sys.getenv("SMTP_USER", "byosync.bot@outlook.com")
SMTP_PASS <- Sys.getenv("SMTP_PASS", "")
SMTP_PROVIDER <- Sys.getenv("SMTP_PROVIDER", "office365")
SMTP_FROM <- Sys.getenv("SMTP_FROM", "byosync.bot@outlook.com")

# ------------------------------------------------------------
# 🧠 Lê argumentos da linha de comando (robusto)
# ------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  # Aceita --flag=valor ou --flag valor
  match_eq <- grep(paste0("^--", flag, "="), args, value = TRUE)
  if (length(match_eq) > 0) {
    return(sub(paste0("^--", flag, "="), "", match_eq))
  }

  match_plain <- which(args == paste0("--", flag))
  if (length(match_plain) > 0 && length(args) >= match_plain + 1) {
    return(args[match_plain + 1])
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
# ✉️ Enviar e-mail com blastula
# ------------------------------------------------------------
tryCatch({
  Sys.setenv(BLASTULA_PASSWORD = SMTP_PASS)  # 🔐 Necessário para autenticação Outlook

  email_msg <- compose_email(
    body = md(glue("
Olá {tester_id},

O seu relatório foi gerado com sucesso ✅  
Pode encontrar o ficheiro em anexo.

Cumprimentos,  
**Equipa BYOSync**
    "))
  ) %>%
    add_attachment(file = output_path)  # 🆕 forma compatível com blastula moderno

  smtp_send(
    email = email_msg,
    from = SMTP_FROM,
    to = email,
    subject = glue("Relatório BYOSync — {tester_id}"),
    credentials = creds(
      user = SMTP_USER,
      provider = SMTP_PROVIDER,
      use_ssl = TRUE
    )
  )

  cat(glue("📨 E-mail enviado com sucesso para {email}\n"))
}, error = function(e) {
  cat(glue("⚠️ Falha ao enviar e-mail: {e$message}\n"))
})

flush.console()


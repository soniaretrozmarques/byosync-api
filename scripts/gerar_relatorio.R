#!/usr/bin/env Rscript
# ================================================================
# 📊 BYOSync — Script de geração automática de relatórios
# ================================================================

suppressPackageStartupMessages({
  library(glue)
  library(dotenv)
  library(blastula)
})

# ------------------------------------------------------------
# 🔧 Carregar variáveis de ambiente (.env ou Render)
# ------------------------------------------------------------
if (file.exists(".env")) {
  dotenv::load_dot_env(".env")
}

SMTP_USER <- Sys.getenv("SMTP_USER", "byosync.health@gmail.com")
SMTP_PASS <- Sys.getenv("SMTP_PASS", "")
SMTP_FROM <- Sys.getenv("SMTP_FROM", "byosync.health@gmail.com")

# ------------------------------------------------------------
# 🧠 Ler argumentos
# ------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  match_eq <- grep(paste0("^--", flag, "="), args, value = TRUE)
  if (length(match_eq) > 0) {
    return(sub(paste0("^--", flag, "="), "", match_eq))
  }
  match_space <- grep(paste0("^--", flag, "$"), args)
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
# ✉️ Enviar e-mail com blastula via Gmail SMTP (compatível)
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

  ns <- getNamespaceExports("blastula")
  if ("smtp_credentials" %in% ns) {
    creds <- blastula::smtp_credentials(
      host = "smtp.gmail.com",
      port = 465,
      user = SMTP_USER,
      password = SMTP_PASS,
      use_ssl = TRUE
    )
  } else if ("creds_smtp" %in% ns) {
    creds <- blastula::creds_smtp(
      user = SMTP_USER,
      password = SMTP_PASS,
      host = "smtp.gmail.com",
      port = 465,
      use_ssl = TRUE
    )
  } else {
    stop("❌ Nenhuma função SMTP suportada encontrada em blastula.")
  }

  smtp_send(
    email = email_msg,
    from = SMTP_FROM,
    to = email,
    subject = glue("Relatório BYOSync — {tester_id}"),
    credentials = creds,
    attachments = output_path
  )

  cat(glue("📨 E-mail enviado com sucesso para {email}\n"))
}, error = function(e) {
  cat(glue("⚠️ Falha ao enviar e-mail: {e$message}\n"))
})

flush.console()

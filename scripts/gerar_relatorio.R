#!/usr/bin/env Rscript
# scripts/gerar_relatorio.R
# Este script gera um relatório PDF e envia por email ao tester

suppressPackageStartupMessages({
  library(optparse)
  library(glue)
  library(rmarkdown)
  library(blastula)
})

# === 1. Ler argumentos ===
option_list <- list(
  make_option("--tester_id", type = "character", help = "ID do tester"),
  make_option("--email", type = "character", help = "Email do tester")
)

opt <- parse_args(OptionParser(option_list = option_list))

tester_id <- opt$tester_id
tester_email <- opt$email

if (is.null(tester_id) || is.null(tester_email)) {
  stop("⚠️ Falta o tester_id ou o email.")
}

cat(glue("📊 Gerando relatório para tester: {tester_id} | email: {tester_email}\n"))

# === 2. Gerar conteúdo do relatório ===
relatorio_path <- glue("relatorio_{tester_id}.pdf")

# Criar um relatório simples em R Markdown temporário
rmd_temp <- tempfile(fileext = ".Rmd")
writeLines(glue("
---
title: 'Relatório do Tester {tester_id}'
output: pdf_document
---

## Informações do Tester

- **ID:** {tester_id}  
- **Email:** {tester_email}  
- **Data:** {Sys.Date()}

## Resultados
Este é um relatório automático gerado via API BYOSync.
"), rmd_temp)

# Gerar o PDF
rmarkdown::render(rmd_temp, output_file = relatorio_path, quiet = TRUE)
cat(glue("✅ Relatório criado com sucesso!\nArquivo salvo: {relatorio_path}\n"))

# === 3. Enviar por email ===
# ⚠️ Configura as tuas credenciais Gmail abaixo

email <- compose_email(
  body = md(glue("
Olá **{tester_id}**,

Segue em anexo o relatório gerado automaticamente pelo sistema BYOSync.

Cumprimentos,  
**Equipa BYOSync**
")),
  footer = md("Relatório gerado automaticamente.")
)

smtp_send(
  email,
  to = tester_email,
  from = "byosync@gmail.com",        # substitui pelo teu email
  subject = glue("Relatório do Tester {tester_id}"),
  credentials = creds(
    user = "byosync@gmail.com",      # substitui pelo teu email
    pass = Sys.getenv("EMAIL_PASSWORD"),  # guarda a password no Render
    host = "smtp.gmail.com",
    port = 465,
    use_ssl = TRUE
  ),
  attachments = relatorio_path
)

cat(glue("📧 Email enviado para {tester_email}\n"))

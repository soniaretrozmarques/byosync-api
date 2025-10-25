#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(glue)
})

# Lê argumentos da linha de comando
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag) {
  val <- sub(paste0("--", flag, "="), "", args[grepl(paste0("--", flag, "="), args)])
  if (length(val) == 0) return(NA)
  return(val)
}

tester_id <- get_arg("tester_id")
email <- get_arg("email")

cat(glue("📊 Gerando relatório para tester: {tester_id} | email: {email}\n"))

# Simula a criação do relatório
Sys.sleep(2)
output_path <- glue("relatorio_{tester_id}.txt")

conteudo <- glue("Relatório gerado com sucesso!\nTester: {tester_id}\nEmail: {email}\nData: {Sys.time()}")
writeLines(conteudo, con = output_path)

cat(glue("✅ Relatório criado com sucesso!\n"))
cat(glue("📁 Arquivo salvo: {output_path}\n"))

# Garante que tudo é enviado para stdout
flush.console()

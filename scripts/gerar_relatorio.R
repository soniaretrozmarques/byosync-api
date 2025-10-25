# scripts/gerar_relatorio.R

args <- commandArgs(trailingOnly = TRUE)

# Lê parâmetros
tester_id <- NA
tester_email <- NA

for (i in seq_along(args)) {
  if (args[i] == "--tester_id") tester_id <- args[i + 1]
  if (args[i] == "--email") tester_email <- args[i + 1]
}

cat(glue::glue("📊 Gerando relatório para tester: {tester_id} | email: {tester_email}\n"))

# Gera o arquivo de saída (pode ser .txt, .pdf, etc.)
output_file <- glue::glue("relatorio_{tester_id}.txt")
writeLines(c(
  glue::glue("Relatório automático do tester: {tester_id}"),
  glue::glue("Email: {tester_email}"),
  glue::glue("Data de geração: {Sys.time()}"),
  "",
  "Conteúdo de teste do relatório."
), output_file)

cat(glue::glue("✅ Relatório criado com sucesso!\n"))
cat(glue::glue("Arquivo salvo: {output_file}\n"))

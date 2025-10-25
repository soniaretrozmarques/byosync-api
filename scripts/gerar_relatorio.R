# scripts/gerar_relatorio.R
args <- commandArgs(trailingOnly = TRUE)

# Lê os argumentos passados pela API
tester_id <- sub("--tester_id=", "", args[grep("--tester_id=", args)])
email <- sub("--email=", "", args[grep("--email=", args)])

cat("📊 Gerando relatório para tester:", tester_id, "email:", email, "\n")

# Simula criação do relatório
Sys.sleep(2)
cat("✅ Relatório criado com sucesso!\n")

# Guarda um arquivo de exemplo
output_file <- paste0("relatorio_", tester_id, ".txt")
writeLines(c("Relatório de Tester", paste("ID:", tester_id), paste("Email:", email)), output_file)
cat("Arquivo salvo:", output_file, "\n")

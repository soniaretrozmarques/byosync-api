# Usa uma imagem oficial do R com o Plumber
FROM rocker/plumber:latest

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os ficheiros do projeto para o container
COPY . /app

# Expõe a porta usada pelo Render
EXPOSE 8080

# Instala pacotes necessários
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'))"

# Comando para correr a API
CMD R -e "pr <- plumber::pr('api_relatorio.R'); pr$run(host='0.0.0.0', port=8080)"

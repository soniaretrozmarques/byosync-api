# Usa uma imagem de R com Plumber
FROM rocker/plumber:latest

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os ficheiros para o container
COPY . /app

# Expõe a porta que o Render usa
EXPOSE 8080

# Instala pacotes R necessários
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'))"

# Comando para iniciar o servidor Plumber
CMD R -e "source('api_relatorio.R'); pr('api_relatorio.R') %>% pr_run(host='0.0.0.0', port=8080)"

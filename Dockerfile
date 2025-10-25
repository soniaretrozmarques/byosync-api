# Usa uma imagem oficial com R e Plumber
FROM rocker/r-ver:4.3.1

# Instala o Plumber e outras dependências
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'), repos='https://cloud.r-project.org/')"

# Define o diretório de trabalho
WORKDIR /app

# Copia os ficheiros do repositório
COPY . /app

# Expõe a porta (Render usa automaticamente esta)
EXPOSE 8000

# Comando para arrancar a API
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=8000)"]

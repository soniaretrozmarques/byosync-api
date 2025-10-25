# Usa uma imagem base do R adequada
FROM rocker/r-ver:4.3.2

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Instala pacotes R necessários (incluindo plumber)
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue', 'dplyr', 'lubridate', 'janitor', 'data.table', 'ggplot2', 'readr', 'googlesheets4'), repos='https://cloud.r-project.org/')"

# Copia todos os ficheiros do projeto
WORKDIR /app
COPY . /app

# Expõe a porta usada pelo plumber
EXPOSE 8000

# Define o comando para iniciar o servidor R
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=8000)"]

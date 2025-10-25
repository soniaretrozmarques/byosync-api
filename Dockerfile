# Usa imagem oficial com R pré-instalado
FROM rocker/r-ver:4.3.1

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala pacotes R necessários
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'), repos='https://cloud.r-project.org/')"

# Define diretório de trabalho
WORKDIR /app

# Copia todo o conteúdo do repositório para dentro do container
COPY . /app

# Expõe a porta usada pelo Plumber
EXPOSE 8000

# Comando que arranca o servidor
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=8000)"]



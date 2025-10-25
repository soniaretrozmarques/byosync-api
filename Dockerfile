# Usa uma imagem oficial do R base
FROM rocker/r-ver:4.3.1

# Instala dependências do sistema (necessárias para plumber, httpuv, sodium, etc.)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libz-dev \
    libsodium-dev \
    pkg-config \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Instala pacotes R necessários
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'), repos='https://cloud.r-project.org/')"

# Define o diretório de trabalho
WORKDIR /app

# Copia todo o código para dentro do container
COPY . /app

# Expõe a porta usada pelo plumber
EXPOSE 8000

# Comando para iniciar a API
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=8000)"]

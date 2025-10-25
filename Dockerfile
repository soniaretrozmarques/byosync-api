# ===============================================================
# 🐳 Dockerfile — API ByoSync (R + plumber)
# ===============================================================

FROM rocker/r-ver:4.3.1

# Instala dependências do sistema
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

# Define diretório de trabalho
WORKDIR /app

# Copia todos os ficheiros para dentro do container
COPY . /app

# Define comando padrão de execução
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT', 8000)))"]


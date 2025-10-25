# Usa imagem base oficial do R
FROM rocker/r-ver:4.3.1

# Instala dependências do sistema necessárias para plumber, curl, e blastula
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libz-dev \
    libsodium-dev \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Instala os pacotes R necessários
RUN R -e "install.packages(c('plumber', 'glue', 'rmarkdown', 'blastula', 'dplyr'), repos='https://cloud.r-project.org')"

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os ficheiros da app
COPY . /app

# Expõe a porta que o Render usa
EXPOSE 8000

# Comando de arranque
CMD ["Rscript", "start.R"]

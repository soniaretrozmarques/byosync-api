# Usa imagem base oficial do R (com suporte a pacotes compilados)
FROM rocker/r-ver:4.3.1

# ------------------------------------------------------------
# 🔧 Instalar dependências do sistema
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    zlib1g-dev \
    pandoc \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 📦 Instalar pacotes R necessários
# ------------------------------------------------------------
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org')"

# Instala todos os pacotes de uma vez, com dependências forçadas
RUN R -e "install.packages(c('plumber', 'glue', 'rmarkdown', 'blastula', 'dplyr', 'httr', 'jsonlite', 'dotenv'), repos='https://cloud.r-project.org', dependencies=TRUE)"

# Força reinstalação do plumber (garante que está disponível)
RUN R -e "if(!requireNamespace('plumber', quietly=TRUE)) install.packages('plumber', repos='https://cloud.r-project.org')"

# ------------------------------------------------------------
# 🏗️ Diretório de trabalho
# ------------------------------------------------------------
WORKDIR /byosync-api

# ------------------------------------------------------------
# 📁 Copiar código da aplicação
# ------------------------------------------------------------
COPY . /byosync-api

# ------------------------------------------------------------
# 🌐 Porta usada pelo Render
# ------------------------------------------------------------
EXPOSE 8000

# ------------------------------------------------------------
# 🚀 Comando de arranque
# ------------------------------------------------------------
CMD ["Rscript", "start.R"]

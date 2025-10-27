# =============================================================
# 🐳 Dockerfile — BYOSync API (Render)
# =============================================================

# Usa imagem base oficial do R
FROM rocker/r-ver:4.3.1

# ------------------------------------------------------------
# 🔧 Instalar dependências do sistema
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libsodium-dev \
    zlib1g-dev \
    pandoc \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 📦 Instalar pacotes R necessários
# ------------------------------------------------------------
RUN R -e "install.packages(c('remotes'), repos='https://cloud.r-project.org')"

RUN R -e "install.packages(c( \
  'plumber', 'glue', 'rmarkdown', 'dplyr', 'httr', 'jsonlite', 'dotenv', 'blastula' \
  ), repos='https://cloud.r-project.org', dependencies=TRUE)"

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

# Usa imagem base oficial do R
FROM rocker/r-ver:4.3.1

# ------------------------------------------------------------
# 🔧 Instalar dependências do sistema
# ------------------------------------------------------------
# Inclui bibliotecas essenciais para:
# - HTTP/SSL (curl, openssl)
# - XML/parsing (libxml2)
# - Geração de relatórios (rmarkdown)
# - Envio de emails (blastula)
# - Compressão e Git (zlib, libgit2)
# - Pandoc (para gerar relatórios em HTML/PDF)
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libz-dev \
    libsodium-dev \
    zlib1g-dev \
    pandoc \
    pandoc-citeproc \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 📦 Instalar pacotes R necessários
# ------------------------------------------------------------
RUN R -e "install.packages(c('plumber', 'glue', 'rmarkdown', 'blastula', 'dplyr', 'httr', 'jsonlite', 'dotenv'), repos='https://cloud.r-project.org')"

# ------------------------------------------------------------
# 🏗️ Definir diretório de trabalho
# ------------------------------------------------------------
WORKDIR /byosync-api

# ------------------------------------------------------------
# 📁 Copiar todos os ficheiros da aplicação
# ------------------------------------------------------------
COPY . /byosync-api

# ------------------------------------------------------------
# 🌐 Expor porta usada pelo Render
# ------------------------------------------------------------
EXPOSE 8000

# ------------------------------------------------------------
# 🚀 Comando de arranque
# ------------------------------------------------------------
CMD ["Rscript", "start.R"]

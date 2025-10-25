# ============================================================
# Dockerfile para API BYOSync no Render (corrigido)
# ============================================================

FROM rocker/r-ver:4.3.1

# Atualiza e instala dependências do sistema necessárias para plumber, curl, etc.
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    pandoc \
    texlive-latex-base \
    texlive-fonts-recommended \
    texlive-extra-utils \
    texlive-latex-extra

RUN R -e "install.packages(c('plumber', 'glue', 'rmarkdown', 'blastula', 'optparse'), repos='https://cloud.r-project.org')"

# Define diretório de trabalho
WORKDIR /app

# Copia os ficheiros do projeto
COPY . /app

# Expõe a porta usada pelo Render
EXPOSE 8000

# Comando para iniciar o servidor
CMD ["Rscript", "start.R"]

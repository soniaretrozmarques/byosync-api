# Usa uma imagem oficial com R já instalado
FROM rocker/r-ver:4.3.1

# Atualiza e instala dependências do sistema necessárias
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala pacotes R necessários para a API
RUN R -e "install.packages(c('plumber', 'jsonlite', 'glue'), repos='https://cloud.r-project.org/')"

# Define o diretório de trabalho
WORKDIR /app

# Copia o código R para dentro do container
COPY . /app

# Expõe a porta usada pela API
EXPOSE 8000

# Define o comando para iniciar o servidor Plumber
CMD ["R", "-e", "pr <- plumber::plumb('api_relatorio.R'); pr$run(host='0.0.0.0', port=8000)"]


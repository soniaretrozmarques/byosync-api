FROM rocker/r-ver:4.3.1

# Instalar plumber e glue
RUN R -e "install.packages(c('plumber', 'glue'), repos='https://cloud.r-project.org')"

WORKDIR /app

COPY . /app

EXPOSE 8000

# Render inicia com este comando
CMD ["Rscript", "start.R"]

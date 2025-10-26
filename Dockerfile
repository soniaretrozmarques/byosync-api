FROM rocker/r-ver:4.3.1

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    zlib1g-dev \
    pandoc \
 && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('plumber', 'glue', 'rmarkdown', 'blastula', 'dplyr', 'httr', 'jsonlite', 'dotenv'), repos='https://cloud.r-project.org', dependencies=TRUE)"

WORKDIR /byosync-api
COPY . /byosync-api
EXPOSE 8000

CMD ["Rscript", "start.R"]

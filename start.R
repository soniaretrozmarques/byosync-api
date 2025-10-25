library(plumber)

pr <- plumber::plumb("api_relatorio.R")
port <- as.numeric(Sys.getenv("PORT", 8000))
pr$run(host = "0.0.0.0", port = port)

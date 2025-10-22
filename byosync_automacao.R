################################################################################
# byosync_auto_envio_final_graficos_estetico_fixed_clean.R
# ByoSync Health — Automatização: Google Sheets -> APIs -> Relatório PDF -> Email
# Versão limpa e corrigida
################################################################################

# 0) CONFIG ⚙️
sheet_url <- "https://docs.google.com/spreadsheets/d/1fu4elw4if84eXVFPjDgMGcoq0MpMOOTB_3wAQgVQWdA/edit?resourcekey=&gid=1788814797#gid=1788814797"
output_folder <- "C:/Users/35191/Documents/ByoSync Health/FASE_3_VERSAO_BETA_DADOS_REAIS"
processed_ids_file <- file.path(output_folder, "processed_ids.rds")

OPENWEATHER_KEY <- Sys.getenv("9c4f621b6211cbf39e53ff51fc061b8d", unset = "9c4f621b6211cbf39e53ff51fc061b8d") 
IQAIR_KEY       <- Sys.getenv("12ee082f-4292-48b1-b178-80117c480852", unset = "12ee082f-4292-48b1-b178-80117c480852")
OPENUV_KEY      <- Sys.getenv("openuv-uzuhrmgtaqn8c-io", unset = "openuv-uzuhrmgtaqn8c-io") 

if (nchar(OPENWEATHER_KEY) < 5) stop("OPENWEATHER_KEY não definida.")
if (nchar(IQAIR_KEY) < 5) stop("IQAIR_KEY não definida.")
if (nchar(OPENUV_KEY) < 5) stop("OPENUV_KEY não definida.")

email_from <- "byosync.health@gmail.com"
produce_and_send_email <- TRUE

if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)

# 1) PACKAGES 📦
pkgs <- c(
  "googlesheets4","dplyr","janitor","glue","stringr","lubridate",
  "httr","jsonlite","rmarkdown","blastula","fs","ggplot2","knitr","digest",
  "data.table"
)
for(p in pkgs){
  if(!requireNamespace(p, quietly = TRUE)){
    message(paste0("Instalando pacote: ", p))
    if (p == "blastula" && !requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes")
      remotes::install_github("rstudio/blastula")
    } else {
      install.packages(p)
    }
  }
  library(p, character.only = TRUE)
}

# Operador utilitário: retorna b se a for NULL
`%||%` <- function(a, b) if(!is.null(a)) a else b

# 2) Google Sheets auth (interactive first time)
token_cache_dir <- file.path(output_folder, "token_cache")
if(!dir.exists(token_cache_dir)) dir.create(token_cache_dir, recursive = TRUE, showWarnings = FALSE)

googlesheets4::gs4_auth(
  email = "sony.marques96@gmail.com",
  cache = token_cache_dir
)
message("✅ Autenticação Google Sheets concluída com sucesso.")

# 3) Ler sheet e normalizar colunas
dados_raw <- googlesheets4::read_sheet(sheet_url)
dados <- janitor::clean_names(dados_raw)

possible_cols <- names(dados)
map_cols <- list(
  tester_id  = possible_cols[stringr::str_detect(possible_cols, regex("codigo|tester_id|tester id|^id$", ignore_case = TRUE))],
  data_raw   = possible_cols[stringr::str_detect(possible_cols, regex("data|date|timestamp|submissao|created", ignore_case = TRUE))],
  horas_sono = possible_cols[stringr::str_detect(possible_cols, regex("horas.*sono|hours.*sleep", ignore_case = TRUE))],
  stress     = possible_cols[stringr::str_detect(possible_cols, regex("stress", ignore_case = TRUE))],
  atividade  = possible_cols[stringr::str_detect(possible_cols, regex("atividade|activity", ignore_case = TRUE))],
  agua       = possible_cols[stringr::str_detect(possible_cols, regex("copos|water", ignore_case = TRUE))],
  energia    = possible_cols[stringr::str_detect(possible_cols, regex("energia|energy", ignore_case = TRUE))],
  humor      = possible_cols[stringr::str_detect(possible_cols, regex("humor|mood", ignore_case = TRUE))],
  cidade     = possible_cols[stringr::str_detect(possible_cols, regex("cidade|city", ignore_case = TRUE))],
  email      = possible_cols[stringr::str_detect(possible_cols, regex("^email$|e_mail", ignore_case = TRUE))]
)

for (nm in names(map_cols)) {
  candidates <- map_cols[[nm]]
  if (length(candidates) == 1 && nzchar(candidates)) {
    names(dados)[names(dados) == candidates] <- nm
  }
}

if (!"tester_id" %in% names(dados)) {
  if ("email" %in% names(dados)) {
    dados <- dados %>% mutate(tester_id = as.character(email))
  } else stop("Erro: não foi possível identificar tester_id nem email.")
}

# Data parsing: tenta várias colunas comuns
if ("data_raw" %in% names(dados)) {
  dados$data <- suppressWarnings(lubridate::as_datetime(dados$data_raw, tz = Sys.timezone()))
  if (all(is.na(dados$data))) {
    dados$data <- suppressWarnings(lubridate::ymd_hms(dados$data_raw, tz = Sys.timezone()))
  }
} else if ("x2_data_date" %in% names(dados)) {
  dados$data <- suppressWarnings(lubridate::as_datetime(dados$x2_data_date, tz = Sys.timezone()))
} else if ("timestamp" %in% names(dados)) {
  dados$data <- suppressWarnings(lubridate::as_datetime(dados$timestamp, tz = Sys.timezone()))
} else {
  stop("Erro: não existe coluna de data identificada.")
}

for (col in c("horas_sono", "stress", "atividade", "agua", "energia", "humor")) {
  if (col %in% names(dados)) dados[[col]] <- suppressWarnings(as.numeric(dados[[col]]))
}

# 3) EVITAR DUPLICADOS
dados <- dados %>%
  mutate(
    data_original = as.character(if("data_raw" %in% names(.) ) data_raw else format(data, "%Y-%m-%d %H:%M:%S")),
    row_uid = digest::digest(paste0(tester_id, "_", data_original), algo = "md5")
  )

if (file.exists(processed_ids_file)) {
  processed_ids <- tryCatch(readRDS(processed_ids_file), error = function(e) character(0))
} else processed_ids <- character(0)

if (!"row_uid" %in% names(dados)) stop("Coluna row_uid não encontrada.")
novas <- dados %>% filter(!row_uid %in% processed_ids)
if (nrow(novas) == 0) {
  message("ℹ️ Sem novas submissões para processar. Nenhum relatório gerado.")
  quit(save="no")
}
message("✅ Novas submissões a processar: ", nrow(novas))

# 4) FUNÇÕES (APIs)
geocode_city <- function(city_name, api_key = OPENWEATHER_KEY){
  if (is.null(city_name) || is.na(city_name) || trimws(city_name) == "") return(NULL)
  url <- glue::glue("http://api.openweathermap.org/geo/1.0/direct?q={utils::URLencode(city_name)}&limit=1&appid={api_key}")
  res <- tryCatch(httr::GET(url, httr::timeout(10)), error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(NULL)
  js <- tryCatch(jsonlite::fromJSON(httr::content(res, "text", encoding = "UTF-8")), error = function(e) NULL)
  if (is.null(js) || length(js) == 0) return(NULL)
  data.frame(lat = js$lat[1], lon = js$lon[1], name = js$name[1], country = js$country[1], stringsAsFactors = FALSE)
}

get_openweather <- function(lat, lon, api_key = OPENWEATHER_KEY){
  if (is.null(lat) || is.null(lon)) return(NULL)
  url <- glue::glue("https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&units=metric&appid={api_key}")
  res <- tryCatch(httr::GET(url, httr::timeout(10)), error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(NULL)
  js <- tryCatch(jsonlite::fromJSON(httr::content(res, "text", encoding = "UTF-8")), error = function(e) NULL)
  if (is.null(js)) return(NULL)
  desc <- tryCatch({
    if (is.list(js$weather)) js$weather[[1]]$description else if (is.data.frame(js$weather)) js$weather$description[1] else NA
  }, error = function(e) NA)
  list(temp = (js$main$`temp` %||% NA), humidity = (js$main$humidity %||% NA), weather_desc = desc)
}

get_iqair <- function(lat, lon, api_key = IQAIR_KEY){
  if (is.null(lat) || is.null(lon)) return(NULL)
  url <- glue::glue("http://api.airvisual.com/v2/nearest_city?lat={lat}&lon={lon}&key={api_key}")
  res <- tryCatch(httr::GET(url, httr::timeout(8)), error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(NULL)
  js <- tryCatch(jsonlite::fromJSON(httr::content(res, "text", encoding = "UTF-8")), error = function(e) NULL)
  if (is.null(js)) return(NULL)
  aqi_us <- tryCatch(js$data$current$pollution$aqius, error = function(e) NA)
  list(aqi_us = aqi_us)
}

get_openuv <- function(lat, lon, api_key = OPENUV_KEY){
  if (is.null(lat) || is.null(lon)) return(NULL)
  url <- glue::glue("https://api.openuv.io/api/v1/uv?lat={lat}&lng={lon}")
  res <- tryCatch(httr::GET(url, httr::add_headers("x-access-token" = api_key), httr::timeout(8)), error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(NULL)
  js <- tryCatch(jsonlite::fromJSON(httr::content(res, "text", encoding = "UTF-8")), error = function(e) NULL)
  if (is.null(js)) return(NULL)
  uv_idx <- tryCatch(js$result$uv, error = function(e) NA)
  list(uv_index = uv_idx)
}

# 5) PROCESSAR SUBMISSÕES 🚀
historico_path <- file.path(output_folder, "dados_historico_enriquecido.csv")
historico_existente <- if (file.exists(historico_path)) {
  data.table::fread(
    historico_path,
    stringsAsFactors = FALSE,
    data.table = FALSE,
    colClasses = list(character = "data_original")
  )
} else {
  data.frame(row_uid = character(0), tester_id = character(0), email = character(0),
             data_original = character(0),
             temperatura_c = numeric(0), humidade = numeric(0), aqi = numeric(0),
             uv_index = numeric(0), stringsAsFactors = FALSE)
}
novas_linhas_enriquecidas <- list()

for (i in seq_len(nrow(novas))) {
  row <- novas[i, , drop = FALSE]
  uid <- as.character(row$row_uid)
  tester_id <- as.character(row$tester_id)
  tester_email <- as.character(row$email %||% NA_character_)
  cidade <- if("cidade" %in% names(row) && !is.na(row$cidade) && trimws(as.character(row$cidade)) != "") as.character(row$cidade) else NULL
  data_submissao <- row$data
  message("Processando ", i, "/", nrow(novas), " (", uid, " — ", tester_id, ")")
  
  # Geocodificação: se cidade desconhecida, usa Lisboa por defeito
  geo <- if(!is.null(cidade)) geocode_city(cidade) else geocode_city("Lisbon,PT")
  if (is.null(geo)) {
    message("⚠️ Sem geocodificação para: ", cidade %||% "N/A", "; marcando como processado.")
    processed_ids <- c(processed_ids, uid)
    saveRDS(processed_ids, processed_ids_file)
    next
  }
  lat <- geo$lat; lon <- geo$lon
  
  ow <- get_openweather(lat, lon)
  temp_c <- ow$temp %||% NA
  hum <- ow$humidity %||% NA
  weather_desc <- ow$weather_desc %||% NA
  Sys.sleep(0.4)
  
  iq <- get_iqair(lat, lon)
  aqi_val <- iq$aqi_us %||% NA
  Sys.sleep(0.4)
  
  uv <- get_openuv(lat, lon)
  uv_index <- uv$uv_index %||% NA
  Sys.sleep(0.4)
  
  # Enriquecer row
  row_env_df <- as.data.frame(row, stringsAsFactors = FALSE)
  row_env_df$temperatura_c <- temp_c
  row_env_df$humidade <- hum
  row_env_df$weather_desc <- weather_desc
  row_env_df$aqi <- aqi_val
  row_env_df$uv_index <- uv_index
  row_env_df$lat <- lat; row_env_df$lon <- lon
  
  novas_linhas_enriquecidas[[length(novas_linhas_enriquecidas) + 1]] <- row_env_df
  
  tid <- tester_id
  historico_tester <- historico_existente %>%
    dplyr::filter(tester_id == tid) %>%
    dplyr::bind_rows(row_env_df) %>%
    dplyr::distinct(row_uid, .keep_all = TRUE) %>%
    dplyr::arrange(data)
  
  
  cols_to_check <- c("temperatura_c", "humidade", "aqi", "uv_index", "lat", "lon")
  for (col in cols_to_check) {
    if (!col %in% names(historico_tester)) {
      historico_tester[[col]] <- numeric(nrow(historico_tester))
    }
  }
  
  historico_tester <- historico_tester %>%
    dplyr::bind_rows(row_env_df) %>%
    dplyr::distinct(row_uid, .keep_all = TRUE) %>%
    dplyr::arrange(data)
  
  
  # Correlações
  cor_temp_sono <- NA; cor_aqi_energia <- NA
  cor_text <- "Insuficientes dados para calcular correlações."
  if (nrow(historico_tester) >= 2) {
    if (all(c("temperatura_c","horas_sono") %in% names(historico_tester))) {
      cor_temp_sono <- suppressWarnings(cor(historico_tester$temperatura_c, historico_tester$horas_sono, use = "complete.obs"))
    }
    if (all(c("aqi","energia") %in% names(historico_tester))) {
      cor_aqi_energia <- suppressWarnings(cor(historico_tester$aqi, historico_tester$energia, use = "complete.obs"))
    }
    cor_text <- glue::glue("Correlação (histórico): Sono vs Temp = {round(cor_temp_sono,2)}, AQI vs Energia = {round(cor_aqi_energia,2)}")
  }
  
  # ================================================================
  # 🧮 Cálculo dos Índices Compostos (Ambiente e Bem-Estar)
  # ================================================================
  for (col in c("temperatura_c", "humidade", "aqi", "uv_index", "energia", "humor", "stress", "atividade", "agua", "horas_sono")) {
    if (col %in% names(historico_tester)) {
      historico_tester[[col]] <- suppressWarnings(as.numeric(historico_tester[[col]]))
    }
  }
  
  historico_tester <- historico_tester %>%
    mutate(
      indice_ambiente = scales::rescale(
        (100 - aqi) * 0.4 +
          (100 - uv_index * 10) * 0.2 +
          (100 - abs(temperatura_c - 22) * 4) * 0.2 +
          (100 - humidade) * 0.2,
        to = c(0, 5)
      ),
      indice_bem_estar = scales::rescale(
        (energia * 0.3 + humor * 0.3 + horas_sono * 0.2 +
           atividade * 0.1 + (10 - stress) * 0.1),
        to = c(0, 5)
      )
    )
  
  # Últimos índices (para o relatório)
  indice_ambiente_atual <- round(tail(historico_tester$indice_ambiente, 1), 2)
  indice_bem_estar_atual <- round(tail(historico_tester$indice_bem_estar, 1), 2)
  
  
  message("📊 Diagnóstico do histórico do tester:")
  if (!exists("historico_tester")) {
    message("❌ 'historico_tester' não existe!")
  } else {
    message("✅ Linhas: ", nrow(historico_tester))
    message("✅ Colunas: ", paste(names(historico_tester), collapse = ", "))
    print(head(historico_tester))
  }
  
  
  # ================================================================
  # 📊 Geração dos Gráficos (versão melhorada e robusta)
  # ================================================================
  
  graf1_path <- file.path(output_folder, paste0("graf_bemestar_ambiente_", uid, ".png"))
  graf2_path <- file.path(output_folder, paste0("graf_sono_temp_", uid, ".png"))
  graf3_path <- file.path(output_folder, paste0("graf_indices_tempo_", uid, ".png"))
  graf4_path <- file.path(output_folder, paste0("graf_radar_bemestar_", uid, ".png"))
  
  graf1 <- graf2 <- graf3 <- graf4 <- NULL
  
  # Garantir que colunas necessárias existem
  cols_ok <- names(historico_tester)
  
  # Gráfico 1: Correlação Bem-Estar vs Ambiente
  if (nrow(historico_tester) >= 2 && all(c("indice_ambiente", "indice_bem_estar") %in% cols_ok)) {
    graf1 <- ggplot(historico_tester, aes(x = indice_ambiente, y = indice_bem_estar)) +
      geom_point(size = 3, alpha = 0.7, color = "#009E73") +
      geom_smooth(method = "lm", se = TRUE, color = "#0072B2") +
      labs(
        title = "Correlação: Índice de Bem-Estar vs Índice Ambiental",
        x = "Índice Ambiental",
        y = "Índice de Bem-Estar"
      ) +
      theme_minimal(base_size = 14)
  }
  
  # Gráfico 2: Sono vs Temperatura
  if (nrow(historico_tester) >= 2 && all(c("temperatura_c", "horas_sono") %in% cols_ok)) {
    graf2 <- ggplot(historico_tester, aes(x = temperatura_c, y = horas_sono)) +
      geom_point(size = 3, alpha = 0.6, color = "#E69F00") +
      geom_smooth(method = "lm", se = TRUE, color = "#D55E00") +
      labs(
        title = "Relação entre Temperatura e Horas de Sono",
        x = "Temperatura (°C)",
        y = "Horas de Sono"
      ) +
      theme_minimal(base_size = 14)
  }
  
  # Gráfico 3: Evolução temporal dos índices
  if (nrow(historico_tester) >= 2 && all(c("data", "indice_bem_estar", "indice_ambiente") %in% cols_ok)) {
    graf3 <- ggplot(historico_tester, aes(x = as.Date(data))) +
      geom_line(aes(y = indice_bem_estar, color = "Bem-Estar"), linewidth = 1.2) +
      geom_line(aes(y = indice_ambiente, color = "Ambiente"), linewidth = 1.2) +
      scale_color_manual(values = c("Bem-Estar" = "#009E73", "Ambiente" = "#56B4E9")) +
      labs(
        title = "Evolução Temporal dos Índices",
        x = "Data",
        y = "Índice (0–5)",
        color = "Indicador"
      ) +
      theme_minimal(base_size = 14)
  }
  
  # Gráfico 4: Radar das métricas de bem-estar
  if (requireNamespace("fmsb", quietly = TRUE) &&
      all(c("energia", "humor", "stress", "atividade", "agua", "horas_sono") %in% cols_ok)) {
    
    library(fmsb)
    radar_data <- historico_tester %>%
      dplyr::select(energia, humor, stress, atividade, agua, horas_sono) %>%
      summarise(across(everything(), ~mean(.x, na.rm = TRUE))) %>%
      as.data.frame()
    
    radar_data <- rbind(rep(10, ncol(radar_data)), rep(0, ncol(radar_data)), radar_data)
    
    png(graf4_path, width = 800, height = 600)
    fmsb::radarchart(
      radar_data,
      axistype = 1,
      pcol = "#0072B2",
      pfcol = scales::alpha("#0072B2", 0.3),
      plwd = 2,
      title = "Radar de Bem-Estar (médias recentes)"
    )
    dev.off()
  }
  
  # Salvar gráficos criados
  if (!is.null(graf1)) ggsave(graf1_path, graf1, width = 6, height = 4)
  if (!is.null(graf2)) ggsave(graf2_path, graf2, width = 6, height = 4)
  if (!is.null(graf3)) ggsave(graf3_path, graf3, width = 6, height = 4)
  
  
  # ================================================================
  # 🧩 Garantir que todas as variáveis usadas no relatório existem
  # ================================================================
  
  # Função auxiliar para obter o último valor de uma coluna, ou "N/A" se não existir
  get_last <- function(col) {
    if (col %in% names(historico_tester)) {
      val <- tail(historico_tester[[col]], 1)
      if (is.null(val) || is.na(val) || val == "") return("N/A")
      return(val)
    } else {
      return("N/A")
    }
  }
  
  # Variáveis de bem-estar
  horas_sono <- get_last("horas_sono")
  stress     <- get_last("stress")
  atividade  <- get_last("atividade")
  agua       <- get_last("agua")
  energia    <- get_last("energia")
  humor      <- get_last("humor")
  
  # Variáveis ambientais
  temp_c       <- get_last("temperatura_c")
  hum           <- get_last("humidade")
  aqi_val       <- get_last("aqi")
  uv_index      <- get_last("uv_index")
  weather_desc  <- get_last("weather_desc")
  
  # Índices calculados
  indice_ambiente_atual  <- get_last("indice_ambiente")
  indice_bem_estar_atual <- get_last("indice_bem_estar")
  
  # ================================================================
  # 🔒 Garantir que variáveis usadas no glue existem e não são NULL
  # ================================================================
  seguras <- c(
    "horas_sono", "stress", "atividade", "agua", "energia", "humor",
    "temp_c", "hum", "aqi_val", "uv_index", "weather_desc",
    "indice_ambiente_atual", "indice_bem_estar_atual",
    "cor_text", "conclusao", "recomendacoes", 
    "cidade", "tester_email", "tester_id", "data_submissao"
  )
  
  for (v in seguras) {
    if (!exists(v, inherits = TRUE) || is.null(get(v, inherits = TRUE))) {
      assign(v, "N/A", envir = environment())
    } else {
      val <- get(v, inherits = TRUE)
      if (is.na(val) || (is.character(val) && val == "")) {
        assign(v, "N/A", envir = environment())
      }
    }
  }
  
  
  
  # ================================================================
  # 🧾 Texto de Conclusões e Recomendações
  # ================================================================
  mean_sono <- if (all(is.na(historico_tester$horas_sono))) NA else round(mean(historico_tester$horas_sono, na.rm = TRUE), 1)
  
  conclusao <- paste0(
    "- O teu sono médio recente é de ", ifelse(is.na(mean_sono), "N/A", paste0(mean_sono, " h.")), "\n",
    "- Índice Ambiental atual: ", indice_ambiente_atual, " / 5\n",
    "- Índice de Bem-Estar atual: ", indice_bem_estar_atual, " / 5\n",
    "- A temperatura atual é ", ifelse(is.na(temp_c), "N/A", paste0(temp_c, " °C")),
    " e o AQI é ", ifelse(is.na(aqi_val), "N/A", aqi_val), ".\n",
    if (!is.na(cor_temp_sono) && cor_temp_sono < -0.3) "🌡️ Verifica-se correlação negativa: temperatura vs sono.\n" else "",
    if (!is.na(cor_aqi_energia) && cor_aqi_energia < -0.3) "💨 AQI parece impactar a tua energia.\n" else ""
  )
  
  recomendacoes <- glue::glue(
    "✨ **Recomendações personalizadas**\n\n",
    "- 💧 Mantém boa hidratação (ideal: {agua} copos/dia ou mais).\n",
    "- ☀️ Se o índice UV ({uv_index %||% 'N/A'}) estiver elevado (>6), evita exposição prolongada.\n",
    "- 🌫️ Se o AQI for >100, limita atividades intensas no exterior.\n",
    "- 🌙 Em noites quentes (>22°C), areja o quarto antes de dormir.\n"
  )
  
  pdf_out <- file.path(output_folder, glue::glue('Relatorio_ByoSync_{tester_id}_{format(Sys.Date(), "%Y%m%d")}_{uid}.pdf'))
  rmd_file <- tempfile(fileext = ".Rmd")
}



# Data do relatório
data_hoje <- format(Sys.Date(), "%d %B %Y") 


# Construir o RMarkdown sem duplicar YAML / chunks
rmd_text <- glue::glue('
---
title: "Relatório ByoSync Health"
author: "ByoSync Health"
date: "{data_hoje}"
output:
  pdf_document:
    latex_engine: xelatex
    toc: false
    number_sections: false
---

```{{r setup, include=FALSE}}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)
library(ggplot2)
library(dplyr)
library(lubridate)
library(glue)
```

## 🧾 Identificação
| Campo | Valor |
| ----- | ------ |
| **Tester ID** | {tester_id} |
| **Email** | {tester_email} |
| **Cidade** | {ifelse(is.null(cidade), "Lisboa (Default)", cidade)} |
| **Data de submissão** | {format(data_submissao, "%Y-%m-%d %H:%M")} |

---

## 💧 Dados Submetidos
| Métrica | Valor |
| -------- | ------ |
| Sono | {horas_sono} |
| Stress | {stress} |
| Atividade | {atividade} |
| Água | {agua} |
| Energia | {energia} |
| Humor | {humor} |

---

## 🌦️ Ambiente
| Parâmetro | Valor |
| ---------- | ------ |
| Temperatura | {ifelse(is.null(temp_c), "N/A", temp_c)} °C |
| Humidade | {ifelse(is.null(hum), "N/A", hum)}% |
| AQI | {ifelse(is.null(aqi_val), "N/A", aqi_val)} |
| UV | {ifelse(is.null(uv_index), "N/A", uv_index)} |
| Condição | {ifelse(is.null(weather_desc), "N/A", weather_desc)} |

---

## 📈 Índices Gerais
| Índice | Valor |
| ------- | ------ |
| **Índice Ambiental** | {indice_ambiente_atual} / 5 |
| **Índice de Bem-Estar** | {indice_bem_estar_atual} / 5 |

---

## 📊 Correlações
{cor_text}

---

## ✨ Conclusões
{conclusao}

---

## 💡 Recomendações
{recomendacoes}

', .open = "{", .close = "}", .envir = environment()) 

# Adicionar bloco de gráficos fora do glue (para evitar erro de parsing)
rmd_text <- paste0(rmd_text, '
---

## 📉 Gráficos e Visualizações

```{r echo=FALSE, warning=FALSE, message=FALSE, fig.width=6, fig.height=4, out.width="70%", fig.align="center"}
graf1_path_local <- "', graf1_path, '"
graf2_path_local <- "', graf2_path, '"
graf3_path_local <- "', graf3_path, '"
graf4_path_local <- "', graf4_path, '"

if (file.exists(graf1_path_local)) knitr::include_graphics(graf1_path_local)
if (file.exists(graf2_path_local)) knitr::include_graphics(graf2_path_local)
if (file.exists(graf3_path_local)) knitr::include_graphics(graf3_path_local)
if (file.exists(graf4_path_local)) knitr::include_graphics(graf4_path_local)
')


writeLines(rmd_text, rmd_file)

message("graf1_path existe? ", file.exists(graf1_path))
message("graf2_path existe? ", file.exists(graf2_path))

# Fallback PDF -> DOCX
ok <- FALSE
tryCatch({
  rmarkdown::render(
    input = rmd_file,
    output_file = basename(pdf_out),
    output_dir = dirname(pdf_out),
    quiet = TRUE
  )
  ok <- file.exists(pdf_out)
}, error = function(e) {
  message("❌ Erro ao renderizar PDF: ", e$message)
  ok <<- FALSE
})

final_report <- NULL

if (ok) {
  final_report <- pdf_out
} else {
  docx_out <- sub("\\.pdf$", ".docx", pdf_out)
  message("A tentar gerar DOCX como fallback...")
  try({
    rmarkdown::render(
      input = rmd_file,
      output_format = "word_document",
      output_file = basename(docx_out),
      output_dir = dirname(docx_out),
      quiet = TRUE
    )
  }, silent = TRUE)
  if (file.exists(docx_out)) final_report <- docx_out
}

if (is.null(final_report)) {
  message("❌ Não foi possível gerar relatório (PDF ou DOCX). Marcar para re-tentativa mais tarde.")
  if (file.exists(rmd_file)) file.remove(rmd_file)
  tryCatch({ next }, error = function(e) return(invisible(NULL)))
}

message("✅ Relatório gerado: ", final_report)


# Envio por email
if (produce_and_send_email && !is.na(tester_email) && nzchar(tester_email)) {
  email_msg <- tryCatch({
    blastula::compose_email(body = blastula::md(glue::glue(
      "Olá {tester_id},

Segue o teu relatório ByoSync Health gerado automaticamente.

Em anexo: relatório completo com análises, gráficos e recomendações.

Abraço,
ByoSync Health"
    )))
  }, error = function(e) {
    message("❌ Erro a compor email: ", e$message)
    NULL
  })
  
  if (!is.null(email_msg)) {
    email_msg <- email_msg %>% blastula::add_attachment(file = final_report)
    tryCatch({
      blastula::smtp_send(
        email = email_msg,
        to = tester_email,
        from = email_from,
        subject = glue::glue("Relatório ByoSync Health - {tester_id} - {format(Sys.Date(), '%Y-%m-%d')}"),
        credentials = blastula::creds_file(file.path(output_folder, "blastula_creds"))
      )
      message("✅ Email enviado para: ", tester_email)
    }, error = function(e){
      message("❌ Erro envio email (verificar 'blastula_creds' e SMTP): ", e$message)
    })
  }
} else {
  message("ℹ️ Email não enviado (produce_and_send_email = FALSE ou email ausente/inválido: ", tester_email %||% "N/A", ").")
}

# Limpeza
if (file.exists(rmd_file)) file.remove(rmd_file)
if (file.exists(graf1_path)) file.remove(graf1_path)
if (file.exists(graf2_path)) file.remove(graf2_path)

processed_ids <- c(processed_ids, uid)
saveRDS(processed_ids, processed_ids_file)
message("Submissão marcada como processada: ", uid)
message("Fim de processamento de ", uid, ".")

# Guardar histórico
if (length(novas_linhas_enriquecidas) > 0) {
  novas_linhas_df <- dplyr::bind_rows(novas_linhas_enriquecidas)
  if ("data_original" %in% names(historico_existente)) historico_existente$data_original <- as.character(historico_existente$data_original)
  if ("data_original" %in% names(novas_linhas_df)) novas_linhas_df$data_original <- as.character(novas_linhas_df$data_original)
  
  historico_completo_final <- dplyr::bind_rows(historico_existente, novas_linhas_df) %>%
    dplyr::distinct(row_uid, .keep_all = TRUE)
  
  data.table::fwrite(historico_completo_final, historico_path, row.names = FALSE)
  message("✅ Histórico enriquecido salvo em: ", historico_path)
} else {
  message("ℹ️ Nenhuma linha nova para adicionar ao histórico enriquecido.")
} 

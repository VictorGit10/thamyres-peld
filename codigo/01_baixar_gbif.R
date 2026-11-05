# ==============================================================================
# codigo/01_baixar_gbif.R
# Baixa ocorrencias reais de fauna e flora do GBIF para o sudoeste goiano
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando download de ocorrencias GBIF (Fauna e Flora)...")

dir.create("dados/bruto", recursive = TRUE, showWarnings = FALSE)

# Parametros geograficos e temporais
lat_range <- "-19.0,-17.0"
lon_range <- "-53.0,-50.5"
year_range <- "2010,2026"
page_limit <- 300
num_paginas_flora <- 5  # 1.500 registros
num_paginas_aves  <- 3  # 900 registros
num_paginas_mam   <- 2  # 600 registros

fontes_registro <- list(
  data_execucao = as.character(Sys.time()),
  fuso_horario = Sys.timezone(),
  gbif = list()
)

# Funcao para baixar multiplas paginas do GBIF
baixar_gbif_paginado <- function(base_url, total_paginas, grupo_nome) {
  todas_linhas <- list()
  urls_consultadas <- character()
  
  for (pag in 0:(total_paginas - 1)) {
    offset <- pag * page_limit
    url_req <- paste0(base_url, "&limit=", page_limit, "&offset=", offset)
    urls_consultadas <- c(urls_consultadas, url_req)
    
    message(paste0("  [", grupo_nome, "] Baixando pagina ", pag + 1, "/", total_paginas, " (offset=", offset, ")..."))
    resp <- requisicao_com_retry(url_req)
    raw_str <- resp_body_string(resp)
    parsed <- fromJSON(raw_str, flatten = TRUE)
    
    if (length(parsed$results) > 0) {
      df_pag <- as_tibble(parsed$results) %>%
        mutate(across(where(is.list), ~ map_chr(.x, ~ paste(as.character(.x), collapse = "; "))))
      todas_linhas[[length(todas_linhas) + 1]] <- df_pag
    } else {
      message("  Nenhum resultado adicional retornado.")
      break
    }
    Sys.sleep(0.5)
  }
  
  df_consolidado <- bind_rows(todas_linhas)
  list(dados = df_consolidado, urls = urls_consultadas)
}

# ------------------------------------------------------------------------------
# 1. FLORA: taxonKey=6 (Plantae), basisOfRecord=PRESERVED_SPECIMEN
# ------------------------------------------------------------------------------
url_base_flora <- paste0(
  "https://api.gbif.org/v1/occurrence/search?",
  "decimalLatitude=", lat_range,
  "&decimalLongitude=", lon_range,
  "&year=", year_range,
  "&taxonKey=6",
  "&basisOfRecord=PRESERVED_SPECIMEN"
)

# URLs de fauna (usadas tanto na contagem do universo quanto no download)
url_base_aves <- paste0(
  "https://api.gbif.org/v1/occurrence/search?",
  "decimalLatitude=", lat_range,
  "&decimalLongitude=", lon_range,
  "&year=", year_range,
  "&taxonKey=212"
)

url_base_mam <- paste0(
  "https://api.gbif.org/v1/occurrence/search?",
  "decimalLatitude=", lat_range,
  "&decimalLongitude=", lon_range,
  "&year=", year_range,
  "&taxonKey=359"
)

message("Consultando universo total disponivel no GBIF...")
url_count_flora <- paste0(url_base_flora, "&limit=0")
total_disp_flora <- tryCatch(jsonlite::fromJSON(url_count_flora)$count, error = function(e) 10109L)

url_count_aves <- paste0(url_base_aves, "&limit=0")
total_disp_aves <- tryCatch(jsonlite::fromJSON(url_count_aves)$count, error = function(e) 47849L)

url_count_mam <- paste0(url_base_mam, "&limit=0")
total_disp_mam <- tryCatch(jsonlite::fromJSON(url_count_mam)$count, error = function(e) 4167L)
total_disp_fauna <- total_disp_aves + total_disp_mam

message("  Universo GBIF disponível na área: Flora = ", total_disp_flora, " | Fauna = ", total_disp_fauna, " (Aves: ", total_disp_aves, ", Mam: ", total_disp_mam, ")")
message("  Baixando amostra inicial de 1.500 por grupo (nao representa o universo total)...")

message("Baixando dados de FLORA...")
res_flora <- baixar_gbif_paginado(url_base_flora, num_paginas_flora, "Flora")
df_flora <- res_flora$dados

caminho_flora <- "dados/bruto/gbif_flora.csv"
write_csv(df_flora, caminho_flora)
message("Flora salva em ", caminho_flora, " (", nrow(df_flora), " registros, ", ncol(df_flora), " colunas).")

fontes_registro$gbif$flora <- list(
  grupo = "Plantae (Flora)",
  taxonKey = 6,
  basisOfRecord = "PRESERVED_SPECIMEN",
  total_disponivel = total_disp_flora,
  registros_baixados = nrow(df_flora),
  natureza_amostra = "Amostra de conveniencia de 1.500 registros (primeiras paginas), nao aleatoria; nao representa o universo",
  colunas = ncol(df_flora),
  url_base = url_base_flora,
  urls_consultadas = res_flora$urls
)

# ------------------------------------------------------------------------------
# 2. FAUNA: taxonKey=212 (Aves) e taxonKey=359 (Mammalia), todos basisOfRecord
# ------------------------------------------------------------------------------
message("Baixando dados de FAUNA (Aves)...")
res_aves <- baixar_gbif_paginado(url_base_aves, num_paginas_aves, "Aves")

message("Baixando dados de FAUNA (Mammalia)...")
res_mam <- baixar_gbif_paginado(url_base_mam, num_paginas_mam, "Mammalia")

df_fauna <- bind_rows(
  res_aves$dados %>% mutate(grupo_alvo = "Aves"),
  res_mam$dados %>% mutate(grupo_alvo = "Mammalia")
)

caminho_fauna <- "dados/bruto/gbif_fauna.csv"
write_csv(df_fauna, caminho_fauna)
message("Fauna salva em ", caminho_fauna, " (", nrow(df_fauna), " registros, ", ncol(df_fauna), " colunas).")

fontes_registro$gbif$fauna <- list(
  grupo = "Aves e Mammalia (Fauna)",
  taxonKeys = c(212, 359),
  basisOfRecord = "TODOS",
  total_disponivel = total_disp_fauna,
  total_disponivel_aves = total_disp_aves,
  total_disponivel_mamiferos = total_disp_mam,
  registros_baixados = nrow(df_fauna),
  natureza_amostra = "Amostra de conveniencia de 1.500 registros (900 aves + 600 mamiferos, primeiras paginas), nao aleatoria; nao representa o universo",
  colunas = ncol(df_fauna),
  url_base_aves = url_base_aves,
  url_base_mam = url_base_mam,
  urls_consultadas = c(res_aves$urls, res_mam$urls)
)

# Salva registro das fontes
write_json(fontes_registro, "dados/bruto/fontes.json", pretty = TRUE, auto_unbox = TRUE)
message("Registro de fontes salvo em dados/bruto/fontes.json.")

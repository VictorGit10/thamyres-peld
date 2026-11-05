# ==============================================================================
# codigo/02_baixar_ibge.R
# Baixa dados socioeconomicos (SIDRA) e malha/centroides municipais (IBGE)
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando download de dados municipais e socioeconomicos do IBGE...")

dir.create("dados/bruto/malhas", recursive = TRUE, showWarnings = FALSE)

municipios_info <- tibble(
  id_local = paste0("LOC_", c("CAI", "JAT", "MIN", "PER", "RVE", "SER")),
  nome_local = c("Caiapônia", "Jataí", "Mineiros", "Perolândia", "Rio Verde", "Serranópolis"),
  municipio = c("Caiapônia", "Jataí", "Mineiros", "Perolândia", "Rio Verde", "Serranópolis"),
  codigo_ibge = c("5204409", "5211909", "5213103", "5216452", "5218805", "5220504"),
  tipo_area = c("Entorno PELD", "Sede PELD / Polo Regional", "Entorno PELD / Parque Emas", "Entorno PELD", "Polo Agroindustrial", "Entorno PELD / RPPN"),
  uc = c("APA Serra das Araras (proxima)", "APA Municipal", "Parna das Emas (entorno)", "Area de amortecimento", "Sem UC de protecao integral", "RPPN Pousada das Araras"),
  obs = c("Regiao ecotonica Cerrado-Floresta", "Campus Jatai / Nucleo PELD", "Importante divisor hidrografico", "Uso agropastoril e remanescentes", "Predominio de lavouras intensivas", "Remanescentes expressivos de Cerrado rupestre")
)

# ------------------------------------------------------------------------------
# 1. Baixar Malhas e calcular centroides/areas
# ------------------------------------------------------------------------------
message("Baixando malhas geograficas do IBGE e calculando centroides...")

calcular_centroide_coords <- function(coords) {
  # Coords e matriz Nx2 [lon, lat]
  # Se poligono fechado, ignora duplicata final se presente
  if (nrow(coords) > 1 && identical(coords[1, ], coords[nrow(coords), ])) {
    pts <- coords[-nrow(coords), , drop = FALSE]
  } else {
    pts <- coords
  }
  c(lon = mean(pts[, 1], na.rm = TRUE), lat = mean(pts[, 2], na.rm = TRUE))
}

centroides_lista <- list()

for (i in seq_len(nrow(municipios_info))) {
  cod <- municipios_info$codigo_ibge[i]
  nome <- municipios_info$municipio[i]
  url_malha <- paste0("https://servicodados.ibge.gov.br/api/v3/malhas/municipios/", cod, "?formato=application/vnd.geo+json")
  
  message("  Baixando malha de ", nome, " (", cod, ")...")
  resp <- requisicao_com_retry(url_malha)
  raw_body <- resp_body_raw(resp)
  
  # Decomprime gzip se necessario
  if (length(raw_body) >= 2 && raw_body[1] == as.raw(0x1f) && raw_body[2] == as.raw(0x8b)) {
    raw_str <- memDecompress(raw_body, type = "gzip", asChar = TRUE)
  } else {
    raw_str <- resp_body_string(resp)
  }
  
  caminho_geo <- paste0("dados/bruto/malhas/", cod, ".geojson")
  writeLines(raw_str, caminho_geo, useBytes = TRUE)
  
  geo_parsed <- fromJSON(raw_str, simplifyVector = FALSE)
  feat <- geo_parsed$features[[1]]
  geom_type <- feat$geometry$type
  coords_raw <- feat$geometry$coordinates
  
  # Extrai matriz de pontos
  if (geom_type == "Polygon") {
    # Anel externo
    pts <- do.call(rbind, lapply(coords_raw[[1]], unlist))
  } else if (geom_type == "MultiPolygon") {
    # Maior poligono
    polys <- coords_raw
    n_pts <- sapply(polys, function(p) length(p[[1]]))
    maior_idx <- which.max(n_pts)
    pts <- do.call(rbind, lapply(polys[[maior_idx]][[1]], unlist))
  } else {
    stop("Tipo de geometria nao suportado: ", geom_type)
  }
  
  cent <- calcular_centroide_coords(pts)
  
  centroides_lista[[i]] <- tibble(
    codigo_ibge = cod,
    lat = cent["lat"],
    lon = cent["lon"]
  )
}

df_centroides <- bind_rows(centroides_lista)

# Juntando com dados dos locais
municipios_locais <- municipios_info %>%
  left_join(df_centroides, by = "codigo_ibge")

write_csv(municipios_locais, "dados/bruto/municipios_locais.csv")
message("Locais municipais salvos em dados/bruto/municipios_locais.csv.")

# ------------------------------------------------------------------------------
# 2. Consultar SIDRA (Censo 2022, Censo 2010, PIB 2021)
# ------------------------------------------------------------------------------
message("Consultando dados socioeconomicos na API SIDRA/IBGE...")

codigos_str <- paste(municipios_info$codigo_ibge, collapse = ",")

# Tabela 9514: Censo 2022 - Populacao residente
url_pop2022 <- paste0("https://apisidra.ibge.gov.br/values/t/9514/n6/", codigos_str, "/v/93/p/last%201")
resp_pop2022 <- requisicao_com_retry(url_pop2022)
raw_pop2022 <- fromJSON(resp_body_string(resp_pop2022))
df_pop2022 <- as_tibble(raw_pop2022[-1, ]) %>%
  transmute(
    codigo_ibge = D1C,
    municipio_sidra = D1N,
    populacao_2022 = as.numeric(V),
    ano_censo_pop = as.integer(D3C)
  )

# Tabela 200: Censo 2010 - Populacao Urbana e Rural
# c1 = 0 (Total), 1 (Urbana), 2 (Rural)
url_pop2010 <- paste0("https://apisidra.ibge.gov.br/values/t/200/n6/", codigos_str, "/v/93/p/last%201/c1/all")
resp_pop2010 <- requisicao_com_retry(url_pop2010)
raw_pop2010 <- fromJSON(resp_body_string(resp_pop2010))
df_pop2010_raw <- as_tibble(raw_pop2010[-1, ])

df_pop2010 <- df_pop2010_raw %>%
  filter(D4N %in% c("Total", "Rural", "Urbana")) %>%
  transmute(
    codigo_ibge = D1C,
    situacao = D4N,
    valor = as.numeric(V)
  ) %>%
  pivot_wider(names_from = situacao, values_from = valor, names_prefix = "pop2010_") %>%
  mutate(
    pop_rural_pct = round((pop2010_Rural / pop2010_Total) * 100, 2)
  )

# Tabela 5938: PIB 2021 - Variável 37 (PIB total em mil R$) e 513 (Agropecuaria em mil R$)
url_pib <- paste0("https://apisidra.ibge.gov.br/values/t/5938/n6/", codigos_str, "/v/37,513/p/2021")
resp_pib <- requisicao_com_retry(url_pib)
raw_pib <- fromJSON(resp_body_string(resp_pib))
df_pib_raw <- as_tibble(raw_pib[-1, ])

df_pib <- df_pib_raw %>%
  transmute(
    codigo_ibge = D1C,
    variavel_cod = D2C,
    ano_pib = as.integer(D3C),
    valor_mil_reais = as.numeric(V)
  ) %>%
  pivot_wider(names_from = variavel_cod, values_from = valor_mil_reais) %>%
  rename(pib_mil_reais = `37`, agro_mil_reais = `513`) %>%
  mutate(
    agro_pct_pib = round((agro_mil_reais / pib_mil_reais) * 100, 2)
  )

# Consolida tabela socioeconomica
df_social <- df_pop2022 %>%
  left_join(df_pop2010 %>% select(codigo_ibge, pop_rural_pct), by = "codigo_ibge") %>%
  left_join(df_pib %>% select(codigo_ibge, ano_pib, pib_mil_reais, agro_pct_pib), by = "codigo_ibge") %>%
  mutate(
    ano = ano_pib, # Ano de referencia do PIB (2021)
    populacao = populacao_2022,
    # PIB per capita: (PIB total em R$) / Populacao 2022 (com ressalva de anos distintos no relatorio)
    pib_per_capita = round((pib_mil_reais * 1000) / populacao_2022, 2),
    fonte = "IBGE/SIDRA (Tabelas 9514, 200, 5938)"
  ) %>%
  select(
    codigo_ibge,
    ano,
    populacao,
    pop_rural_pct,
    pib_mil_reais,
    pib_per_capita,
    agro_pct_pib,
    fonte
  )

write_csv(df_social, "dados/bruto/social_municipios.csv")
message("Dados sociais salvos em dados/bruto/social_municipios.csv (", nrow(df_social), " municipios).")

# ------------------------------------------------------------------------------
# 3. Atualizar registro em dados/bruto/fontes.json
# ------------------------------------------------------------------------------
fontes_atuais <- list()
if (file.exists("dados/bruto/fontes.json")) {
  fontes_atuais <- fromJSON("dados/bruto/fontes.json")
}

fontes_atuais$ibge <- list(
  data_execucao = as.character(Sys.time()),
  municipios_selecionados = municipios_info$municipio,
  codigos_ibge = municipios_info$codigo_ibge,
  url_malhas = "https://servicodados.ibge.gov.br/api/v3/malhas/municipios/{codigo}?formato=application/vnd.geo+json",
  sidra_tabelas = list(
    pop_2022 = list(tabela = 9514, variavel = 93, url = url_pop2022),
    pop_rural_2010 = list(tabela = 200, variavel = 93, classificacao = "c1/all", url = url_pop2010),
    pib_2021 = list(tabela = 5938, variaveis = c(37, 513), url = url_pib)
  )
)

write_json(fontes_atuais, "dados/bruto/fontes.json", pretty = TRUE, auto_unbox = TRUE)
message("Fontes atualizadas com sucesso em dados/bruto/fontes.json.")

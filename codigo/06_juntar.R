# ==============================================================================
# codigo/06_juntar.R
# Monta a tabela integrada de analise (biodiversidade x paisagem x socioeconomia)
# Grao: local x unidade de agregacao x grupo
# Separa claramente contagem real de individuos vs registros de presenca
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando montagem da tabela integrada de analise...")

# 1. Carrega tabelas canônicas
banco_local <- read_csv("dados/banco/local.csv", show_col_types = FALSE)
banco_campanha <- read_csv("dados/banco/campanha.csv", show_col_types = FALSE)
banco_observacao <- read_csv("dados/banco/observacao.csv", show_col_types = FALSE)
banco_paisagem <- read_csv("dados/banco/paisagem.csv", show_col_types = FALSE)
banco_social <- read_csv("dados/banco/social.csv", show_col_types = FALSE)

# 2. Agregacao ecologica por unidade de agregacao x grupo
message("Agregando riqueza, registros de presenca e contagens reais por unidade...")

bio_agregada <- banco_observacao %>%
  group_by(id_local, id_campanha, grupo) %>%
  summarise(
    ano = if (all(is.na(ano_original))) NA_integer_ else as.integer(round(mean(na.omit(ano_original)))),
    riqueza_especies = n_distinct(especie),
    n_registros = n(),
    n_presencas = sum(presenca, na.rm = TRUE),
    # Soma de individuos estritamente para registros onde houve contagem numerica real
    n_individuos_reais = if (all(is.na(individuos))) NA_real_ else sum(individuos, na.rm = TRUE),
    tem_contagem_numerica = any(!is.na(individuos)),
    n_incerteza_conhecida = sum(!is.na(incerteza_metros)),
    pct_incerteza_conhecida = round(mean(!is.na(incerteza_metros)) * 100, 1),
    n_valido_paisagem = sum(valido_paisagem, na.rm = TRUE),
    pct_valido_paisagem = round(mean(valido_paisagem) * 100, 1),
    .groups = "drop"
  )

message("Total de unidades agregadas: ", nrow(bio_agregada))

# 3. Preparacao da Paisagem em diferentes escalas (municipio, buffer 5km, buffer 10km)
mapear_ano_mapbiomas <- function(anos) {
  anos_mb <- c(2015, 2020, 2024)
  sapply(anos, function(a) {
    if (is.na(a)) return(2020)
    anos_mb[which.min(abs(anos_mb - a))]
  })
}

bio_agregada <- bio_agregada %>%
  mutate(ano_mapbiomas = mapear_ano_mapbiomas(ano))

# Pivota paisagem para ter colunas por escala
paisagem_larga <- banco_paisagem %>%
  mutate(escala_sufixo = case_when(
    buffer_m == 0 ~ "mun",
    buffer_m == 5000 ~ "buf5km",
    buffer_m == 10000 ~ "buf10km",
    TRUE ~ paste0("buf", buffer_m)
  )) %>%
  pivot_wider(
    id_cols = c(id_local, ano),
    names_from = escala_sufixo,
    values_from = c(pct_nativa, pct_pastagem, pct_agricultura, pct_agua, area_nativa_km2, area_total_km2),
    names_glue = "{.value}_{escala_sufixo}"
  )

# 4. Juncao relacional com Local, Paisagem e Social
message("Realizando joins relacionais...")

tabela_analise <- bio_agregada %>%
  left_join(banco_local, by = "id_local") %>%
  left_join(paisagem_larga, by = c("id_local" = "id_local", "ano_mapbiomas" = "ano")) %>%
  left_join(banco_social %>% select(-ano, -fonte), by = "codigo_ibge")

# 5. Relatorio de correspondencia
n_sem_local <- sum(is.na(tabela_analise$municipio))
n_sem_paisagem <- sum(is.na(tabela_analise$pct_nativa_mun))
n_sem_social <- sum(is.na(tabela_analise$pib_mil_reais))

message("--- Diagnostico de Juncao Relacional ---")
message("Unidades sem local correspondente: ", n_sem_local)
message("Unidades sem paisagem correspondente: ", n_sem_paisagem)
message("Unidades sem dados sociais correspondentes: ", n_sem_social)

caminho_saida <- "saidas/tabela_analise.csv"
write_csv(tabela_analise, caminho_saida)
message("Tabela integrada de analise salva em ", caminho_saida, " (", nrow(tabela_analise), " linhas, ", ncol(tabela_analise), " colunas).")

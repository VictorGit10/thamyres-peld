# ==============================================================================
# codigo/05_padronizar.R
# Normaliza dados brutos usando o dicionario de colunas para o esquema canônico
# Filtra apenas ocorrencias dentro dos 6 municipios (exclui fora_area do banco)
# Gera CSVs em dados/banco/ e popula dados/banco/peld.sqlite com integridade referencial
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando padronizacao canônica e criacao do banco relacional...")

dir.create("dados/banco", recursive = TRUE, showWarnings = FALSE)

# 1. Carrega dicionario e tabelas de referencia
dicionario <- carregar_dicionario("dicionario_colunas.csv")

locais_raw <- read_csv("dados/bruto/municipios_locais.csv", show_col_types = FALSE)
social_raw <- read_csv("dados/bruto/social_municipios.csv", show_col_types = FALSE)
paisagem_raw <- read_csv("dados/bruto/paisagem.csv", show_col_types = FALSE)

# ------------------------------------------------------------------------------
# 2. Tabela Canônica: LOCAL
# ------------------------------------------------------------------------------
message("Padronizando tabela 'local'...")
banco_local <- locais_raw %>%
  transmute(
    id_local = as.character(id_local),
    nome_local = as.character(nome_local),
    municipio = as.character(municipio),
    codigo_ibge = as.character(codigo_ibge),
    lat = round(as.numeric(lat), 6),
    lon = round(as.numeric(lon), 6),
    tipo_area = as.character(tipo_area),
    uc = as.character(uc),
    obs = as.character(obs)
  ) %>%
  distinct(id_local, .keep_all = TRUE)

write_csv(banco_local, "dados/banco/local.csv")

# ------------------------------------------------------------------------------
# 3. Mapeamento Dinamico de Ocorrencias via Dicionario de Colunas
# Itera sobre unique(dicionario$tabela_origem) para tabela_destino == 'observacao'
# Carrega tabelas de dados/bruto/; deixa tabelas de dados/exemplo fora do run principal
# ------------------------------------------------------------------------------
message("Mapeando ocorrencias dinamicamente via dicionario_colunas.csv...")

tabelas_obs_declaradas <- dicionario %>%
  filter(tabela_destino == "observacao") %>%
  pull(tabela_origem) %>%
  unique()

message("Tabelas de observacao declaradas no dicionario: ", paste(tabelas_obs_declaradas, collapse = ", "))

lista_obs_mapeadas <- list()

for (tab_orig in tabelas_obs_declaradas) {
  caminho_arq <- file.path("dados/bruto", paste0(tab_orig, ".csv"))
  
  if (file.exists(caminho_arq)) {
    message("  Lendo e mapeando tabela bruta: ", caminho_arq, "...")
    df_raw <- read_csv(caminho_arq, col_types = cols(.default = col_character()), show_col_types = FALSE)
    
    grp_padrao <- case_when(
      str_detect(tab_orig, "flora|vegetacao|planta") ~ "Flora",
      str_detect(tab_orig, "fauna|ave|bicho|animal") ~ "Fauna",
      TRUE ~ "Indeterminado"
    )
    
    df_map <- mapear_tabela_por_dicionario(
      df = df_raw,
      nome_tabela_origem = tab_orig,
      dicionario = dicionario,
      tabela_destino = "observacao",
      grupo_padrao = grp_padrao
    )
    
    lista_obs_mapeadas[[tab_orig]] <- df_map
    message("    -> ", nrow(df_map), " registros mapeados de '", tab_orig, "'.")
  } else {
    message("  Tabela '", tab_orig, "' declarada no dicionario nao encontrada em dados/bruto/ (deixada fora do run principal).")
  }
}

if (length(lista_obs_mapeadas) == 0) {
  stop("Nenhuma tabela de observacao encontrada em dados/bruto/ correspondente ao dicionario.")
}

todas_obs_mapped <- bind_rows(lista_obs_mapeadas)

# FILTRAGEM RIGOROSA DE PONTO-EM-POLIGONO:
# Apenas registros que cairam comprovadamente dentro dos 6 municipios entram no banco canonico
total_bruto <- nrow(todas_obs_mapped)
obs_fora_poligono <- todas_obs_mapped %>% filter(fora_area == TRUE | is.na(id_local))
banco_observacao_df <- todas_obs_mapped %>% filter(fora_area == FALSE & !is.na(id_local))

message("Total de ocorrencias brutas: ", total_bruto)
message("Ocorrencias fora dos 6 polos PELD (excluidas do banco): ", nrow(obs_fora_poligono))
message("Ocorrencias canonicas ingeridas no banco: ", nrow(banco_observacao_df))

# ------------------------------------------------------------------------------
# 4. Tabela Canônica: ESPECIE (Reconstruida a partir dos atributos taxonomicos)
# Preserva id_especie (PK: ESP_001 a ESP_738), familia, ordem, origem e status IUCN
# ------------------------------------------------------------------------------
message("Padronizando tabela 'especie' com taxonomia completa...")

banco_especie <- banco_observacao_df %>%
  group_by(especie) %>%
  summarise(
    nome_cientifico = first(especie),
    nome_aceito = first(na.omit(c(nome_aceito[nome_aceito != "" & !is.na(nome_aceito)], first(especie)))),
    familia = first(na.omit(c(familia[familia != "Não determinada" & familia != "" & !is.na(familia)], "Não determinada"))),
    ordem = first(na.omit(c(ordem[ordem != "Não determinada" & ordem != "" & !is.na(ordem)], "Não determinada"))),
    grupo = first(grupo),
    origem = first(na.omit(c(origem[origem != "Nativa" & origem != "" & !is.na(origem)], "Nativa"))),
    status_conservacao = first(na.omit(c(status_conservacao[status_conservacao != "LC" & status_conservacao != "" & !is.na(status_conservacao)], "LC"))),
    .groups = "drop"
  ) %>%
  arrange(grupo, nome_cientifico) %>%
  mutate(id_especie = sprintf("ESP_%03d", row_number())) %>%
  select(id_especie, nome_cientifico, nome_aceito, familia, ordem, grupo, origem, status_conservacao)

message("Total de especies catalogadas: ", nrow(banco_especie))
message("  Familias distintas: ", n_distinct(banco_especie$familia[banco_especie$familia != "Não determinada"]))
message("  Ordens distintas: ", n_distinct(banco_especie$ordem[banco_especie$ordem != "Não determinada"]))

write_csv(banco_especie, "dados/banco/especie.csv")

# ------------------------------------------------------------------------------
# 5. Tabela Canônica: OBSERVACAO (Com id_especie como FK e chaves validadas)
# ------------------------------------------------------------------------------
message("Padronizando tabela 'observacao' (com id_especie FK)...")

banco_observacao <- banco_observacao_df %>%
  left_join(banco_especie %>% select(nome_cientifico, id_especie), by = c("especie" = "nome_cientifico")) %>%
  select(
    id_observacao,
    id_campanha,
    id_local,
    id_especie,
    data,
    precisao_data,
    ano_original,
    grupo,
    especie,
    nome_comum,
    individuos,
    presenca,
    unidade,
    categoria,
    incerteza_metros,
    valido_paisagem,
    fonte,
    id_registro_original
  ) %>%
  distinct(id_observacao, .keep_all = TRUE)

write_csv(banco_observacao, "dados/banco/observacao.csv")

# ------------------------------------------------------------------------------
# 6. Tabela Canônica: CAMPANHA (Unidade de Agregacao Temporal-Espacial)
# Esforco = NA para dados oportunistas; conceito renomeado para agregacao
# ------------------------------------------------------------------------------
message("Padronizando tabela 'campanha' (unidades de agregacao)...")
banco_campanha <- banco_observacao %>%
  group_by(id_campanha, id_local) %>%
  summarise(
    ano = suppressWarnings(as.integer(first(na.omit(ano_original)))),
    grupo = first(grupo),
    data_inicio = suppressWarnings(if (all(is.na(data))) NA_character_ else min(na.omit(data))),
    data_fim = suppressWarnings(if (all(is.na(data))) NA_character_ else max(na.omit(data))),
    metodo = first(categoria),
    # Esforco = NA para fontes oportunistas (nao circular com n de registros)
    esforco = NA_real_,
    esforco_unidade = NA_character_,
    equipe = "Pesquisadores / Coletores PELD",
    tipo_evento = "unidade_agregacao",
    obs = paste0("Unidade de agregacao espacial-temporal com ", n(), " registros de presenca."),
    .groups = "drop"
  )

write_csv(banco_campanha, "dados/banco/campanha.csv")

# ------------------------------------------------------------------------------
# 6. Tabela Canônica: PAISAGEM
# ------------------------------------------------------------------------------
message("Padronizando tabela 'paisagem'...")
banco_paisagem <- paisagem_raw %>%
  transmute(
    id_local = as.character(id_local),
    ano = as.integer(ano),
    buffer_m = as.integer(buffer_m),
    area_nativa_km2 = as.numeric(area_nativa_km2),
    area_pastagem_km2 = as.numeric(area_pastagem_km2),
    area_agricultura_km2 = as.numeric(area_agricultura_km2),
    area_agua_km2 = as.numeric(area_agua_km2),
    area_total_km2 = as.numeric(area_total_km2),
    pct_nativa = as.numeric(pct_nativa),
    pct_pastagem = as.numeric(pct_pastagem),
    pct_agricultura = as.numeric(pct_agricultura),
    pct_agua = as.numeric(pct_agua)
  ) %>%
  distinct(id_local, ano, buffer_m, .keep_all = TRUE)

write_csv(banco_paisagem, "dados/banco/paisagem.csv")

# ------------------------------------------------------------------------------
# 7. Tabela Canônica: SOCIAL
# ------------------------------------------------------------------------------
message("Padronizando tabela 'social'...")
banco_social <- social_raw %>%
  transmute(
    codigo_ibge = as.character(codigo_ibge),
    ano = as.integer(ano),
    populacao = as.integer(populacao),
    pop_rural_pct = as.numeric(pop_rural_pct),
    pib_mil_reais = as.numeric(pib_mil_reais),
    pib_per_capita = as.numeric(pib_per_capita),
    agro_pct_pib = as.numeric(agro_pct_pib),
    fonte = as.character(fonte)
  ) %>%
  distinct(codigo_ibge, ano, .keep_all = TRUE)

write_csv(banco_social, "dados/banco/social.csv")

# ------------------------------------------------------------------------------
# 8. Tabela Canônica: PERFIL (Modelo Vazio)
# ------------------------------------------------------------------------------
message("Padronizando tabela 'perfil' (modelo vazio)...")
banco_perfil <- tibble(
  id_propriedade = character(),
  id_local = character(),
  ano = integer(),
  variavel = character(),
  valor = character(),
  unidade = character(),
  fonte = character()
)

write_csv(banco_perfil, "dados/banco/perfil.csv")

# ------------------------------------------------------------------------------
# 9. Validacao de Chaves Estrangeiras e Criacao do Banco SQLite
# ------------------------------------------------------------------------------
message("Validando chaves estrangeiras...")

# Checagem campanha -> local
orfaos_camp_loc <- setdiff(banco_campanha$id_local, banco_local$id_local)
if (length(orfaos_camp_loc) > 0) stop("Erro: Chaves orfas de local em campanha: ", paste(orfaos_camp_loc, collapse = ", "))

# Checagem observacao -> campanha
orfaos_obs_camp <- setdiff(banco_observacao$id_campanha, banco_campanha$id_campanha)
if (length(orfaos_obs_camp) > 0) stop("Erro: Chaves orfas de campanha em observacao: ", paste(orfaos_obs_camp, collapse = ", "))

# Checagem observacao -> local
orfaos_obs_loc <- setdiff(banco_observacao$id_local, banco_local$id_local)
if (length(orfaos_obs_loc) > 0) stop("Erro: Chaves orfas de local em observacao: ", paste(orfaos_obs_loc, collapse = ", "))

# Checagem observacao -> especie (via id_especie PK/FK e via nome_cientifico)
orfaos_obs_esp_id <- setdiff(banco_observacao$id_especie, banco_especie$id_especie)
if (length(orfaos_obs_esp_id) > 0) stop("Erro: Chaves orfas de id_especie em observacao: ", paste(head(orfaos_obs_esp_id, 5), collapse = ", "))

orfaos_obs_esp_nome <- setdiff(banco_observacao$especie, banco_especie$nome_cientifico)
if (length(orfaos_obs_esp_nome) > 0) stop("Erro: Chaves orfas de especie em observacao: ", paste(head(orfaos_obs_esp_nome, 5), collapse = ", "))

# Checagem paisagem -> local
orfaos_pais_loc <- setdiff(banco_paisagem$id_local, banco_local$id_local)
if (length(orfaos_pais_loc) > 0) stop("Erro: Chaves orfas de local em paisagem: ", paste(orfaos_pais_loc, collapse = ", "))

message("Todas as chaves estrangeiras foram validadas com 100% de integridade relacional!")

# Criando banco SQLite
caminho_sqlite <- "dados/banco/peld.sqlite"
if (file.exists(caminho_sqlite)) unlink(caminho_sqlite)

con <- dbConnect(SQLite(), caminho_sqlite)

# Executa DDL esquema.sql
ddl <- readLines("esquema.sql", warn = FALSE) %>% paste(collapse = "\n")
comandos_sql <- str_split(ddl, ";")[[1]] %>% trimws()
comandos_sql <- comandos_sql[comandos_sql != ""]

for (cmd in comandos_sql) {
  dbExecute(con, cmd)
}

# Popula tabelas
dbWriteTable(con, "local", banco_local, append = TRUE)
dbWriteTable(con, "campanha", banco_campanha, append = TRUE)
dbWriteTable(con, "especie", banco_especie, append = TRUE)
dbWriteTable(con, "observacao", banco_observacao, append = TRUE)
dbWriteTable(con, "paisagem", banco_paisagem, append = TRUE)
dbWriteTable(con, "social", banco_social, append = TRUE)
dbWriteTable(con, "perfil", banco_perfil, append = TRUE)

dbDisconnect(con)
message("Banco SQLite criado com sucesso em ", caminho_sqlite)

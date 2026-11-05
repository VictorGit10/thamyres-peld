# ==============================================================================
# codigo/10_teste_dicionario.R
# Teste unitario automatizado do mapeador por dicionario
# Prova que uma tabela com colunas arbitrarias (Sp_Name, Dt_Coleta, Qtde, Lat, Lon)
# e lida, auditada e convertida com sucesso para o esquema canônico
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando teste do dicionario com tabela de exemplo customizada...")

# 1. Carrega dicionario e tabela de exemplo com colunas nao-GBIF
caminho_csv <- "dados/exemplo/minha_flora.csv"
if (!file.exists(caminho_csv)) {
  stop("ERRO: Arquivo de exemplo nao encontrado: ", caminho_csv)
}

df_custom <- read_csv(caminho_csv, show_col_types = FALSE)
dicionario <- carregar_dicionario("dicionario_colunas.csv")

message("1. Arquivo de exemplo carregado:")
message("   Colunas presentes: ", paste(names(df_custom), collapse = ", "))
message("   Total de linhas: ", nrow(df_custom))

# 2. Testa auditoria orientada pelo dicionario
message("2. Executando auditoria da tabela customizada...")
prob_audit <- auditar_tabela_por_dicionario(df_custom, "minha_flora", dicionario)
message("   Inconsistencias detectadas pela auditoria: ", nrow(prob_audit))

# Deve detectar contagem ausente (NA em Qtde) sem crashar
tipos_prob <- unique(prob_audit$tipo_problema)
if (!"abundancia_ausente" %in% tipos_prob) {
  stop("ERRO: Auditoria nao detectou contagem ausente esperada na coluna Qtde!")
}

# 3. Testa mapeamento e conversao para o esquema canonico
message("3. Executando mapeamento e conversao para o esquema canonico...")
df_canonico <- mapear_tabela_por_dicionario(
  df = df_custom,
  nome_tabela_origem = "minha_flora",
  dicionario = dicionario,
  tabela_destino = "observacao",
  grupo_padrao = "Flora"
)

# 4. Validacoes estritas de assercoes
message("4. Validando assercoes estruturais do resultado...")

# (a) Numero de linhas deve bater
if (nrow(df_canonico) != nrow(df_custom)) {
  stop("ERRO: Numero de linhas divergente (esperado: ", nrow(df_custom), ", obtido: ", nrow(df_canonico), ")")
}

# (b) Colunas canonicas obrigatorias devem estar presentes
cols_obrigatorias <- c(
  "id_observacao", "id_campanha", "data", "precisao_data", "ano_original",
  "grupo", "especie", "individuos", "presenca", "unidade", "lat", "lon"
)
faltantes_canonicas <- setdiff(cols_obrigatorias, names(df_canonico))
if (length(faltantes_canonicas) > 0) {
  stop("ERRO: Colunas canonicas ausentes no resultado: ", paste(faltantes_canonicas, collapse = ", "))
}

# (c) Mapeamento de valores especificos
if (df_canonico$especie[1] != "Caryocar brasiliense") {
  stop("ERRO: Especie da linha 1 incorreta: ", df_canonico$especie[1])
}

if (df_canonico$individuos[1] != 5) {
  stop("ERRO: Quantidade da linha 1 incorreta: ", df_canonico$individuos[1])
}

# Linha 3 (Qualea grandiflora) tinha Qtde = NA; deve virar individuos = NA e presenca = 1L
if (!is.na(df_canonico$individuos[3]) || df_canonico$presenca[3] != 1L || df_canonico$unidade[3] != "presenca") {
  stop("ERRO: Linha com Qtde ausente nao foi tratada corretamente como presenca=1L e individuos=NA!")
}

# Datas com precisao "dia"
if (any(df_canonico$precisao_data != "dia")) {
  stop("ERRO: Precisao de data incorreta nas linhas com data ISO completa!")
}

# Coordenadas numericas
if (!is.numeric(df_canonico$lat) || !is.numeric(df_canonico$lon) || any(is.na(df_canonico$lat))) {
  stop("ERRO: Coordenadas nao foram convertidas corretamente para numerico!")
}

# 5. Testa o fluxo de descoberta iterativa sobre unique(dicionario$tabela_origem) em modo separado
message("5. Testando descoberta iterativa de tabelas arbitrarias no dicionario (modo isolado)...")
tabelas_declaradas <- dicionario %>%
  filter(tabela_destino == "observacao") %>%
  pull(tabela_origem) %>%
  unique()

if (!"minha_flora" %in% tabelas_declaradas) {
  stop("ERRO: 'minha_flora' nao esta declarada como tabela de observacao no dicionario!")
}

# Procura em pasta de teste isolada (dados/exemplo/)
pasta_teste <- "dados/exemplo"
tabelas_encontradas <- list()
for (tab in tabelas_declaradas) {
  arq <- file.path(pasta_teste, paste0(tab, ".csv"))
  if (file.exists(arq)) {
    df_raw <- read_csv(arq, col_types = cols(.default = col_character()), show_col_types = FALSE)
    df_map <- mapear_tabela_por_dicionario(df_raw, tab, dicionario, "observacao", "Flora")
    tabelas_encontradas[[tab]] <- df_map
  }
}

if (!"minha_flora" %in% names(tabelas_encontradas)) {
  stop("ERRO: O teste de descoberta iterativa nao encontrou 'minha_flora.csv'!")
}
if (nrow(tabelas_encontradas[["minha_flora"]]) != 6) {
  stop("ERRO: 'minha_flora' mapeada via descoberta iterativa nao tem 6 linhas!")
}
message("   Descoberta iterativa comprovada com sucesso para tabelas customizadas!")

message("\n==============================================================================")
message("   SUCESSO ABSOLUTO: O teste do dicionario passou em todas as assercoes!")
message("   Tabela com colunas arbitrarias foi lida, auditada, descoberta e convertida.")
message("==============================================================================")

# ==============================================================================
# codigo/10b_teste_fluxo_completo.R
# Teste de integracao do fluxo da pesquisadora:
# copia uma tabela com colunas arbitrarias para dados/bruto/ e roda
# 03b (point-in-polygon) + 05 (banco canonico) + 06 (tabela de analise)
# em uma pasta temporaria, sem contaminar os dados do exemplo.
# ==============================================================================

source("R/funcoes.R")

testar_fluxo_completo <- function() {
message(">>> Teste de integracao: tabela customizada -> 03b -> 05 -> 06")

raiz <- normalizePath(".")
tmp <- tempfile("peld_teste_fluxo_")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
on.exit({
  setwd(raiz)
  unlink(tmp, recursive = TRUE, force = TRUE)
}, add = TRUE)

# Estrutura minima
for (d in c("R", "codigo", "dados/bruto", "dados/banco", "saidas")) {
  dir.create(file.path(tmp, d), recursive = TRUE, showWarnings = FALSE)
}

# Arquivos de codigo e configuracao
arquivos <- c(
  "R/funcoes.R",
  "codigo/03b_atribuir_locais.py",
  "codigo/05_padronizar.R",
  "codigo/06_juntar.R",
  "dicionario_colunas.csv",
  "esquema.sql"
)
for (a in arquivos) {
  file.copy(a, file.path(tmp, a), overwrite = TRUE)
}

# Dados de apoio
for (a in c(
  "dados/bruto/gbif_flora.csv",
  "dados/bruto/gbif_fauna.csv",
  "dados/bruto/municipios_locais.csv",
  "dados/bruto/social_municipios.csv",
  "dados/bruto/paisagem.csv"
)) {
  file.copy(a, file.path(tmp, a), overwrite = TRUE)
}
file.copy(
  "dados/bruto/malhas",
  file.path(tmp, "dados/bruto"),
  recursive = TRUE,
  overwrite = TRUE
)

# A tabela da pesquisadora: colunas Sp_Name, Dt_Coleta, Qtde, Lat, Lon
file.copy(
  "dados/exemplo/minha_flora.csv",
  file.path(tmp, "dados/bruto/minha_flora.csv"),
  overwrite = TRUE
)

setwd(tmp)

# 1. Point-in-polygon
status_03b <- system2("python", "codigo/03b_atribuir_locais.py")
if (status_03b != 0) stop("Falha no 03b_atribuir_locais.py")

# 2. Banco canonico
source("codigo/05_padronizar.R")

# 3. Tabela de analise
source("codigo/06_juntar.R")

# 4. Assercoes
obs <- read_csv("dados/banco/observacao.csv", show_col_types = FALSE)
custom <- obs %>% filter(str_detect(id_observacao, "^OBS_MIN_"))

message("Linhas da tabela customizada no banco: ", nrow(custom))
if (nrow(custom) != 6) {
  stop("ERRO: esperava 6 linhas de minha_flora no banco, encontrei ", nrow(custom))
}
if (any(is.na(custom$id_local))) {
  stop("ERRO: alguma linha de minha_flora ficou sem id_local")
}
if (!all(c("id_especie", "presenca", "precisao_data") %in% names(custom))) {
  stop("ERRO: colunas canonicas ausentes nas linhas de minha_flora")
}

analise <- read_csv("saidas/tabela_analise.csv", show_col_types = FALSE)
if (nrow(analise) == 0) stop("ERRO: tabela_analise.csv vazia")

message("OK: a tabela customizada entrou no banco e na tabela de analise.")
message("Teste de integracao concluido com sucesso.")
}

testar_fluxo_completo()

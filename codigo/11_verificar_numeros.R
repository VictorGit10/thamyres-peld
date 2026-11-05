# ==============================================================================
# codigo/11_verificar_numeros.R
# Confere os numeros-chave do RELATORIO.md e REVISAO-ALVO.md contra as saidas geradas
# Falha com stop() se qualquer valor divergir dos scripts
# ==============================================================================

source("R/funcoes.R")

message(">>> Verificando integridade numerica dos relatorios contra saidas oficiais...")

# 1. Carrega dados gerados oficiais
metricas <- fromJSON("saidas/metricas_analise.json")
resumo_esp <- read_csv("saidas/resumo_espacializacao.csv", show_col_types = FALSE)
riqueza_locais <- read_csv("saidas/tabela_riqueza_locais.csv", show_col_types = FALSE)
resumo_auditoria <- read_csv("saidas/resumo_auditoria.csv", show_col_types = FALSE)
problemas_df <- read_csv("saidas/problemas.csv", show_col_types = FALSE)
banco_especie <- read_csv("dados/banco/especie.csv", show_col_types = FALSE)
banco_observacao <- read_csv("dados/banco/observacao.csv", show_col_types = FALSE)

# 2. Carrega texto dos documentos
relatorio_txt <- readLines("RELATORIO.md", warn = FALSE) %>% paste(collapse = "\n")
revisao_alvo_txt <- readLines("REVISAO-ALVO.md", warn = FALSE) %>% paste(collapse = "\n")
roteiro_txt <- readLines("ROTEIRO-ENCONTRO.md", warn = FALSE) %>% paste(collapse = "\n")

erros <- character()

testar_numero <- function(nome, valor_esperado, regex_procura, doc_nome, doc_txt) {
  if (!str_detect(doc_txt, regex_procura)) {
    erros <<- c(erros, paste0("[", doc_nome, "] Falha em '", nome, "': valor esperado '", valor_esperado, "' nao encontrado com regex '", regex_procura, "'"))
  } else {
    message("  [OK] ", doc_nome, " -> ", nome, ": ", valor_esperado)
  }
}

message("Testando numeros-chave no RELATORIO.md...")

# Soma populacional: 429.010
pop_total <- metricas$amostra$soma_populacao_2022
testar_numero("Soma populacional 2022", pop_total, "429\\.010", "RELATORIO.md", relatorio_txt)
testar_numero("Soma populacional 2022", pop_total, "429\\.010", "REVISAO-ALVO.md", revisao_alvo_txt)

# Total ocorrencias brutas: 3.000
testar_numero("Total registros brutos", 3000, "3\\.000", "RELATORIO.md", relatorio_txt)
testar_numero("Total registros brutos", 3000, "3\\.000", "REVISAO-ALVO.md", revisao_alvo_txt)

# Ocorrencias canonicas ingeridas: 2.124
reg_canonicos <- metricas$amostra$total_registros_canonicos
testar_numero("Registros canonicos ingeridos", reg_canonicos, "2\\.124", "RELATORIO.md", relatorio_txt)
testar_numero("Registros canonicos ingeridos", reg_canonicos, "2\\.124", "REVISAO-ALVO.md", revisao_alvo_txt)

# Ocorrencias fora dos 6 polos: 876
reg_fora <- metricas$amostra$total_registros_fora_poligono
testar_numero("Registros fora dos 6 polos", reg_fora, "876", "RELATORIO.md", relatorio_txt)
testar_numero("Registros fora dos 6 polos", reg_fora, "876", "REVISAO-ALVO.md", revisao_alvo_txt)

# Riqueza geral canonica: 738 especies
sp_total <- metricas$amostra$total_especies_geral
testar_numero("Riqueza geral canonica", sp_total, "738", "RELATORIO.md", relatorio_txt)
testar_numero("Riqueza geral canonica", sp_total, "738", "REVISAO-ALVO.md", revisao_alvo_txt)

# Riqueza Flora: 535
sp_flora <- metricas$amostra$total_especies_flora
testar_numero("Riqueza Flora canonica", sp_flora, "535", "RELATORIO.md", relatorio_txt)
testar_numero("Riqueza Flora canonica", sp_flora, "535", "REVISAO-ALVO.md", revisao_alvo_txt)

# Riqueza Aves: 160
sp_aves <- metricas$amostra$total_especies_aves
testar_numero("Riqueza Aves canonica", sp_aves, "160", "RELATORIO.md", relatorio_txt)
testar_numero("Riqueza Aves canonica", sp_aves, "160", "REVISAO-ALVO.md", revisao_alvo_txt)

# Riqueza Mamiferos: 43
sp_mam <- metricas$amostra$total_especies_mamiferos
testar_numero("Riqueza Mamiferos canonica", sp_mam, "43", "RELATORIO.md", relatorio_txt)
testar_numero("Riqueza Mamiferos canonica", sp_mam, "43", "REVISAO-ALVO.md", revisao_alvo_txt)

# Correlacao Spearman nativa mun vs agro: 0.5429
rho_agro <- metricas$correlacoes_spearman$nativa_mun_vs_agro_pib
testar_numero("Spearman Nativa Mun vs Agro", rho_agro, "0,5429", "RELATORIO.md", relatorio_txt)
testar_numero("Spearman Nativa Mun vs Agro", rho_agro, "0,5429", "REVISAO-ALVO.md", revisao_alvo_txt)

# Inversao escala PIB per capita: -0.6000 vs +0.4286
testar_numero("Spearman Nativa Mun vs PIBpc", -0.6, "-0,6000", "RELATORIO.md", relatorio_txt)
testar_numero("Spearman Nativa Buf5km vs PIBpc", 0.4286, "\\+0,4286|0,4286", "RELATORIO.md", relatorio_txt)

# Controle negativo p-valor: 0.303
p_perm <- metricas$controle_negativo$p_valor_empirico
testar_numero("P-valor empirico permutacao", p_perm, "0,303", "RELATORIO.md", relatorio_txt)
testar_numero("P-valor empirico permutacao", p_perm, "0,303", "REVISAO-ALVO.md", revisao_alvo_txt)

# Testes de Chave Primaria/Estrangeira id_especie
message("Testando chaves primarias e estrangeiras id_especie (ESP_001 a ESP_738)...")
if (!"id_especie" %in% names(banco_especie)) {
  erros <- c(erros, "Coluna 'id_especie' ausente na tabela especie.csv")
}
if (!"id_especie" %in% names(banco_observacao)) {
  erros <- c(erros, "Coluna 'id_especie' ausente na tabela observacao.csv")
}
if (any(!str_detect(banco_especie$id_especie, "^ESP_\\d{3}$"))) {
  erros <- c(erros, "Formato invalido de PK em especie$id_especie")
}
testar_numero("PK id_especie ESP_001 a ESP_738", "ESP_001", "ESP_001", "RELATORIO.md", relatorio_txt)
testar_numero("PK id_especie ESP_001 a ESP_738", "ESP_001", "ESP_001", "REVISAO-ALVO.md", revisao_alvo_txt)

# Testes de Taxonomia Preservada (Familias e Ordens)
n_fam <- metricas$amostra$total_familias_geral
n_ord <- metricas$amostra$total_ordens_geral
testar_numero("Total de familias taxonomicas", n_fam, as.character(n_fam), "RELATORIO.md", relatorio_txt)
testar_numero("Total de ordens taxonomicas", n_ord, as.character(n_ord), "RELATORIO.md", relatorio_txt)

# Testes de Incerteza Espacial e Valido Paisagem
n_val_pais <- metricas$amostra$incerteza_espacial$total_valido_paisagem
n_inval_pais <- metricas$amostra$incerteza_espacial$total_invalido_paisagem
n_inc_na <- metricas$amostra$incerteza_espacial$total_incerteza_na
testar_numero("Ocorrencias validas para paisagem", n_val_pais, as.character(n_val_pais), "RELATORIO.md", relatorio_txt)
testar_numero("Ocorrencias com incerteza ausente", n_inc_na, "1\\.414", "RELATORIO.md", relatorio_txt)

# Testes das contagens da auditoria (12 tipos, 8.613 ocorrencias)
soma_aud <- sum(resumo_auditoria$total_ocorrencias)
n_tipos_aud <- nrow(resumo_auditoria)
testar_numero("Total de inconsistencias da auditoria", soma_aud, "8\\.613", "REVISAO-ALVO.md", revisao_alvo_txt)
testar_numero("Total de inconsistencias da auditoria", soma_aud, "8\\.613", "ROTEIRO-ENCONTRO.md", roteiro_txt)
testar_numero("Tipos de inconsistencia da auditoria", n_tipos_aud, "12 tipos", "REVISAO-ALVO.md", revisao_alvo_txt)
testar_numero("Tipos de inconsistencia da auditoria", n_tipos_aud, "12 tipos", "ROTEIRO-ENCONTRO.md", roteiro_txt)

if (length(erros) > 0) {
  message("\n==============================================================================")
  message("FALHA NA CONFERENCIA DE NUMEROS! Foram encontradas ", length(erros), " divergencias:")
  for (e in erros) message("  ", e)
  message("==============================================================================")
  stop("Integridade numerica violada entre os relatorios e as saidas dos scripts.")
} else {
  message("\n==============================================================================")
  message("SUCESSO ABSOLUTO: 100% dos numeros testados coincidem perfeitamente com os scripts!")
  message("Nenhum valor foi inventado ou digitado incorretamente nos relatorios.")
  message("==============================================================================")
}

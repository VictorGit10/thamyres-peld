# ==============================================================================
# codigo/99_rodar_tudo.R
# Pipeline mestre de execucao do kit PELD (executa do zero em sequencia estrita)
# ==============================================================================

tempo_inicio <- Sys.time()
message("==============================================================================")
message("   EXECUTANDO PIPELINE COMPLETO DO KIT PELD (DO ZERO)")
message("   Inicio: ", tempo_inicio)
message("==============================================================================")

executar_etapa <- function(numero, script, tipo = "R") {
  t0 <- Sys.time()
  message("\n------------------------------------------------------------------------------")
  message(">> ETAPA ", numero, ": Executando ", script, "...")
  message("------------------------------------------------------------------------------")
  
  if (tipo == "R") {
    status <- tryCatch({
      source(script, echo = FALSE)
      0
    }, error = function(e) {
      message("ERRO na execucao de ", script, ": ", e$message)
      1
    })
  } else if (tipo == "python") {
    status <- system2("python", script)
  } else {
    stop("Tipo desconhecido: ", tipo)
  }
  
  duracao <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  if (status != 0) {
    stop("Falha critica na etapa ", numero, " (", script, "). Execucao interrompida.")
  }
  message(">> Etapa ", numero, " concluida com sucesso em ", duracao, " segundos.")
}

# 1. Verificacao de ambiente e bibliotecas
executar_etapa(0, "codigo/00_instalar.R", tipo = "R")

# 2. Download GBIF (Flora e Fauna)
executar_etapa(1, "codigo/01_baixar_gbif.R", tipo = "R")

# 3. Download IBGE (SIDRA e Malhas)
executar_etapa(2, "codigo/02_baixar_ibge.R", tipo = "R")

# 4. Processamento de Paisagem MapBiomas no Google Earth Engine
executar_etapa(3, "codigo/03_paisagem_gee.py", tipo = "python")

# 5. Atribuicao Espacial Point-in-Polygon contra Malhas IBGE
executar_etapa("3b", "codigo/03b_atribuir_locais.py", tipo = "python")

# 6. Auditoria de Dados Brutos (Orientada a Dicionario)
executar_etapa(4, "codigo/04_auditar.R", tipo = "R")

# 7. Padronizacao Canônica e Banco SQLite
executar_etapa(5, "codigo/05_padronizar.R", tipo = "R")

# 8. Juncao e Tabela de Analise
executar_etapa(6, "codigo/06_juntar.R", tipo = "R")

# 9. Analise Socioambiental e Controles (Escala e Negativo)
executar_etapa(7, "codigo/07_analisar.R", tipo = "R")

# 10. Geracao de Figuras e Esquema
executar_etapa(8, "codigo/08_figuras.R", tipo = "R")

# 11. Teste de Ingestao de Tabela Customizada via Dicionario
executar_etapa(10, "codigo/10_teste_dicionario.R", tipo = "R")

# 12. Teste de Integracao do Fluxo Completo (03b + 05 + 06) com Tabela Customizada
executar_etapa("10b", "codigo/10b_teste_fluxo_completo.R", tipo = "R")

# 13. Verificacao de Integridade Numerica dos Relatorios contra Scripts
executar_etapa(11, "codigo/11_verificar_numeros.R", tipo = "R")

duracao_total <- round(as.numeric(difftime(Sys.time(), tempo_inicio, units = "mins")), 2)
message("\n==============================================================================")
message("   PIPELINE FINALIZADO COM SUCESSO INTEGRAL!")
message("   Tempo total decorrido: ", duracao_total, " minutos.")
message("==============================================================================")

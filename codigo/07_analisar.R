# ==============================================================================
# codigo/07_analisar.R
# Analise ecologica e socioambiental rigorosa
# Riqueza municipal real a partir do banco, controle de escala (exercicio didatico MAUP)
# e controle negativo por permutacao (1.000 repeticoes)
# ==============================================================================

source("R/funcoes.R")

message(">>> Iniciando analise ecologica e socioambiental...")

dir.create("saidas", recursive = TRUE, showWarnings = FALSE)

# 1. Carrega dados canônicos
banco_local <- read_csv("dados/banco/local.csv", show_col_types = FALSE)
banco_obs <- read_csv("dados/banco/observacao.csv", show_col_types = FALSE)
banco_especie <- read_csv("dados/banco/especie.csv", show_col_types = FALSE)
banco_paisagem <- read_csv("dados/banco/paisagem.csv", show_col_types = FALSE)
banco_social <- read_csv("dados/banco/social.csv", show_col_types = FALSE)
tabela_analise <- read_csv("saidas/tabela_analise.csv", show_col_types = FALSE)

# ------------------------------------------------------------------------------
# 2. Riqueza e Registros Canônicos por Local e Grupo Taxonômico
# Calculado estritamente sobre as ocorrencias confirmadas dentro dos 6 municipios
# ------------------------------------------------------------------------------
message("Calculando riqueza taxonomica e esforco amostral canonico...")

# Riqueza acumulada por municipio e grupo
resumo_biodiversidade <- banco_obs %>%
  group_by(id_local, grupo) %>%
  summarise(
    total_registros = n(),
    riqueza_especies = n_distinct(especie),
    n_com_contagem_real = sum(!is.na(individuos)),
    .groups = "drop"
  ) %>%
  left_join(banco_local %>% select(id_local, nome_local, municipio), by = "id_local") %>%
  arrange(municipio, grupo)

write_csv(resumo_biodiversidade, "saidas/tabela_riqueza_locais.csv")

# Totais gerais canônicos no banco
total_especies_flora <- n_distinct(banco_obs$especie[banco_obs$grupo == "Flora"])
total_especies_aves <- n_distinct(banco_obs$especie[str_detect(banco_obs$grupo, "Aves")])
total_especies_mam <- n_distinct(banco_obs$especie[str_detect(banco_obs$grupo, "Mammalia")])
total_geral_especies <- n_distinct(banco_obs$especie)
total_registros_canonicos <- nrow(banco_obs)

message("Total de especies catalogadas no banco: ", total_geral_especies,
        " (Flora: ", total_especies_flora, ", Aves: ", total_especies_aves, ", Mamiferos: ", total_especies_mam, ")")
message("Total de ocorrencias canonicas ingeridas no banco: ", total_registros_canonicos)

# ------------------------------------------------------------------------------
# 3. Cruzamento Paisagem (2024) x Indicadores Sociais (n = 6 municipios)
# Pergunta: "Municipios com mais vegetacao nativa tem perfil socioeconomico diferente?"
# ------------------------------------------------------------------------------
message("Avaliando relacao Paisagem x Perfil Socioeconomico (n = 6)...")

dados_mun_2024 <- banco_local %>%
  left_join(banco_social %>% select(-ano), by = "codigo_ibge") %>%
  left_join(
    banco_paisagem %>%
      filter(ano == 2024, buffer_m == 0) %>%
      select(id_local, pct_nativa_mun = pct_nativa, pct_pasto_mun = pct_pastagem, pct_agri_mun = pct_agricultura),
    by = "id_local"
  ) %>%
  left_join(
    banco_paisagem %>%
      filter(ano == 2024, buffer_m == 5000) %>%
      select(id_local, pct_nativa_buf5km = pct_nativa, pct_pasto_buf5km = pct_pastagem, pct_agri_buf5km = pct_agricultura),
    by = "id_local"
  ) %>%
  left_join(
    banco_paisagem %>%
      filter(ano == 2024, buffer_m == 10000) %>%
      select(id_local, pct_nativa_buf10km = pct_nativa, pct_pasto_buf10km = pct_pastagem, pct_agri_buf10km = pct_agricultura),
    by = "id_local"
  )

soma_populacao_oficial <- sum(dados_mun_2024$populacao)
message("Soma populacional oficial dos 6 municipios (Censo 2022): ", soma_populacao_oficial)

calc_spearman <- function(x, y) {
  cor(x, y, method = "spearman", use = "complete.obs")
}

# Spearman Nativa x Agro % PIB
rho_mun_agro <- calc_spearman(dados_mun_2024$pct_nativa_mun, dados_mun_2024$agro_pct_pib)
rho_buf5_agro <- calc_spearman(dados_mun_2024$pct_nativa_buf5km, dados_mun_2024$agro_pct_pib)
rho_buf10_agro <- calc_spearman(dados_mun_2024$pct_nativa_buf10km, dados_mun_2024$agro_pct_pib)

# Spearman Nativa x % Pop Rural
rho_mun_rural <- calc_spearman(dados_mun_2024$pct_nativa_mun, dados_mun_2024$pop_rural_pct)
rho_buf5_rural <- calc_spearman(dados_mun_2024$pct_nativa_buf5km, dados_mun_2024$pop_rural_pct)
rho_buf10_rural <- calc_spearman(dados_mun_2024$pct_nativa_buf10km, dados_mun_2024$pop_rural_pct)

# Spearman Nativa x PIB per capita
rho_mun_pibpc <- calc_spearman(dados_mun_2024$pct_nativa_mun, dados_mun_2024$pib_per_capita)
rho_buf5_pibpc <- calc_spearman(dados_mun_2024$pct_nativa_buf5km, dados_mun_2024$pib_per_capita)
rho_buf10_pibpc <- calc_spearman(dados_mun_2024$pct_nativa_buf10km, dados_mun_2024$pib_per_capita)

# ------------------------------------------------------------------------------
# 4. Controle de Escala (Exercicio Didatico de Sensibilidade Numerica / MAUP)
# ------------------------------------------------------------------------------
message("Montando tabela de controle de escala (exercicio didatico)...")

tabela_controle_escala <- tibble(
  escala = c("Município Inteiro (buffer 0m)", "Buffer 5 km (ao redor centroide)", "Buffer 10 km (ao redor centroide)"),
  raio_buffer_m = c(0, 5000, 10000),
  spearman_nativa_vs_agro_pib = c(round(rho_mun_agro, 4), round(rho_buf5_agro, 4), round(rho_buf10_agro, 4)),
  spearman_nativa_vs_pop_rural = c(round(rho_mun_rural, 4), round(rho_buf5_rural, 4), round(rho_buf10_rural, 4)),
  spearman_nativa_vs_pib_per_capita = c(round(rho_mun_pibpc, 4), round(rho_buf5_pibpc, 4), round(rho_buf10_pibpc, 4))
)

write_csv(tabela_controle_escala, "saidas/tabela_controle_escala.csv")

# ------------------------------------------------------------------------------
# 5. Controle Negativo (Teste de Permutacao com 1.000 iteracoes)
# ------------------------------------------------------------------------------
message("Executando controle negativo (1.000 permutacoes)...")

set.seed(42)
n_perm <- 1000
rho_nulos <- numeric(n_perm)
x_real <- dados_mun_2024$pct_nativa_mun
y_real <- dados_mun_2024$agro_pct_pib

for (k in 1:n_perm) {
  y_shuffled <- sample(y_real, replace = FALSE)
  rho_nulos[k] <- calc_spearman(x_real, y_shuffled)
}

p_empirico <- mean(abs(rho_nulos) >= abs(rho_mun_agro))
ic95_nulo_inf <- quantile(rho_nulos, 0.025)
ic95_nulo_sup <- quantile(rho_nulos, 0.975)

df_nulo <- tibble(iteracao = 1:n_perm, rho_nulo = rho_nulos)
write_csv(df_nulo, "saidas/distribuicao_nula_controle_negativo.csv")

message("Controle negativo concluido: rho observado = ", round(rho_mun_agro, 4),
        " | p empirico = ", round(p_empirico, 4),
        " | IC 95% nulo: [", round(ic95_nulo_inf, 4), ", ", round(ic95_nulo_sup, 4), "]")

# ------------------------------------------------------------------------------
# 6. Modelo Linear Ilustrativo (Apenas Exercicio com Incerteza)
# ------------------------------------------------------------------------------
message("Ajustando modelo linear ilustrativo (lm)...")

mod_simples <- lm(agro_pct_pib ~ pct_nativa_mun, data = dados_mun_2024)
sum_mod <- summary(mod_simples)

coef_intercepto <- coef(mod_simples)[1]
coef_inclinacao <- coef(mod_simples)[2]
se_inclinacao <- sum_mod$coefficients[2, 2]
r2_modelo <- sum_mod$r.squared
p_val_modelo <- sum_mod$coefficients[2, 4]

# ------------------------------------------------------------------------------
# 7. Consolidacao de Todas as Metricas em JSON
# ------------------------------------------------------------------------------
metricas_saida <- list(
  data_analise = as.character(Sys.time()),
  amostra = list(
    n_municipios = nrow(dados_mun_2024),
    soma_populacao_2022 = soma_populacao_oficial,
    municipios = dados_mun_2024$municipio,
    total_registros_brutos = 3000,
    total_registros_fora_poligono = 876,
    total_registros_canonicos = total_registros_canonicos,
    total_especies_geral = total_geral_especies,
    total_especies_flora = total_especies_flora,
    total_especies_aves = total_especies_aves,
    total_especies_mamiferos = total_especies_mam,
    total_familias_geral = n_distinct(banco_especie$familia[banco_especie$familia != "Não determinada"]),
    total_ordens_geral = n_distinct(banco_especie$ordem[banco_especie$ordem != "Não determinada"]),
    incerteza_espacial = list(
      total_incerteza_na = sum(is.na(banco_obs$incerteza_metros)),
      flora_incerteza_na = sum(banco_obs$grupo == "Flora" & is.na(banco_obs$incerteza_metros)),
      fauna_incerteza_na = sum(banco_obs$grupo != "Flora" & is.na(banco_obs$incerteza_metros)),
      fauna_incerteza_maior_5km = sum(banco_obs$grupo != "Flora" & !is.na(banco_obs$incerteza_metros) & banco_obs$incerteza_metros > 5000),
      total_valido_paisagem = sum(banco_obs$valido_paisagem == 1L),
      total_invalido_paisagem = sum(banco_obs$valido_paisagem == 0L),
      pct_valido_paisagem = round(100 * mean(banco_obs$valido_paisagem == 1L), 2),
      criterio_filtro = "Valido para analise de paisagem (buffer 5 km) se incerteza conhecida E <= 5000m. Incerteza NA tratada conservadoramente como invalida."
    )
  ),
  riqueza_por_municipio = resumo_biodiversidade,
  valores_municipios = dados_mun_2024 %>%
    select(municipio, codigo_ibge, populacao, pop_rural_pct, pib_mil_reais, pib_per_capita, agro_pct_pib,
           pct_nativa_mun, pct_pasto_mun, pct_agri_mun,
           pct_nativa_buf5km, pct_pasto_buf5km, pct_agri_buf5km,
           pct_nativa_buf10km, pct_pasto_buf10km, pct_agri_buf10km),
  correlacoes_spearman = list(
    nativa_mun_vs_agro_pib = round(rho_mun_agro, 4),
    nativa_buf5km_vs_agro_pib = round(rho_buf5_agro, 4),
    nativa_buf10km_vs_agro_pib = round(rho_buf10_agro, 4),
    nativa_mun_vs_pop_rural = round(rho_mun_rural, 4),
    nativa_buf5km_vs_pop_rural = round(rho_buf5_rural, 4),
    nativa_buf10km_vs_pop_rural = round(rho_buf10_rural, 4),
    nativa_mun_vs_pib_per_capita = round(rho_mun_pibpc, 4),
    nativa_buf5km_vs_pib_per_capita = round(rho_buf5_pibpc, 4),
    nativa_buf10km_vs_pib_per_capita = round(rho_buf10_pibpc, 4)
  ),
  controle_escala_qualificacao = list(
    natureza = "Exercicio didatico de sensibilidade numerica e ilustracao do MAUP",
    advertencia = "A correlacao e inversao de sinal decorrem da instabilidade de postos em n=6 e do posicionamento do centroide geometrico proximo a areas urbanas, nao devendo ser interpretada como descoberta ecologica."
  ),
  controle_negativo = list(
    n_permutacoes = n_perm,
    rho_observado = round(rho_mun_agro, 4),
    p_valor_empirico = round(p_empirico, 4),
    ic95_nulo_inferior = round(as.numeric(ic95_nulo_inf), 4),
    ic95_nulo_superior = round(as.numeric(ic95_nulo_sup), 4),
    interpretacao = "Correlacao observada perfeitamente compativel com a variacao estocastica sob a hipotese nula (p = 0.303)."
  ),
  modelo_linear_exercicio = list(
    formula = "agro_pct_pib ~ pct_nativa_mun",
    n = nrow(dados_mun_2024),
    intercepto = round(as.numeric(coef_intercepto), 4),
    inclinacao = round(as.numeric(coef_inclinacao), 4),
    erro_padrao_inclinacao = round(as.numeric(se_inclinacao), 4),
    r_quadrado = round(as.numeric(r2_modelo), 4),
    p_valor = round(as.numeric(p_val_modelo), 4),
    ressalva_metodologica = "Modelo linear ajustado estritamente como exercicio didatico. Com n=6 municipios agregados, p-valores e R2 nao possuem poder probatorio."
  )
)

write_json(metricas_saida, "saidas/metricas_analise.json", pretty = TRUE, auto_unbox = TRUE)
message("Metricas analiticas consolidadas em saidas/metricas_analise.json.")

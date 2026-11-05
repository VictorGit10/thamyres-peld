# ==============================================================================
# codigo/08_figuras.R
# Gera as figuras e graficos do kit PELD e o diagrama relacional Mermaid
# Atualizado com numeros canonicos de ponto-em-poligono e qualificacao metodologica
# ==============================================================================

source("R/funcoes.R")

message(">>> Gerando figuras analiticas e diagrama do banco...")

dir.create("figuras", recursive = TRUE, showWarnings = FALSE)
dir.create("saidas", recursive = TRUE, showWarnings = FALSE)

theme_peld <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0),
    plot.subtitle = element_text(color = "gray30", size = 10, margin = margin(b = 10)),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# ------------------------------------------------------------------------------
# Figura 1: Problemas por tipo na auditoria
# ------------------------------------------------------------------------------
message("1. Gerando figura: problemas na auditoria...")
resumo_auditoria <- read_csv("saidas/resumo_auditoria.csv", show_col_types = FALSE)

p1 <- resumo_auditoria %>%
  mutate(
    tipo_problema_label = fct_reorder(paste0(tabela, ": ", tipo_problema), total_ocorrencias),
    gravidade = factor(gravidade, levels = c("critico", "importante", "menor"))
  ) %>%
  ggplot(aes(x = total_ocorrencias, y = tipo_problema_label, fill = gravidade)) +
  geom_col(width = 0.7) +
  scale_fill_manual(
    values = c("critico" = "#d95f02", "importante" = "#e7298a", "menor" = "#7570b3"),
    labels = c("critico" = "Crítico", "importante" = "Importante", "menor" = "Menor")
  ) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    title = "Inconsistências Detectadas na Auditoria dos Dados Brutos",
    subtitle = "Auditoria orientada pelo dicionario de colunas (incluindo point-in-polygon e incertezas)",
    x = "Total de Ocorrências",
    y = "Tabela : Tipo de Inconsistência",
    fill = "Gravidade"
  ) +
  theme_peld

ggsave("figuras/01_problemas_auditoria.png", p1, width = 10, height = 6, dpi = 300)

# ------------------------------------------------------------------------------
# Figura 2: Riqueza por local e grupo taxonomico
# ------------------------------------------------------------------------------
message("2. Gerando figura: riqueza por local e grupo...")
riqueza_locais <- read_csv("saidas/tabela_riqueza_locais.csv", show_col_types = FALSE)

p2 <- riqueza_locais %>%
  ggplot(aes(x = fct_reorder(municipio, riqueza_especies, .fun = sum), y = riqueza_especies, fill = grupo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    aes(label = riqueza_especies),
    position = position_dodge(width = 0.8),
    vjust = -0.5,
    size = 3.2
  ) +
  scale_fill_manual(
    values = c("Flora" = "#2ca25f", "Aves" = "#3182bd", "Mammalia" = "#e6550d")
  ) +
  labs(
    title = "Riqueza de Espécies Observada por Município e Grupo Taxonômico",
    subtitle = "Ocorrências canônicas validadas estritamente por ponto-em-poligono (2010–2026)",
    x = "Município Polo",
    y = "Número de Espécies Distintas",
    fill = "Grupo Taxonômico"
  ) +
  ylim(0, max(riqueza_locais$riqueza_especies) * 1.15) +
  theme_peld

ggsave("figuras/02_riqueza_locais.png", p2, width = 9.5, height = 5.5, dpi = 300)

# ------------------------------------------------------------------------------
# Figura 3: Dispersao Paisagem x Indicador Social com Controle de Escala
# ------------------------------------------------------------------------------
message("3. Gerando figura: paisagem x indicador social com controle de escala...")
dados_analise <- read_csv("saidas/tabela_analise.csv", show_col_types = FALSE)

dados_escala_longo <- bind_rows(
  dados_analise %>%
    distinct(municipio, agro_pct_pib, pct_nativa = pct_nativa_mun) %>%
    mutate(escala = "Município Inteiro (buffer 0m)"),
  dados_analise %>%
    distinct(municipio, agro_pct_pib, pct_nativa = pct_nativa_buf5km) %>%
    mutate(escala = "Buffer 5 km (ao redor centroide)"),
  dados_analise %>%
    distinct(municipio, agro_pct_pib, pct_nativa = pct_nativa_buf10km) %>%
    mutate(escala = "Buffer 10 km (ao redor centroide)")
)

dados_escala_longo$escala <- factor(
  dados_escala_longo$escala,
  levels = c("Município Inteiro (buffer 0m)", "Buffer 5 km (ao redor centroide)", "Buffer 10 km (ao redor centroide)")
)

p3 <- dados_escala_longo %>%
  ggplot(aes(x = pct_nativa, y = agro_pct_pib)) +
  geom_point(color = "#1b9e77", size = 3.5) +
  geom_text(aes(label = municipio), vjust = -0.8, size = 3.2, check_overlap = FALSE) +
  geom_smooth(method = "lm", se = FALSE, color = "#d95f02", linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~ escala, scales = "free_x") +
  labs(
    title = "Exercício Didático de Escala (MAUP): Vegetação Nativa vs Agropecuária no PIB",
    subtitle = "A ordenação numérica altera-se com o buffer do centróide (sensibilidade de postos em n=6)",
    x = "Vegetação Nativa (%) - MapBiomas 2024",
    y = "Participação da Agropecuária no PIB (%) - IBGE 2021"
  ) +
  ylim(15, 60) +
  theme_peld

ggsave("figuras/03_escala_paisagem_social.png", p3, width = 11, height = 5, dpi = 300)

# ------------------------------------------------------------------------------
# Figura 4: Controle Negativo (Distribuicao Nula)
# ------------------------------------------------------------------------------
message("4. Gerando figura: controle negativo...")
dist_nula <- read_csv("saidas/distribuicao_nula_controle_negativo.csv", show_col_types = FALSE)
metricas <- fromJSON("saidas/metricas_analise.json")
rho_obs <- metricas$correlacoes_spearman$nativa_mun_vs_agro_pib

p4 <- ggplot(dist_nula, aes(x = rho_nulo)) +
  geom_histogram(bins = 25, fill = "#bcbddc", color = "white", alpha = 0.8) +
  geom_vline(xintercept = rho_obs, color = "#d95f02", linewidth = 1.2, linetype = "solid") +
  geom_vline(xintercept = c(metricas$controle_negativo$ic95_nulo_inferior, metricas$controle_negativo$ic95_nulo_superior),
             color = "gray40", linetype = "dotted", linewidth = 0.9) +
  annotate("text", x = rho_obs + 0.04, y = 110, label = paste0("Observado (rho = ", round(rho_obs, 3), ")\np = ", round(metricas$controle_negativo$p_valor_empirico, 3)),
           color = "#d95f02", fontface = "bold", hjust = 0, size = 3.8) +
  annotate("text", x = metricas$controle_negativo$ic95_nulo_superior, y = 140, label = "Limite Sup. 95%",
           color = "gray30", hjust = 1.05, size = 3.2) +
  labs(
    title = "Controle Negativo: Teste de Permutação (1.000 repetições)",
    subtitle = "O rho observado situa-se dentro da distribuição nula (estocástica) esperada para n=6",
    x = "Coeficiente de Correlação de Spearman Nulo (rho)",
    y = "Frequência de Permutações"
  ) +
  theme_peld

ggsave("figuras/04_controle_negativo.png", p4, width = 8.5, height = 5, dpi = 300)

# ------------------------------------------------------------------------------
# 5. Esquema Relacional do Banco (Mermaid em saidas/esquema.md)
# ------------------------------------------------------------------------------
message("5. Gerando diagrama de esquema relacional em saidas/esquema.md...")

esquema_md <- c(
  "# Esquema Relacional do Banco de Dados Ecológico PELD",
  "",
  "Diagrama entidade-relacionamento (ER) do banco de dados relacional implementado em SQLite (`dados/banco/peld.sqlite`) e exportado em CSVs canônicos.",
  "",
  "```mermaid",
  "erDiagram",
  "    LOCAL ||--o{ CAMPANHA : \"possui agregacoes em\" ",
  "    LOCAL ||--o{ OBSERVACAO : \"localiza\" ",
  "    LOCAL ||--o{ PAISAGEM : \"caracteriza-se por\" ",
  "    LOCAL ||--o{ PERFIL : \"vincula propriedades em\" ",
  "    CAMPANHA ||--o{ OBSERVACAO : \"contem registros em\" ",
  "    ESPECIE ||--o{ OBSERVACAO : \"identifica taxonomicamente\" ",
  "    LOCAL }|--|| SOCIAL : \"associa via codigo_ibge\" ",
  "",
  "    LOCAL {",
  "        string id_local PK",
  "        string nome_local",
  "        string municipio",
  "        string codigo_ibge",
  "        float lat",
  "        float lon",
  "        string tipo_area",
  "        string uc",
  "        string obs",
  "    }",
  "",
  "    CAMPANHA {",
  "        string id_campanha PK",
  "        string id_local FK",
  "        int ano",
  "        string grupo",
  "        date data_inicio",
  "        date data_fim",
  "        string metodo",
  "        float esforco",
  "        string esforco_unidade",
  "        string equipe",
  "        string tipo_evento",
  "        string obs",
  "    }",
  "",
  "    ESPECIE {",
  "        string id_especie PK",
  "        string nome_cientifico",
  "        string nome_aceito",
  "        string familia",
  "        string ordem",
  "        string grupo",
  "        string origem",
  "        string status_conservacao",
  "    }",
  "",
  "    OBSERVACAO {",
  "        string id_observacao PK",
  "        string id_campanha FK",
  "        string id_local FK",
  "        string id_especie FK",
  "        date data",
  "        string precisao_data",
  "        int ano_original",
  "        string grupo",
  "        string especie",
  "        string nome_comum",
  "        float individuos",
  "        int presenca",
  "        string unidade",
  "        string categoria",
  "        float incerteza_metros",
  "        int valido_paisagem",
  "        string fonte",
  "        string id_registro_original",
  "    }",
  "",
  "    PAISAGEM {",
  "        string id_local PK,FK",
  "        int ano PK",
  "        int buffer_m PK",
  "        float area_nativa_km2",
  "        float area_pastagem_km2",
  "        float area_agricultura_km2",
  "        float area_agua_km2",
  "        float area_total_km2",
  "        float pct_nativa",
  "        float pct_pastagem",
  "        float pct_agricultura",
  "        float pct_agua",
  "    }",
  "",
  "    SOCIAL {",
  "        string codigo_ibge PK",
  "        int ano PK",
  "        int populacao",
  "        float pop_rural_pct",
  "        float pib_mil_reais",
  "        float pib_per_capita",
  "        float agro_pct_pib",
  "        string fonte",
  "    }",
  "",
  "    PERFIL {",
  "        string id_propriedade PK",
  "        string id_local FK",
  "        int ano PK",
  "        string variavel PK",
  "        string valor",
  "        string unidade",
  "        string fonte",
  "    }",
  "```",
  "",
  "## Descrição das Tabelas e Relações",
  "",
  "1. **`local`**: Unidade espacial de amostragem (município polo do PELD). Chave primária `id_local`.",
  "2. **`campanha`**: Unidade de agregação temporal-espacial (`id_campanha`), agrupando coletas de mesmo polo, ano e grupo taxonômico. Para dados oportunistas, `esforco = NA` e `esforco_unidade = NA`.",
  "3. **`observacao`**: Tabela longa e atômica (`id_observacao`). Contém registros canônicos validados por ponto-em-polígono. Contém colunas explícitas `presenca = 1L`, `precisao_data` e `valido_paisagem`.",
  "4. **`especie`**: Dicionário taxonômico de referência (`nome_cientifico`), padronizado com `acceptedScientificName`.",
  "5. **`paisagem`**: Métricas de cobertura e uso da terra do MapBiomas Coleção 11 calculadas no Earth Engine (município e buffers de 5 km e 10 km).",
  "6. **`social`**: Indicadores socioeconômicos municipais agregados (Censo 2022, Censo 2010 e PIB 2021 do IBGE/SIDRA).",
  "7. **`perfil`**: Modelo em formato entidade-atributo-valor (EAV) para variáveis de produtores rurais e entrevistas de campo (especificação de modelo vazio)."
)

writeLines(esquema_md, "saidas/esquema.md", useBytes = TRUE)
message("Esquema Mermaid gerado em saidas/esquema.md.")

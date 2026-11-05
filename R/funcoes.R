# ==============================================================================
# R/funcoes.R
# Funcoes utilitarias reutilizaveis para o kit PELD
# Auditoria flexivel via dicionario, mapeamento generico e banco relacional
# ==============================================================================

# Garante biblioteca gravavel do usuario de forma portavel
configurar_ambiente <- function() {
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (nzchar(user_lib) && dir.exists(user_lib)) {
    .libPaths(c(user_lib, .libPaths()))
  } else if (length(.libPaths()) > 0) {
    .libPaths(.libPaths())
  }
}

configurar_ambiente()

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(httr2)
  library(jsonlite)
  library(DBI)
  library(RSQLite)
})

# ------------------------------------------------------------------------------
# 0. Requisicoes HTTP Seguras com Retry
# ------------------------------------------------------------------------------
requisicao_com_retry <- function(url, max_tentativas = 3, espera_seg = 2) {
  tentativa <- 1
  while (tentativa <= max_tentativas) {
    res <- tryCatch({
      req <- request(url) |>
        req_headers(`User-Agent` = "PELD-DataKit/1.0 (LAPIG/UFG; Pesquisa Ecologica)") |>
        req_timeout(30)
      resp <- req_perform(req)
      if (resp_status(resp) == 200) {
        return(resp)
      } else {
        warning(paste("Status HTTP", resp_status(resp), "ao acessar", url))
        NULL
      }
    }, error = function(e) {
      warning(paste("Erro na tentativa", tentativa, ":", e$message))
      NULL
    })
    
    if (!is.null(res)) return(res)
    Sys.sleep(espera_seg * tentativa)
    tentativa <- tentativa + 1
  }
  stop(paste("Falha definitiva ao requisitar:", url))
}

# ------------------------------------------------------------------------------
# 1. Carregamento e Consulta do Dicionario de Colunas
# ------------------------------------------------------------------------------
carregar_dicionario <- function(caminho = "dicionario_colunas.csv") {
  if (!file.exists(caminho)) {
    stop("Arquivo de dicionario nao encontrado: ", caminho)
  }
  df_dict <- read_csv(caminho, show_col_types = FALSE)
  campos_nec <- c("tabela_destino", "campo_destino", "tabela_origem", "campo_origem", "obrigatorio", "tipo_dado")
  faltantes <- setdiff(campos_nec, names(df_dict))
  if (length(faltantes) > 0) {
    stop("Dicionario de colunas invalido. Faltam as colunas: ", paste(faltantes, collapse = ", "))
  }
  df_dict
}

# ------------------------------------------------------------------------------
# 2. Utilitarios de Parsing e Limpeza Rigorosos (Sem Imputacao Arbitraria)
# ------------------------------------------------------------------------------

# Limpa e extrai data com precisao (dia, mes, ano ou desconhecida)
# NUNCA imputa 2020 nem 01-01 ficticio
extrair_data_e_precisao <- function(vetor_datas, vetor_anos = NULL) {
  n <- length(vetor_datas)
  datas_clean <- rep(NA_character_, n)
  precisao <- rep("desconhecida", n)
  ano_orig <- rep(NA_integer_, n)
  
  for (i in seq_len(n)) {
    raw_d <- if (is.null(vetor_datas) || is.na(vetor_datas[i])) "" else trimws(as.character(vetor_datas[i]))
    raw_a <- if (is.null(vetor_anos) || is.na(vetor_anos[i])) "" else trimws(as.character(vetor_anos[i]))
    
    # Se raw_d esta no formato AAAA-MM-DD
    if (str_detect(raw_d, "^\\d{4}-\\d{2}-\\d{2}")) {
      data_iso <- substr(raw_d, 1, 10)
      parsed_d <- suppressWarnings(as.Date(data_iso))
      if (!is.na(parsed_d) && parsed_d >= as.Date("1900-01-01") && parsed_d <= Sys.Date()) {
        datas_clean[i] <- data_iso
        precisao[i] <- "dia"
        ano_orig[i] <- as.integer(substr(data_iso, 1, 4))
        next
      }
    }
    
    # Formato AAAA-MM
    if (str_detect(raw_d, "^\\d{4}-\\d{2}$")) {
      datas_clean[i] <- paste0(raw_d, "-01")
      precisao[i] <- "mes"
      ano_orig[i] <- as.integer(substr(raw_d, 1, 4))
      next
    }
    
    # Formato apenas ano AAAA
    if (str_detect(raw_d, "^\\d{4}$")) {
      a_num <- as.integer(raw_d)
      if (a_num >= 1900 && a_num <= 2026) {
        datas_clean[i] <- paste0(raw_d, "-01-01")
        precisao[i] <- "ano"
        ano_orig[i] <- a_num
        next
      }
    }
    
    # Se data falhou mas ha ano disponivel no vetor_anos
    if (raw_a != "" && str_detect(raw_a, "^\\d{4}$")) {
      a_num <- as.integer(raw_a)
      if (a_num >= 1900 && a_num <= 2026) {
        datas_clean[i] <- paste0(raw_a, "-01-01")
        precisao[i] <- "ano"
        ano_orig[i] <- a_num
        next
      }
    }
    
    datas_clean[i] <- NA_character_
    precisao[i] <- "desconhecida"
    ano_orig[i] <- NA_integer_
  }
  
  tibble(
    data = datas_clean,
    precisao_data = precisao,
    ano_original = ano_orig
  )
}

# Limpa contagem de individuos e presença
# NUNCA transforma contagem ausente em abundancia 1.0!
extrair_contagem_e_presenca <- function(vetor_contagem) {
  n <- length(vetor_contagem)
  individuos <- rep(NA_real_, n)
  unidade <- rep("presenca", n)
  presenca <- rep(1L, n) # Todo registro biologico e uma deteccao/presenca
  
  if (!is.null(vetor_contagem)) {
    num_vals <- suppressWarnings(as.numeric(gsub(",", ".", as.character(vetor_contagem))))
    for (i in seq_len(n)) {
      if (!is.na(num_vals[i]) && num_vals[i] > 0) {
        individuos[i] <- num_vals[i]
        unidade[i] <- "individuos"
      } else {
        individuos[i] <- NA_real_
        unidade[i] <- "presenca"
      }
    }
  }
  
  tibble(
    individuos = individuos,
    presenca = presenca,
    unidade = unidade
  )
}

# ------------------------------------------------------------------------------
# 3. Mapeador Dinamico de Tabelas por Dicionario
# ------------------------------------------------------------------------------
mapear_tabela_por_dicionario <- function(df, nome_tabela_origem, dicionario, tabela_destino = "observacao", grupo_padrao = "Flora") {
  mapa <- dicionario %>%
    filter(tabela_origem == nome_tabela_origem, tabela_destino == tabela_destino)
  
  if (nrow(mapa) == 0) {
    stop("Nenhum mapeamento encontrado no dicionario para tabela_origem='", nome_tabela_origem,
         "' e tabela_destino='", tabela_destino, "'.")
  }
  
  # Verifica colunas obrigatorias
  obrigatorios <- mapa %>% filter(obrigatorio == TRUE) %>% pull(campo_origem)
  faltantes <- setdiff(obrigatorios, names(df))
  if (length(faltantes) > 0) {
    stop("Colunas obrigatorias ausentes na tabela '", nome_tabela_origem, "': ",
         paste(faltantes, collapse = ", "))
  }
  
  pegar_col <- function(campo_dest) {
    m <- mapa %>% filter(campo_destino == campo_dest)
    if (nrow(m) > 0 && m$campo_origem[1] %in% names(df)) {
      df[[m$campo_origem[1]]]
    } else {
      NULL
    }
  }
  
  n_rows <- nrow(df)
  
  # 1. Chaves e identificadores
  col_id_orig <- pegar_col("id_registro_original")
  if (is.null(col_id_orig)) col_id_orig <- pegar_col("id_observacao")
  if (is.null(col_id_orig)) col_id_orig <- as.character(seq_len(n_rows))
  id_orig <- as.character(col_id_orig)
  id_obs <- paste0("OBS_", toupper(substr(nome_tabela_origem, 1, 3)), "_", id_orig)
  
  # 2. Taxonomia
  col_esp <- pegar_col("especie")
  if (is.null(col_esp)) stop("Coluna de especie nao mapeada para ", nome_tabela_origem)
  especie_clean <- trimws(as.character(col_esp))
  col_acc <- if ("acceptedScientificName" %in% names(df)) df[["acceptedScientificName"]] else NULL
  if (!is.null(col_acc)) {
    idx_acc <- which(!is.na(col_acc) & trimws(as.character(col_acc)) != "")
    especie_clean[idx_acc] <- trimws(as.character(col_acc[idx_acc]))
  }
  
  col_comum <- pegar_col("nome_comum")
  nome_comum <- if (is.null(col_comum)) rep(NA_character_, n_rows) else as.character(col_comum)
  
  col_fam <- pegar_col("familia")
  familia <- if (!is.null(col_fam)) {
    coalesce(trimws(as.character(col_fam)), "Não determinada")
  } else if ("family" %in% names(df)) {
    coalesce(trimws(as.character(df[["family"]])), "Não determinada")
  } else {
    rep("Não determinada", n_rows)
  }
  
  col_ord <- pegar_col("ordem")
  ordem <- if (!is.null(col_ord)) {
    coalesce(trimws(as.character(col_ord)), "Não determinada")
  } else if ("order" %in% names(df)) {
    coalesce(trimws(as.character(df[["order"]])), "Não determinada")
  } else {
    rep("Não determinada", n_rows)
  }
  
  col_nome_acc <- pegar_col("nome_aceito")
  nome_aceito <- if (!is.null(col_nome_acc)) {
    coalesce(trimws(as.character(col_nome_acc)), especie_clean)
  } else if ("acceptedScientificName" %in% names(df)) {
    coalesce(trimws(as.character(df[["acceptedScientificName"]])), especie_clean)
  } else {
    especie_clean
  }
  
  col_orig <- pegar_col("origem")
  origem <- if (!is.null(col_orig)) {
    coalesce(trimws(as.character(col_orig)), "Nativa")
  } else if ("establishmentMeans" %in% names(df)) {
    ifelse(!is.na(df[["establishmentMeans"]]) & trimws(as.character(df[["establishmentMeans"]])) != "",
           trimws(as.character(df[["establishmentMeans"]])), "Nativa")
  } else {
    rep("Nativa", n_rows)
  }
  
  col_status <- pegar_col("status_conservacao")
  status_conservacao <- if (!is.null(col_status)) {
    coalesce(trimws(as.character(col_status)), "LC")
  } else if ("iucnRedListCategory" %in% names(df)) {
    coalesce(trimws(as.character(df[["iucnRedListCategory"]])), "LC")
  } else {
    rep("LC", n_rows)
  }
  
  # 3. Grupo
  col_grupo <- pegar_col("grupo")
  grupo <- if (!is.null(col_grupo)) {
    g_raw <- as.character(col_grupo)
    case_when(
      g_raw %in% c("Plantae", "Plantae (Flora)") ~ "Flora",
      g_raw == "Aves" ~ "Aves",
      g_raw == "Mammalia" ~ "Mammalia",
      TRUE ~ g_raw
    )
  } else {
    rep(grupo_padrao, n_rows)
  }
  
  # 4. Data e precisao
  col_data <- pegar_col("data")
  col_ano <- if ("year" %in% names(df)) df[["year"]] else NULL
  res_data <- extrair_data_e_precisao(col_data, col_ano)
  
  # 5. Contagem e presenca
  col_ind <- pegar_col("individuos")
  res_ind <- extrair_contagem_e_presenca(col_ind)
  
  # 6. Coordenadas e incerteza
  col_lat <- pegar_col("lat")
  col_lon <- pegar_col("lon")
  lats <- if (is.null(col_lat)) rep(NA_real_, n_rows) else suppressWarnings(as.numeric(gsub(",", ".", as.character(col_lat))))
  lons <- if (is.null(col_lon)) rep(NA_real_, n_rows) else suppressWarnings(as.numeric(gsub(",", ".", as.character(col_lon))))
  
  col_inc <- pegar_col("incerteza_metros")
  incerteza <- if (is.null(col_inc)) rep(NA_real_, n_rows) else suppressWarnings(as.numeric(gsub(",", ".", as.character(col_inc))))
  valido_paisagem <- if_else(!is.na(incerteza) & incerteza <= 5000, 1L, 0L)
  
  # 7. Local e espacializacao
  # Primeiro tenta o mapeamento declarado; se o 03b ja gravou id_local no CSV,
  # usa a coluna do proprio arquivo (caso da tabela da pesquisadora).
  col_local <- pegar_col("id_local")
  if (!is.null(col_local)) {
    id_local_vec <- as.character(col_local)
  } else if ("id_local" %in% names(df)) {
    id_local_vec <- as.character(df[["id_local"]])
  } else {
    id_local_vec <- rep(NA_character_, n_rows)
  }
  
  fora_area_vec <- if ("fora_area" %in% names(df)) as.logical(df[["fora_area"]]) else is.na(id_local_vec)
  
  # 8. Unidade de agregacao local x ano x grupo
  ano_safe <- if_else(!is.na(res_data$ano_original), as.character(res_data$ano_original), "INDET")
  loc_safe <- if_else(!is.na(id_local_vec), id_local_vec, "FORA")
  grp_prefix <- substr(gsub("[^A-Za-z]", "", grupo), 1, 3)
  id_campanha_vec <- paste0("AGR_", loc_safe, "_", ano_safe, "_", grp_prefix)
  
  col_cat <- pegar_col("categoria")
  categoria <- if (is.null(col_cat)) "FIELD_SAMPLE" else as.character(col_cat)
  
  col_fonte <- pegar_col("fonte")
  fonte_str <- if (is.null(col_fonte)) {
    rep(paste0("GBIF / ", nome_tabela_origem), n_rows)
  } else {
    coalesce(as.character(col_fonte), paste0("GBIF / ", nome_tabela_origem))
  }
  
  tibble(
    id_observacao = id_obs,
    id_campanha = id_campanha_vec,
    id_local = id_local_vec,
    lat = lats,
    lon = lons,
    data = res_data$data,
    precisao_data = res_data$precisao_data,
    ano_original = res_data$ano_original,
    grupo = grupo,
    especie = especie_clean,
    nome_aceito = nome_aceito,
    familia = familia,
    ordem = ordem,
    origem = origem,
    status_conservacao = status_conservacao,
    nome_comum = nome_comum,
    individuos = res_ind$individuos,
    presenca = res_ind$presenca,
    unidade = res_ind$unidade,
    categoria = categoria,
    incerteza_metros = incerteza,
    valido_paisagem = valido_paisagem,
    fora_area = fora_area_vec,
    fonte = fonte_str,
    id_registro_original = id_orig
  )
}

# ------------------------------------------------------------------------------
# 4. Auditoria Flexivel Baseada no Dicionario
# ------------------------------------------------------------------------------
registrar_problema <- function(tabela, campo, linha, tipo_problema, gravidade, descricao, valor_encontrado = NA) {
  tibble(
    tabela = as.character(tabela),
    campo = as.character(campo),
    linha = as.integer(linha),
    tipo_problema = as.character(tipo_problema),
    gravidade = as.character(gravidade),
    descricao = as.character(descricao),
    valor_encontrado = as.character(valor_encontrado)
  )
}

auditar_tabela_por_dicionario <- function(df, nome_tabela_origem, dicionario) {
  problemas <- list()
  mapa <- dicionario %>% filter(tabela_origem == nome_tabela_origem)
  
  if (nrow(mapa) == 0) {
    return(registrar_problema(nome_tabela_origem, "dicionario", 0L, "tabela_nao_mapeada", "critico",
                              "Tabela nao possui mapeamento no dicionario de colunas."))
  }
  
  # 1. Colunas obrigatorias
  obrigatorios <- mapa %>% filter(obrigatorio == TRUE) %>% pull(campo_origem)
  faltantes <- setdiff(obrigatorios, names(df))
  if (length(faltantes) > 0) {
    problemas[[length(problemas) + 1]] <- registrar_problema(
      nome_tabela_origem, paste(faltantes, collapse = ", "), 0L, "colunas_obrigatorias_ausentes", "critico",
      "Colunas marcadas como obrigatorias no dicionario nao foram encontradas no arquivo."
    )
  }
  
  pegar_nome_col <- function(campo_dest) {
    m <- mapa %>% filter(campo_destino == campo_dest)
    if (nrow(m) > 0 && m$campo_origem[1] %in% names(df)) m$campo_origem[1] else NULL
  }
  
  # 2. Coordenadas
  col_lat_name <- pegar_nome_col("lat")
  col_lon_name <- pegar_nome_col("lon")
  if (!is.null(col_lat_name) && !is.null(col_lon_name)) {
    lats <- suppressWarnings(as.numeric(gsub(",", ".", as.character(df[[col_lat_name]]))))
    lons <- suppressWarnings(as.numeric(gsub(",", ".", as.character(df[[col_lon_name]]))))
    
    idx_na <- which(is.na(lats) | is.na(lons))
    if (length(idx_na) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = paste0(col_lat_name, "/", col_lon_name),
        linha = idx_na,
        tipo_problema = "coordenada_ausente",
        gravidade = "critico",
        descricao = "Coordenada geografica ausente ou nao conversivel para numerico",
        valor_encontrado = paste(df[[col_lat_name]][idx_na], df[[col_lon_name]][idx_na], sep = "; ")
      )
    }
    
    idx_zero <- which(abs(lats) < 0.0001 & abs(lons) < 0.0001)
    if (length(idx_zero) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = paste0(col_lat_name, "/", col_lon_name),
        linha = idx_zero,
        tipo_problema = "coordenada_zero",
        gravidade = "critico",
        descricao = "Coordenada em (0, 0)",
        valor_encontrado = paste(lats[idx_zero], lons[idx_zero], sep = "; ")
      )
    }
    
    idx_fora <- which(!is.na(lats) & !is.na(lons) & (lats < -35 | lats > 6 | lons < -75 | lons > -30))
    if (length(idx_fora) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = paste0(col_lat_name, "/", col_lon_name),
        linha = idx_fora,
        tipo_problema = "coordenada_fora_brasil",
        gravidade = "critico",
        descricao = "Coordenadas fora do envelope do Brasil",
        valor_encontrado = paste(lats[idx_fora], lons[idx_fora], sep = "; ")
      )
    }
  }
  
  # 3. Taxonomia
  col_esp_name <- pegar_nome_col("especie")
  if (!is.null(col_esp_name)) {
    esps <- as.character(df[[col_esp_name]])
    idx_esp_na <- which(is.na(esps) | trimws(esps) == "" | esps %in% c("NA", "null", "None"))
    if (length(idx_esp_na) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = col_esp_name,
        linha = idx_esp_na,
        tipo_problema = "taxonomia_vazia",
        gravidade = "critico",
        descricao = "Nome taxonomico ausente ou vazio",
        valor_encontrado = esps[idx_esp_na]
      )
    }
    
    idx_morf <- which(str_detect(esps, regex("\\b(sp\\.?|spp\\.?|cf\\.?|aff\\.?|indet\\.?)\\b", ignore_case = TRUE)))
    if (length(idx_morf) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = col_esp_name,
        linha = idx_morf,
        tipo_problema = "identificacao_morfotipo_incerta",
        gravidade = "menor",
        descricao = "Morfotipo ou genero com qualificadores (sp., cf., aff.)",
        valor_encontrado = esps[idx_morf]
      )
    }
  }
  
  # 4. Datas
  col_data_name <- pegar_nome_col("data")
  if (!is.null(col_data_name)) {
    datas_raw <- as.character(df[[col_data_name]])
    hoje <- Sys.Date()
    
    for (i in seq_along(datas_raw)) {
      d_str <- trimws(datas_raw[i])
      if (is.na(d_str) || d_str == "" || d_str == "NA") next
      
      if (str_detect(d_str, "^\\d{4}$")) {
        problemas[[length(problemas) + 1]] <- tibble(
          tabela = nome_tabela_origem,
          campo = col_data_name,
          linha = i,
          tipo_problema = "data_imprecisa",
          gravidade = "menor",
          descricao = "Data registrada apenas no nivel de ano (sem dia/mes)",
          valor_encontrado = d_str
        )
        next
      }
      
      if (str_detect(d_str, "^\\d{4}-\\d{2}-\\d{2}")) {
        d_parsed <- suppressWarnings(as.Date(substr(d_str, 1, 10)))
        if (!is.na(d_parsed) && d_parsed > hoje) {
          problemas[[length(problemas) + 1]] <- tibble(
            tabela = nome_tabela_origem,
            campo = col_data_name,
            linha = i,
            tipo_problema = "data_no_futuro",
            gravidade = "critico",
            descricao = "Data de evento posterior a data atual",
            valor_encontrado = d_str
          )
        }
        next
      }
      
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = col_data_name,
        linha = i,
        tipo_problema = "data_invalida",
        gravidade = "importante",
        descricao = "Data em formato nao reconhecido",
        valor_encontrado = d_str
      )
    }
  }
  
  # 5. Abundancia / Contagem
  col_ind_name <- pegar_nome_col("individuos")
  if (!is.null(col_ind_name)) {
    vals <- df[[col_ind_name]]
    nums <- suppressWarnings(as.numeric(gsub(",", ".", as.character(vals))))
    
    idx_na_ind <- which(is.na(vals) | trimws(as.character(vals)) == "" | trimws(as.character(vals)) == "NA")
    if (length(idx_na_ind) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = col_ind_name,
        linha = idx_na_ind,
        tipo_problema = "abundancia_ausente",
        gravidade = "menor",
        descricao = "Contagem ausente; mantido individuos=NA e presenca=1L (nao comparavel como abundancia)",
        valor_encontrado = "NA"
      )
    }
    
    idx_neg <- which(!is.na(nums) & nums < 0)
    if (length(idx_neg) > 0) {
      problemas[[length(problemas) + 1]] <- tibble(
        tabela = nome_tabela_origem,
        campo = col_ind_name,
        linha = idx_neg,
        tipo_problema = "abundancia_negativa",
        gravidade = "critico",
        descricao = "Numero de individuos negativo",
        valor_encontrado = as.character(vals[idx_neg])
      )
    }
  }
  
  # 6. Deteccao de formato Wide
  cols_binomiais <- names(df)[str_detect(names(df), "^[A-Z][a-z]+[ _][a-z]+")]
  if (length(cols_binomiais) >= 3) {
    problemas[[length(problemas) + 1]] <- tibble(
      tabela = nome_tabela_origem,
      campo = paste(cols_binomiais[1:min(3, length(cols_binomiais))], collapse = ", "),
      linha = 0L,
      tipo_problema = "estrutura_formato_wide",
      gravidade = "importante",
      descricao = paste0("Detectadas ", length(cols_binomiais), " colunas com nomes binomials. Sugere-se pivot_longer()."),
      valor_encontrado = paste(head(cols_binomiais, 5), collapse = ", ")
    )
  }
  
  bind_rows(problemas)
}

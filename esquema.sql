-- ==============================================================================
-- esquema.sql
-- Definicao DDL do banco relacional PELD (SQLite)
-- Garante integridade referencial, tipos canônicos e comentarios
-- ==============================================================================

PRAGMA foreign_keys = ON;

-- 1. Tabela local
-- Representa os polos municipais amostrados no sudoeste goiano
CREATE TABLE IF NOT EXISTS local (
    id_local TEXT PRIMARY KEY,
    nome_local TEXT NOT NULL,
    municipio TEXT NOT NULL,
    codigo_ibge TEXT NOT NULL,
    lat REAL NOT NULL,
    lon REAL NOT NULL,
    tipo_area TEXT,
    uc TEXT,
    obs TEXT
);

-- 2. Tabela campanha (unidade de agregacao temporal-espacial)
-- Agregacao local x ano x grupo (esforco = NULL para dados oportunistas)
CREATE TABLE IF NOT EXISTS campanha (
    id_campanha TEXT PRIMARY KEY,
    id_local TEXT NOT NULL,
    ano INTEGER,
    grupo TEXT,
    data_inicio TEXT,
    data_fim TEXT,
    metodo TEXT,
    esforco REAL,
    esforco_unidade TEXT,
    equipe TEXT,
    tipo_evento TEXT DEFAULT 'unidade_agregacao',
    obs TEXT,
    FOREIGN KEY (id_local) REFERENCES local(id_local) ON DELETE CASCADE
);

-- 3. Tabela especie
-- Dicionario taxonomico de referencia para nomes cientificos aceitos
CREATE TABLE IF NOT EXISTS especie (
    id_especie TEXT PRIMARY KEY,
    nome_cientifico TEXT UNIQUE NOT NULL,
    nome_aceito TEXT,
    familia TEXT,
    ordem TEXT,
    grupo TEXT NOT NULL,
    origem TEXT,
    status_conservacao TEXT
);

-- 4. Tabela observacao
-- Tabela longa: cada linha e um registro canonico de ocorrencia biológica
CREATE TABLE IF NOT EXISTS observacao (
    id_observacao TEXT PRIMARY KEY,
    id_campanha TEXT NOT NULL,
    id_local TEXT NOT NULL,
    id_especie TEXT NOT NULL,
    data TEXT,
    precisao_data TEXT,
    ano_original INTEGER,
    grupo TEXT NOT NULL,
    especie TEXT NOT NULL,
    nome_comum TEXT,
    individuos REAL,
    presenca INTEGER NOT NULL DEFAULT 1,
    unidade TEXT NOT NULL DEFAULT 'presenca',
    categoria TEXT,
    incerteza_metros REAL,
    valido_paisagem INTEGER NOT NULL DEFAULT 0,
    fonte TEXT NOT NULL,
    id_registro_original TEXT,
    FOREIGN KEY (id_campanha) REFERENCES campanha(id_campanha) ON DELETE CASCADE,
    FOREIGN KEY (id_local) REFERENCES local(id_local) ON DELETE CASCADE,
    FOREIGN KEY (id_especie) REFERENCES especie(id_especie) ON DELETE RESTRICT
);

-- 5. Tabela paisagem
-- Metricas de uso e cobertura da terra (MapBiomas) por local, ano e escala
CREATE TABLE IF NOT EXISTS paisagem (
    id_local TEXT NOT NULL,
    ano INTEGER NOT NULL,
    buffer_m INTEGER NOT NULL,
    area_nativa_km2 REAL NOT NULL,
    area_pastagem_km2 REAL NOT NULL,
    area_agricultura_km2 REAL NOT NULL,
    area_agua_km2 REAL NOT NULL,
    area_total_km2 REAL NOT NULL,
    pct_nativa REAL NOT NULL,
    pct_pastagem REAL NOT NULL,
    pct_agricultura REAL NOT NULL,
    pct_agua REAL NOT NULL,
    PRIMARY KEY (id_local, ano, buffer_m),
    FOREIGN KEY (id_local) REFERENCES local(id_local) ON DELETE CASCADE
);

-- 6. Tabela social
-- Indicadores socioeconomicos municipais agregados (IBGE/SIDRA)
CREATE TABLE IF NOT EXISTS social (
    codigo_ibge TEXT NOT NULL,
    ano INTEGER NOT NULL,
    populacao INTEGER NOT NULL,
    pop_rural_pct REAL NOT NULL,
    pib_mil_reais REAL NOT NULL,
    pib_per_capita REAL NOT NULL,
    agro_pct_pib REAL NOT NULL,
    fonte TEXT NOT NULL,
    PRIMARY KEY (codigo_ibge, ano)
);

-- 7. Tabela perfil (modelo vazio para futuros dados de entrevistas/propriedades)
CREATE TABLE IF NOT EXISTS perfil (
    id_propriedade TEXT NOT NULL,
    id_local TEXT NOT NULL,
    ano INTEGER NOT NULL,
    variavel TEXT NOT NULL,
    valor TEXT NOT NULL,
    unidade TEXT,
    fonte TEXT,
    PRIMARY KEY (id_propriedade, variavel, ano),
    FOREIGN KEY (id_local) REFERENCES local(id_local) ON DELETE CASCADE
);

-- Indices para otimizacao de consultas analiticas
CREATE INDEX IF NOT EXISTS idx_obs_local ON observacao(id_local);
CREATE INDEX IF NOT EXISTS idx_obs_campanha ON observacao(id_campanha);
CREATE INDEX IF NOT EXISTS idx_obs_especie ON observacao(especie);
CREATE INDEX IF NOT EXISTS idx_paisagem_local ON paisagem(id_local, ano);

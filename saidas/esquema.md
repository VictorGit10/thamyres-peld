# Esquema Relacional do Banco de Dados Ecológico PELD

Diagrama entidade-relacionamento (ER) do banco de dados relacional implementado em SQLite (`dados/banco/peld.sqlite`) e exportado em CSVs canônicos.

```mermaid
erDiagram
    LOCAL ||--o{ CAMPANHA : "possui agregacoes em" 
    LOCAL ||--o{ OBSERVACAO : "localiza" 
    LOCAL ||--o{ PAISAGEM : "caracteriza-se por" 
    LOCAL ||--o{ PERFIL : "vincula propriedades em" 
    CAMPANHA ||--o{ OBSERVACAO : "contem registros em" 
    ESPECIE ||--o{ OBSERVACAO : "identifica taxonomicamente" 
    LOCAL }|--|| SOCIAL : "associa via codigo_ibge" 

    LOCAL {
        string id_local PK
        string nome_local
        string municipio
        string codigo_ibge
        float lat
        float lon
        string tipo_area
        string uc
        string obs
    }

    CAMPANHA {
        string id_campanha PK
        string id_local FK
        int ano
        string grupo
        date data_inicio
        date data_fim
        string metodo
        float esforco
        string esforco_unidade
        string equipe
        string tipo_evento
        string obs
    }

    ESPECIE {
        string id_especie PK
        string nome_cientifico
        string nome_aceito
        string familia
        string ordem
        string grupo
        string origem
        string status_conservacao
    }

    OBSERVACAO {
        string id_observacao PK
        string id_campanha FK
        string id_local FK
        string id_especie FK
        date data
        string precisao_data
        int ano_original
        string grupo
        string especie
        string nome_comum
        float individuos
        int presenca
        string unidade
        string categoria
        float incerteza_metros
        int valido_paisagem
        string fonte
        string id_registro_original
    }

    PAISAGEM {
        string id_local PK,FK
        int ano PK
        int buffer_m PK
        float area_nativa_km2
        float area_pastagem_km2
        float area_agricultura_km2
        float area_agua_km2
        float area_total_km2
        float pct_nativa
        float pct_pastagem
        float pct_agricultura
        float pct_agua
    }

    SOCIAL {
        string codigo_ibge PK
        int ano PK
        int populacao
        float pop_rural_pct
        float pib_mil_reais
        float pib_per_capita
        float agro_pct_pib
        string fonte
    }

    PERFIL {
        string id_propriedade PK
        string id_local FK
        int ano PK
        string variavel PK
        string valor
        string unidade
        string fonte
    }
```

## Descrição das Tabelas e Relações

1. **`local`**: Unidade espacial de amostragem (município polo do PELD). Chave primária `id_local`.
2. **`campanha`**: Unidade de agregação temporal-espacial (`id_campanha`), agrupando coletas de mesmo polo, ano e grupo taxonômico. Para dados oportunistas, `esforco = NA` e `esforco_unidade = NA`.
3. **`observacao`**: Tabela longa e atômica (`id_observacao`). Contém registros canônicos validados por ponto-em-polígono. Contém colunas explícitas `presenca = 1L`, `precisao_data` e `valido_paisagem`.
4. **`especie`**: Dicionário taxonômico de referência (`nome_cientifico`), padronizado com `acceptedScientificName`.
5. **`paisagem`**: Métricas de cobertura e uso da terra do MapBiomas Coleção 11 calculadas no Earth Engine (município e buffers de 5 km e 10 km).
6. **`social`**: Indicadores socioeconômicos municipais agregados (Censo 2022, Censo 2010 e PIB 2021 do IBGE/SIDRA).
7. **`perfil`**: Modelo em formato entidade-atributo-valor (EAV) para variáveis de produtores rurais e entrevistas de campo (especificação de modelo vazio).

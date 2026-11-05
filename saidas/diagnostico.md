# Diagnóstico de Auditoria de Dados Brutos (Orientado pelo Dicionário)

**Data da Auditoria:** 2026-11-04 15:27:05.688782
**Total de inconformidades/alertas detectados:** 8613

## 1. Resumo por Gravidade

| Gravidade | Ocorrências | Impacto Metodológico |
| :--- | :--- | :--- |
| **Crítico** | 0 | Erros que impedem o pareamento relacional ou corrompem coordenadas |
| **Importante** | 6170 | Registros fora dos 6 polos, incerteza espacial > 10 km, sinonímias e ausência de esforço |
| **Menor** | 2443 | Ausência de contagem numérica (tratada como presença = 1) e datas com precisão de ano |

## 2. Detalhamento por Tabela e Tipo de Inconsistência

| Tabela | Tipo de Inconsistência | Gravidade | Ocorrências | Ação Executada no Pipeline |
| :--- | :--- | :--- | :--- | :--- |
| `gbif_fauna` | `esforco_amostral_ausente` | **importante** | 1500 | Atribui esforco = NA_real_ e trata campanha como unidade de agregacao |
| `gbif_flora` | `esforco_amostral_ausente` | **importante** | 1500 | Atribui esforco = NA_real_ e trata campanha como unidade de agregacao |
| `gbif_fauna` | `municipio_textual_ausente` | **importante** | 1499 | Atribui municipio via point-in-polygon com GeoJSONs oficiais do IBGE |
| `gbif_fauna` | `incerteza_espacial_elevada` | **importante** | 639 | Registra incerteza_metros e marca valido_paisagem = 0 para buffers locais |
| `gbif_fauna` | `registro_fora_poligonos_peld` | **importante** | 639 | Exclui do banco SQLite canônico e preserva no relatorio de auditoria |
| `gbif_flora` | `registro_fora_poligonos_peld` | **importante** | 237 | Exclui do banco SQLite canônico e preserva no relatorio de auditoria |
| `gbif_flora` | `sinonimia_ou_divergencia_taxonomica` | **importante** | 79 | Padroniza nome pelo acceptedScientificName |
| `gbif_fauna` | `sinonimia_ou_divergencia_taxonomica` | **importante** | 77 | Padroniza nome pelo acceptedScientificName |
| `gbif_flora` | `abundancia_ausente` | **menor** | 1288 | Atribui individuos = NA e presenca = 1L (nunca confunde presenca com abundancia) |
| `gbif_fauna` | `abundancia_ausente` | **menor** | 1105 | Atribui individuos = NA e presenca = 1L (nunca confunde presenca com abundancia) |
| `gbif_flora` | `data_imprecisa` | **menor** | 48 | Mantem precisao_data = 'ano' e ano_original sem imputar dias ficticios |
| `minha_flora` | `abundancia_ausente` | **menor** | 2 | Atribui individuos = NA e presenca = 1L (nunca confunde presenca com abundancia) |

## 3. Registros Biológicos e Aproveitamento Espacial

A atribuição espacial por polígono (point-in-polygon) realizada em `codigo/03b_atribuir_locais.py` filtrou com precisão as ocorrências que pertencem estritamente aos 6 municípios polo do PELD:
- **Flora:** 1.263 registros dentro dos 6 municípios (84,2%) | 237 registros em municípios vizinhos da caixa geográfica.
- **Fauna:** 861 registros dentro dos 6 municípios (57,4%) | 639 registros em municípios vizinhos da caixa geográfica.
- **Total Canônico no Banco:** 2.124 ocorrências (100% georreferenciadas dentro dos limites municipais do PELD).
- **Total Fora do Polígono (não ingeridos):** 876 ocorrências.

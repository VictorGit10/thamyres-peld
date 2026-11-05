# Guia de Contexto para Agentes de IA — Kit PELD Goiás

Este documento fornece as diretrizes arquiteturais, contexto de dados, sequência de execução e armadilhas identificadas para que qualquer agente de inteligência artificial dê continuidade a este projeto de ecologia quantitativa e engenharia de dados.

---

## 1. Contexto Geral do Projeto

- **Usuária / Pesquisadora:** Ecóloga trabalhando com conservação e biodiversidade no PELD (sudoeste de Goiás, entorno do Parque Nacional das Emas e bacia do Rio Araguaia/Paranaíba).
- **Problema de Negócio / Científico:** Múltiplas tabelas heterogêneas de coletas de fauna e flora precisam ser auditadas e normalizadas para um esquema canônico único (SQLite + CSVs) e integradas a métricas de paisagem (MapBiomas Coleção 11) e indicadores socioeconômicos (IBGE).
- **Linguagem Principal:** R (`tidyverse`, `janitor`, `DBI`, `RSQLite`, `httr2`, `jsonlite`, `scales`).
- **Linguagem Auxiliar:** Python (usado estritamente para a extração do Google Earth Engine em [`codigo/03_paisagem_gee.py`](codigo/03_paisagem_gee.py)).

---

## 2. Caminhos e Ambiente de Execução Local

- **Binário do R (nesta máquina):** `C:\Program Files\R\R-4.6.2\bin\Rscript.exe`
- **Biblioteca Gravável do Usuário (R):** o código usa `Sys.getenv("R_LIBS_USER")`; nesta máquina ela aponta para `<usuário>\AppData\Local\R\win-library\4.6`. Em outra máquina, não edite o caminho: o `R_LIBS_USER` do R já aponta para a biblioteca pessoal. A pasta de `Program Files` não é gravável pelo usuário comum.
- **Google Earth Engine (Python):** `ee.Initialize(project = Sys.getenv("GEE_PROJECT", "SEU-PROJETO-EARTH-ENGINE"))`; nesta máquina o padrão é `SEU-PROJETO-EARTH-ENGINE`. Em outra, defina `GEE_PROJECT`.

---

## 3. Ordem Estrita de Execução dos Scripts

1. `Rscript codigo/00_instalar.R`: Garante presença dos 7 pacotes R essenciais.
2. `Rscript codigo/01_baixar_gbif.R`: Baixa 3.000 ocorrências públicas do GBIF (1.500 Flora e 1.500 Fauna) e registra metadados em `dados/bruto/fontes.json`.
3. `Rscript codigo/02_baixar_ibge.R`: Baixa malhas municipais (GeoJSON), extrai centroides e consulta tabelas 9514 (Censo 2022), 200 (Censo 2010) e 5938 (PIB 2021) do SIDRA.
4. `python codigo/03_paisagem_gee.py`: Extrai no Earth Engine métricas de vegetação nativa, pastagem, agricultura e água para município inteiro e buffers de 5 km e 10 km (anos 2015, 2020 e 2024).
5. `python codigo/03b_atribuir_locais.py`: Executa junção espacial estrita (point-in-polygon com GeoPandas) associando ocorrências aos 6 municípios do PELD e separando pontos externos.
6. `Rscript codigo/04_auditar.R`: Audita tabelas declaradas em `dicionario_colunas.csv` e emite relatório de problemas e gravidade.
7. `Rscript codigo/05_padronizar.R`: Ingestão orientada a dicionário, cria banco SQLite (`dados/banco/peld.sqlite`), exclui pontos fora da área e valida chaves estrangeiras.
8. `Rscript codigo/06_juntar.R`: Constrói a tabela consolidada `saidas/tabela_analise.csv` (separando registros, presenças e contagens reais).
9. `Rscript codigo/07_analisar.R`: Realiza testes estatísticos de Spearman, modelo linear, controle de escala (MAUP) e teste de permutação (controle negativo).
10. `Rscript codigo/08_figuras.R`: Gera figuras de alta qualidade em `figuras/` e esquema relacional em `saidas/esquema.md`.
11. `Rscript codigo/10_teste_dicionario.R`: Teste unitário provando ingestão e padronização de tabela com colunas arbitrárias (`dados/exemplo/minha_flora.csv`).
12. `Rscript codigo/10b_teste_fluxo_completo.R`: Teste de integração em pasta temporária que roda `03b + 05 + 06` com `minha_flora.csv` e confirma as 6 linhas no banco.
13. `Rscript codigo/11_verificar_numeros.R`: Asserções automatizadas conferindo os números-chave do relatório contra as saídas reais.
14. `Rscript codigo/99_rodar_tudo.R`: Orquestrador mestre do pipeline executado sequencialmente do zero.

---

## 4. Armadilhas e Lições Aprendidas

1. **Darwin Core: Município Ausente e Junção Espacial:** O campo textual `municipality` nos registros de aves e mamíferos do GBIF veio 99,9% nulo (`NA`). Nunca filtre fauna pelo nome textual do município; utilize sempre junção espacial pontual sobre polígono (`geopandas.sjoin` ou `sf`) contra os limites municipais oficiais. Registros fora dos municípios de estudo (876 registros nos dados brutos) devem ser mantidos fora do banco canônico para evitar distorções.
2. **Esforço Amostral Oportunista e Contagens Reais:** Coleções de herbários e plataformas públicas não possuem campo de esforço amostral padronizado (`sampleSizeValue`). Nunca invente esforços artificiais: mantenha `esforco = NA` e nomeie esses agrupamentos como "unidades de agregação". Quando não houver contagem numérica, use `individuos = NA` e marque `presenca = 1L`. Jamais chame soma de presenças de "abundância".
3. **Inversão de Sinal por Efeito de Escala (MAUP):** No controle de escala, a correlação de Spearman entre % nativa e PIB per capita inverteu de $\rho = -0,6000$ (escala municipal) para $\rho = +0,4286$ (buffer local de 5 km). Esse fenômeno decorre da sensibilidade de postos em amostras pequenas ($n=6$) e da posição do centroide, devendo ser qualificado como exercício didático de sensibilidade numérica, e não como descoberta ecológica.
4. **Falácia Ecológica em Socioeconomia:** Variáveis do Censo e do PIB municipal representam agregados macroeconômicos. É metodologicamente inválido transferir essas correlações para o perfil individual do proprietário rural sem dados primários de questionários ([`dados/modelo_perfil_propriedade.csv`](dados/modelo_perfil_propriedade.csv)).
5. **Motor de Dicionário Declarativo:** O mapeamento de colunas arbitrárias deve ser orientado ao `dicionario_colunas.csv`. O script `R/funcoes.R` provê o motor `mapear_tabela_por_dicionario()`, permitindo que novas planilhas da pesquisadora sejam incorporadas sem necessidade de refatorar os scripts analíticos centrais.

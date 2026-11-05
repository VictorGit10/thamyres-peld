# Pedido — do caos de planilhas ao banco de dados ecológico: um kit em R para fauna, flora e paisagem

Leia antes `REGRAS-COMUNS.md` e `CONTEXTO.md` (os dois estão nesta pasta).

## O que queremos

A pesquisadora trabalha com biodiversidade e conservação no PELD de Goiás. Ela tem **várias tabelas de fauna e flora** e quer organizá-las de um jeito prático para extrair as informações de que precisa. Também pretende cruzar esses dados com a **paisagem e o perfil socioambiental** das pessoas da região. Ela usa **R**.

O gargalo não é o modelo estatístico: é chegar a uma **tabela análise-pronta** sem perder informação, sem duplicar registros e sem depender de uma planilha específica. Queremos um kit pequeno, **executado com dados públicos reais**, que:

1. audite tabelas heterogêneas e aponte problemas concretos;
2. mapeie as colunas existentes para um esquema canônico **sem exigir que ela mude as planilhas**;
3. monte um banco relacional (SQLite + CSVs) e tabelas de análise;
4. mostre, com um exemplo real, como ligar biodiversidade × paisagem × perfil socioeconômico — e onde essa ligação engana (escala, falácia ecológica, esforço amostral);
5. deixe um caminho claro para ela aplicar o kit às tabelas dela.

## Princípios

- **Tudo em R** (tidyverse etc.), porque é a ferramenta dela. Python só se for indispensável para baixar ou geoprocessar; nesse caso, o R lê CSV e o README explica.
- **Não invente as tabelas dela.** Use dados públicos reais da região do PELD CEMA/EBMN (sudoeste goiano) como *stand-in* e diga isso em cada arquivo. O que é real, o que é stand-in e o que é modelo vazio precisa estar explícito no `RELATORIO.md`.
- O kit **não pode depender dos nomes de colunas dos dados de exemplo**: o mapeamento é um CSV que a pessoa edita.
- **Todo número do relatório sai de um script.** Nada de "cerca de".
- **Nada de login.** GBIF e IBGE são APIs abertas; o Earth Engine já está autenticado nesta máquina.
- **Limite de 1 GB**; baixe só o necessário.

## Ambiente desta máquina

- R 4.6.2 em `C:\Program Files\R\R-4.6.2\bin\Rscript.exe`.
- Biblioteca de usuário (use esta, a de `Program Files` não é gravável):
  `<usuário>\AppData\Local\R\win-library\4.6`.
  No começo de cada script: `.libPaths(c("<usuário>/AppData/Local/R/win-library/4.6", .libPaths()))`.
- Pacotes já instalados ou em instalação: `tidyverse`, `janitor`, `DBI`, `RSQLite`, `jsonlite`, `httr2`, `scales`. Se faltar algum, instale com `install.packages(..., lib = "<usuário>/AppData/Local/R/win-library/4.6", type = "binary")`.
- Python 3.14 com `earthengine-api`, `pandas`, `geopandas`, `matplotlib`. Earth Engine: `ee.Initialize(project='SEU-PROJETO-EARTH-ENGINE')`.

## Dados (com fontes e fallback)

1. **Fauna e flora (GBIF, sem login).** Baixe ocorrências com coordenada para o sudoeste goiano (caixa lat -19,0 a -17,0; lon -53,0 a -50,5), 2010–2026:
   - flora: `taxonKey=6` (Plantae), `basisOfRecord=PRESERVED_SPECIMEN`;
   - fauna: `taxonKey=212` (Aves) e `taxonKey=359` (Mammalia), todos os `basisOfRecord`.
   - Pagine com `limit=300`; guarde os campos crus; registre a URL exata e a data da consulta em `dados/bruto/fontes.json`. Se a API falhar, use o dataset PELD-AGCV no GBIF como fallback e diga.
2. **Locais.** Seis municípios do entorno do PELD (ex.: Jataí, Rio Verde, Mineiros, Caiapônia, Perolândia, Serranópolis) com código IBGE, centroide e área. Calcule os centroides da malha municipal do IBGE (`https://servicodados.ibge.gov.br/api/v3/malhas/municipios/{codigo}?formato=application/vnd.geo+json`) no script; se preferir, use coordenadas documentadas.
3. **Paisagem.** MapBiomas Coleção 11 no Earth Engine (`projects/mapbiomas-public/assets/brazil/lulc/collection11/mapbiomas_brazil_collection11_coverage_v3`), bandas `classification_2015`, `classification_2020` e `classification_2024` (confira se a de 2025 está estável; use a mais recente que estiver):
   - para cada município e ano, área (km²) de: vegetação nativa (classes 3, 4, 11, 12, 29), pastagem (15), agricultura (18, 19, 20, 36, 39, 40, 41, 46, 47, 48), urbano (24), água (33) e outras;
   - e, como **controle de escala**, a mesma conta num buffer de 5 km e de 10 km ao redor do centroide municipal (ou de cada local). O objetivo é mostrar que o número muda com a unidade.
   - Se o Earth Engine falhar, use as estatísticas municipais do MapBiomas (plataforma/Base dos Dados) e documente; não invente.
4. **Perfil socioeconômico (IBGE/SIDRA, sem login).** Para os seis municípios:
   - população residente 2022 (tabela 9514, variável 93);
   - população urbana/rural 2010 (tabela 200, variável 93; calcule % rural);
   - PIB 2021 (tabela 5938, variável 37) e PIB per capita (PIB ÷ população 2022, com a ressalva dos anos diferentes);
   - participação da agropecuária no PIB (variável 513 ÷ 37).
   - Se quiser IDHM, só use fonte oficial e deixe a URL; se não conseguir baixar, não use.
5. **Perfil de pessoas (o que não existe publicamente).** Crie `dados/modelo_perfil_propriedade.csv` com colunas sugeridas (`id_propriedade`, `id_local`, `municipio`, `ano`, `tipo_producao`, `tempo_na_propriedade`, `area_ha`, `pct_reserva_legal`, `participa_associacao`, `renda_declarada`, `fonte`) e deixe claro que é **modelo vazio**, não dado. A análise com esse arquivo fica como próximo passo dela.

## O kit (R)

Estrutura sugerida (ajuste nomes se necessário):

- `codigo/00_instalar.R` — instala/verifica pacotes.
- `codigo/01_baixar_gbif.R` — baixa e salva `dados/bruto/gbif_flora.csv` e `gbif_fauna.csv`; registra a consulta.
- `codigo/02_baixar_ibge.R` — baixa SIDRA; salva `dados/bruto/social_municipios.csv`.
- `codigo/03_paisagem_gee.py` — calcula paisagem no Earth Engine e salva `dados/bruto/paisagem.csv`; o R não depende do GEE para rodar o resto.
- `codigo/04_auditar.R` — recebe uma ou mais tabelas e o dicionário; gera `saidas/diagnostico.md`, `saidas/problemas.csv` e `saidas/resumo_auditoria.csv`.
- `codigo/05_padronizar.R` — aplica o dicionário, limpa tipos, valida chaves e gera `dados/banco/*.csv` + `dados/banco/peld.sqlite` com o esquema.
- `codigo/06_juntar.R` — monta `saidas/tabela_analise.csv` (local × campanha × grupo × ano × paisagem × social) e relata linhas sem correspondência.
- `codigo/07_analisar.R` — riqueza/registros por local e ano; junta paisagem/social; calcula Spearman e um modelo simples **só como exercício**, com n e incerteza; faz o controle de escala (município × buffer 5 km × 10 km) e um controle negativo (embaralhar os rótulos e mostrar que a "relação" desaparece).
- `codigo/08_figuras.R` — figuras: (a) esquema do banco (SVG simples ou Mermaid em `saidas/esquema.md`), (b) problemas por tipo na auditoria, (c) riqueza por local/grupo, (d) dispersão paisagem × indicador social com o controle de escala.
- `codigo/99_rodar_tudo.R` — roda na ordem, do zero.
- `R/funcoes.R` — funções reutilizáveis e testáveis.
- `dicionario_colunas.csv` — o coração: uma linha por campo canônico × tabela de origem × coluna de origem × transformação. Deve cobrir as duas tabelas de exemplo e servir de modelo para as tabelas dela.
- `esquema.sql` — DDL do SQLite com PK/FK e comentários.
- `dados/bruto/` — os brutos baixados; `dados/banco/` — as saídas.
- `figuras/`, `saidas/`.

## O esquema canônico (mínimo)

- `local(id_local, nome_local, municipio, codigo_ibge, lat, lon, tipo_area, uc, obs)`
- `campanha(id_campanha, id_local, data_inicio, data_fim, metodo, esforco, esforco_unidade, equipe, obs)`
- `observacao(id_observacao, id_campanha, id_local, data, grupo, especie, nome_comum, individuos, unidade, categoria, fonte, id_registro_original)`
- `especie(nome_cientifico, nome_aceito, familia, grupo, origem, status_conservacao)`
- `paisagem(id_local, ano, buffer_m, area_nativa_km2, area_pastagem_km2, area_agricultura_km2, area_agua_km2, area_total_km2, pct_nativa, pct_pastagem, pct_agricultura, pct_agua)`
- `social(codigo_ibge, ano, populacao, pop_rural_pct, pib_mil_reais, pib_per_capita, agro_pct_pib, fonte)`
- `perfil(id_propriedade, id_local, ano, variavel, valor, unidade, fonte)` — modelo vazio.

Regras do esquema:

- `observacao` é **longa**: uma linha por espécie × campanha × local (não uma coluna por espécie).
- `individuos` é contagem; se a tabela só tem presença, use `1` e `unidade = "presenca"` — e diga que riqueza e abundância não são comparáveis.
- Toda tabela tem `id_*` estável e `fonte`/`id_registro_original` para rastrear.
- Chaves estrangeiras validadas; o script falha (ou avisa) se houver órfão.

## A auditoria (o que ela precisa pegar)

Implemente checagens que falham de verdade nos dados de exemplo:

1. codificação/separador/cabeçalho; nomes de colunas duplicados/vazios;
2. `id` duplicado; chaves órfãs entre tabelas;
3. datas em formatos mistos, inválidas, fora do intervalo; data de fim < início;
4. coordenadas ausentes, fora do Brasil, (0,0), lat/lon trocados, precisão/incerteza;
5. nomes científicos: vazios, `sp.`/`cf.`/`aff.`, autor/ano, sinônimos (compare `scientificName` com `acceptedScientificName`), duplicatas de mesmo registro;
6. abundância: negativa, fracionária, ausente; esforço amostral ausente;
7. formato wide: detecte colunas que são nomes de espécies e sugira `pivot_longer`;
8. unidades: DBH, altura, área, esforço; valores fora de faixa plausível;
9. consistência entre tabelas: nomes de locais, municípios, anos, táxons;
10. no fim: um resumo com contagem por tipo e gravidade (crítico/importante/menor) e uma lista do que **não** foi possível checar.

## A análise socioambiental (pequena e honesta)

- Calcule riqueza (n espécies distintas) e registros por local/ano/grupo. Não compare abundância entre métodos sem esforço.
- Junte paisagem (município e buffers) e social.
- Faça **uma** pergunta: "municípios com mais vegetação nativa têm perfil socioeconômico diferente?" — com n = 6, use Spearman e um gráfico; não use p-valor como prova.
- Mostre o **controle de escala**: a correlação/ordenação muda entre município, buffer 5 km e buffer 10 km. Tabela com os três.
- Mostre o **controle negativo**: embaralhe os valores de paisagem 1.000 vezes; a correlação observada deve estar dentro da distribuição nula se não houver relação. Se estiver fora, diga que é sugestivo, não causal.
- Escreva a limitação: agregação municipal não mede "perfil de pessoas"; para isso, o dado tem de ser da propriedade/entrevista. A falácia ecológica é o risco principal.
- Se os dados de fauna forem escassos, não force: use flora para a riqueza e diga que fauna é ilustrativa.

## Entregas

As de `REGRAS-COMUNS.md`, mais:

- `ROTEIRO-ENCONTRO.md` — 40 min: o que mostrar em cada bloco, 3 perguntas para ela, o que deixar como próxima tarefa.
- `REVISAO-ALVO.md` — as 12 afirmações/números centrais do `RELATORIO.md`, cada uma com o script e o arquivo de onde saiu, e as limitações que não podem ser omitidas. É o alvo da revisão de 3 passadas.
- No `RELATORIO.md`, uma seção **"O que é real, o que é stand-in e o que é modelo vazio"**.
- No `README.md`, um passo a passo de 10 minutos para ela aplicar nas tabelas dela: preencher o dicionário, rodar `04`, `05`, `06`.
- `saidas/esquema.md` (Mermaid) ou `figuras/esquema.svg` com o desenho das tabelas e chaves.

## Critérios de aceitação

- `Rscript codigo/99_rodar_tudo.R` roda do zero nesta máquina e produz todos os arquivos citados.
- Nenhum número no relatório sem script que o gere.
- O dicionário cobre 100% das colunas usadas; o script avisa se uma coluna obrigatória falta.
- A auditoria encontra pelo menos 5 problemas reais nos dados brutos (com exemplo e contagem) e não inventa problema nos campos corretos.
- O controle de escala mostra números diferentes para as três unidades; o controle negativo está implementado e interpretado.
- As referências (5 a 10) têm DOI conferido no Crossref; nenhuma inventada.

## Tempo

~90 min. Prefira um kit pequeno e rodado a um kit grande e quebrado.

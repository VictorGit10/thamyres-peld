# CORRECOES-REVISAO.md — Relatório de Ações e Correções Pós-Revisão de Três Passadas

Este documento detalha cada achado apontado na auditoria sintética independente ([`revisao/relatorio.md`](docs/revisoes/revisao/relatorio.md)), registrando com precisão:
1. O achado auditado;
2. A alteração concreta implementada no código, banco de dados ou documentação;
3. A evidência comprobatória (arquivo, linhas e comando de verificação);
4. O que eventualmente não foi feito e a respectiva justificativa técnica.

---

## 1. Bloqueadores (B1 e B2)

### B1. Dicionário de colunas era código morto e auditoria não lia tabelas arbitrárias da pesquisadora
- **Diagnóstico original:** O `dicionario_colunas.csv` era lido mas ignorado em `04_auditar.R` e `05_padronizar.R`, que dependiam de colunas fixas do Darwin Core. Arquivos da pesquisadora como `minha_flora.csv` seriam ignorados.
- **O que foi feito:**
  1. Implementado em [`R/funcoes.R`](R/funcoes.R) o motor dinâmico de dicionário: funções `carregar_dicionario()`, `mapear_tabela_por_dicionario()` e `auditar_tabela_por_dicionario()`.
  2. Refatorado [`codigo/04_auditar.R`](codigo/04_auditar.R) para iterar dinamicamente sobre todas as tabelas registradas no dicionário.
  3. Refatorado [`codigo/05_padronizar.R`](codigo/05_padronizar.R) para iterar sobre `unique(dicionario$tabela_origem)` para `tabela_destino == "observacao"`, buscando os arquivos em `dados/bruto/` (mantendo tabelas de teste em `dados/exemplo/` fora do run principal de dados reais) e concatenando todas as observações mapeadas dinamicamente.
  4. Criada a tabela de exemplo [`dados/exemplo/minha_flora.csv`](dados/exemplo/minha_flora.csv) com colunas totalmente não-GBIF (`Sp_Name`, `Dt_Coleta`, `Qtde`, `Lat`, `Lon`).
  5. Criado o teste unitário [`codigo/10_teste_dicionario.R`](codigo/10_teste_dicionario.R), que valida que a tabela arbitrária é lida, auditada, mapeada e descoberta dinamicamente em modo separado.
- **Evidência:**
  - Arquivo: [`R/funcoes.R`](R/funcoes.R), [`codigo/05_padronizar.R`](codigo/05_padronizar.R), [`codigo/10_teste_dicionario.R`](codigo/10_teste_dicionario.R), [`dicionario_colunas.csv`](dicionario_colunas.csv).
  - Comando: `Rscript codigo/10_teste_dicionario.R` (retorna sucesso em todas as asserções de teste).
- **O que não foi feito:** Nada pendente. O motor está 100% ativo e testado.

---

### B2. Números de riqueza por município no `RELATORIO.md` eram fictícios
- **Diagnóstico original:** O parágrafo da Seção 5 de `RELATORIO.md` continha números digitados manualmente (Caiapônia 85/24/7, Perolândia 30/25/6, Jataí 287/149/28) que divergiam completamente das saídas dos scripts.
- **O que foi feito:**
  1. Reescrita completa da seção de riqueza biológica municipal em [`RELATORIO.md`](RELATORIO.md) a partir estritamente de [`saidas/tabela_riqueza_locais.csv`](saidas/tabela_riqueza_locais.csv) e [`saidas/metricas_analise.json`](saidas/metricas_analise.json).
  2. Detalhados os números reais pós-espacialização point-in-polygon (total canônico: 738 espécies: 535 flora, 160 aves, 43 mamíferos em 2.124 ocorrências):
     - Mineiros: 187 flora, 154 aves, 36 mamíferos (1.197 registros).
     - Jataí: 234 flora, 12 aves, 3 mamíferos (444 registros).
     - Serranópolis: 126 flora, 14 aves, 6 mamíferos (345 registros).
     - Rio Verde: 40 flora, 9 aves, 14 mamíferos (111 registros).
     - Caiapônia: 21 flora, 1 ave, 0 mamíferos (26 registros).
     - Perolândia: 0 flora, 1 ave, 0 mamíferos (1 registro).
  3. Criado o script [`codigo/11_verificar_numeros.R`](codigo/11_verificar_numeros.R), que confere linha por linha os valores do texto contra os dados exportados e interrompe com erro caso haja divergência.
- **Evidência:**
  - Arquivo: [`RELATORIO.md`](RELATORIO.md) Seção 5; [`saidas/tabela_riqueza_locais.csv`](saidas/tabela_riqueza_locais.csv).
  - Comando: `Rscript codigo/11_verificar_numeros.R` (100% dos testes aprovados).
- **O que não foi feito:** Nada pendente.

---

## 2. Maiores (M1 a M8)

### M1. Atribuição espacial ingênua e incorporação indevida de municípios vizinhos
- **Diagnóstico original:** `atribuir_local_mais_proximo()` usava distância Euclidiana em graus e forçava coordenadas faltantes para Caiapônia, além de incluir pontos de Quirinópolis, Chapadão do Céu e Costa Rica/MS.
- **O que foi feito:**
  1. Criado [`codigo/03b_atribuir_locais.py`](codigo/03b_atribuir_locais.py) com `geopandas.sjoin`, executando junção espacial estrita point-in-polygon contra as malhas GeoJSON oficiais dos 6 municípios baixadas do IBGE.
  2. Dos 3.000 registros brutos, 2.124 pontos caem comprovadamente dentro dos 6 municípios (1.263 flora, 861 fauna) e 876 pontos caem fora (237 flora, 639 fauna).
  3. Os 876 registros fora da área recebem `fora_area = TRUE` e são **excluídos do banco SQLite canônico**, eliminando distorções geográficas nas análises.
  4. Resultados salvos em [`saidas/resumo_espacializacao.csv`](saidas/resumo_espacializacao.csv) e documentados no relatório.
- **Evidência:**
  - Arquivo: [`codigo/03b_atribuir_locais.py`](codigo/03b_atribuir_locais.py), [`saidas/resumo_espacializacao.csv`](saidas/resumo_espacializacao.csv).
  - Comando: `python codigo/03b_atribuir_locais.py`.

---

### M2. "Campanha" e "esforço" eram fabricados a partir do número de registros
- **Diagnóstico original:** `esforco = as.numeric(n())` criava uma taxa artificial unitária e chamava agrupamento por ano de campanha de campo.
- **O que foi feito:**
  1. Alterado [`codigo/05_padronizar.R`](codigo/05_padronizar.R) para definir estritamente `esforco = NA_real_` e `esforco_unidade = NA_character_` para todas as fontes oportunistas (GBIF e herbários).
  2. Renomeado o conceito na documentação e no código para "unidade de agregação temporal-espacial" (`id_agregacao`), esclarecendo que agrupamentos anuais de ocorrências dispersas não constituem campanhas amostrais padronizadas.
  3. Adicionado o campo `tipo_evento = "agregacao_oportunista"` no esquema relacional SQLite.
- **Evidência:**
  - Arquivo: [`codigo/05_padronizar.R`](codigo/05_padronizar.R), [`dados/banco/campanha.csv`](dados/banco/campanha.csv).

---

### M3. Imputação silenciosa de ano/data (2020 e `-01-01`)
- **Diagnóstico original:** Registros sem ano recebiam `2020` e datas sem dia/mês recebiam `-01-01`, inventando dados temporais.
- **O que foi feito:**
  1. Implementada a função `extrair_data_e_precisao()` em [`R/funcoes.R`](R/funcoes.R).
  2. Datas incompletas mantêm `data = NA` e registram a precisão (`ano`, `mes`, `dia`, `desconhecida`) no campo `precisao_data`.
  3. O ano original é preservado em `ano_original`, isolando registros sem ano em agregação temporal indeterminada (`_INDET`). Nenhuma data ou ano arbitrário é imputado.
- **Evidência:**
  - Arquivo: [`R/funcoes.R`](R/funcoes.R) linhas 48–110, [`esquema.sql`](esquema.sql).

---

### M4. Ausência de contagem virava pseudo-abundância 1
- **Diagnóstico original:** `individuos = 1.0` gerava uma coluna somável que produzia falsa abundância.
- **O que foi feito:**
  1. Em [`R/funcoes.R`](R/funcoes.R) e [`codigo/05_padronizar.R`](codigo/05_padronizar.R), quando não há contagem numérica de espécimes, define-se `individuos = NA_real_`.
  2. Criada coluna explícita e independente `presenca = 1L` para todas as detecções confirmadas.
  3. Em [`codigo/06_juntar.R`](codigo/06_juntar.R), as métricas foram desmembradas em `n_registros`, `n_presencas` e `n_individuos_reais` (somando apenas valores reais).
- **Evidência:**
  - Arquivo: [`dados/banco/observacao.csv`](dados/banco/observacao.csv), [`saidas/tabela_analise.csv`](saidas/tabela_analise.csv).

---

### M5. Incerteza espacial alta não era propagada e critério de paisagem
- **Diagnóstico original:** Registros com incerteza > 10.000 m (até 44 km) entravam no banco e eram associados a buffers locais de 5 km.
- **O que foi feito:**
  1. Campo `coordinateUncertaintyInMeters` incorporado na coluna `incerteza_metros` da tabela `observacao`.
  2. Implementado critério conservador de validação geográfica em buffers locais de 5 km: o campo `valido_paisagem = 1L` exige que a incerteza métrica seja explicitamente conhecida E $\le 5.000$ m.
  3. Explicado formalmente que registros com incerteza ausente (`NA`) também são tratados como inválidos para análise local de paisagem (`valido_paisagem = 0L`). Como 100% da flora de herbário (1.263 registros) e 151 registros de fauna não reportam incerteza (total de 1.414 ocorrências com incerteza `NA`), somadas a 534 ocorrências de fauna com incerteza conhecida superior a 5 km, resultam em **1.948 de 2.124 ocorrências (91,7%) classificadas com `valido_paisagem = 0L`**, restando 176 registros (8,3%, todos de fauna) com validação métrica atestada $\le 5.000$ m.
  4. A proporção de registros válidos (`pct_valido_paisagem`) e com incerteza conhecida (`pct_incerteza_conhecida`) é reportada na tabela analítica em [`saidas/tabela_analise.csv`](saidas/tabela_analise.csv).
- **Evidência:**
  - Arquivo: [`dados/banco/observacao.csv`](dados/banco/observacao.csv), [`saidas/tabela_analise.csv`](saidas/tabela_analise.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json).

---

### M6. Qualificação do controle de escala (MAUP) como exercício didático
- **Diagnóstico original:** A inversão de sinal no PIB per capita entre município e buffer era apresentada como descoberta ecológica substantiva.
- **O que foi feito:**
  1. A seção de controle de escala em [`RELATORIO.md`](RELATORIO.md) e [`REVISAO-ALVO.md`](REVISAO-ALVO.md) foi formalmente requalificada como **exercício didático de sensibilidade numérica e demonstração do MAUP**.
  2. Inserido alerta de que a inversão de postos decorre da sensibilidade da métrica em $n=6$ e da proximidade do centroide geométrico a áreas urbanas.
  3. Esclarecido que o próximo passo ecológico é a medição de buffers sobre parcelas e fazendas amostradas em campo.
- **Evidência:**
  - Arquivo: [`RELATORIO.md`](RELATORIO.md) Seção 5; [`saidas/metricas_analise.json`](saidas/metricas_analise.json).

---

### M7. Correção da soma populacional dos 6 municípios
- **Diagnóstico original:** O relatório anterior grafava 428.980 habitantes (erro de 30 habitantes).
- **O que foi feito:**
  1. A soma populacional oficial dos 6 municípios (Censo IBGE 2022) foi calculada pelo script: $16.513 + 105.729 + 70.081 + 2.964 + 225.696 + 8.027 =$ **429.010 habitantes**.
  2. Atualizados [`RELATORIO.md`](RELATORIO.md), [`REVISAO-ALVO.md`](REVISAO-ALVO.md) e [`saidas/metricas_analise.json`](saidas/metricas_analise.json).
  3. Testado automaticamente em [`codigo/11_verificar_numeros.R`](codigo/11_verificar_numeros.R).
- **Evidência:**
  - Arquivo: [`saidas/metricas_analise.json`](saidas/metricas_analise.json), [`codigo/11_verificar_numeros.R`](codigo/11_verificar_numeros.R).

---

### M8. Alinhamento da documentação (README, ROTEIRO, CLAUDE, REVISAO-ALVO)
- **Diagnóstico original:** Textos prometiam funcionalidades inexistentes e usavam jargão triunfalista ("100% pronto").
- **O que foi feito:**
  1. Todos os documentos foram atualizados para descrever com precisão o que o código faz.
  2. Documentado o teste de tabela com colunas arbitrárias via [`dados/exemplo/minha_flora.csv`](dados/exemplo/minha_flora.csv).
  3. Atualizadas as instruções do encontro para focar na demonstração do teste do dicionário e no esclarecimento metodológico.
- **Evidência:**
  - Arquivos: [`README.md`](README.md), [`ROTEIRO-ENCONTRO.md`](ROTEIRO-ENCONTRO.md), [`CLAUDE.md`](CLAUDE.md), [`REVISAO-ALVO.md`](REVISAO-ALVO.md).

---

## 3. Menores (m1 a m10)

| Item | Descrição do Achado | Ação Realizada | Evidência |
| :--- | :--- | :--- | :--- |
| **m1** | Chaves e taxonomia completa de espécies | Implementadas PKs `id_especie` (`ESP_001` a `ESP_738`) e FKs em `observacao`; reconstruídas 182 famílias e 76 ordens reais a partir das colunas mapeadas do dicionário (`family`, `order`, `acceptedScientificName`, `establishmentMeans`, `iucnRedListCategory`) | [`dados/banco/especie.csv`](dados/banco/especie.csv) |
| **m2** | `perfil` não integrado | Qualificado formalmente como especificação relacional de esquema futuro para questionários | [`RELATORIO.md`](RELATORIO.md), [`saidas/esquema.md`](saidas/esquema.md) |
| **m3** | Parsing defensivo sem ocultação | Subsituição de conversões cegas por rotinas de validação de datas e coordenadas em `R/funcoes.R` | [`R/funcoes.R`](R/funcoes.R) |
| **m4** | Distância Euclidiana em graus | Substituída por point-in-polygon contra malhas GeoJSON em [`codigo/03b_atribuir_locais.py`](codigo/03b_atribuir_locais.py) | [`saidas/resumo_espacializacao.csv`](saidas/resumo_espacializacao.csv) |
| **m5** | Auditoria e ordenação de gravidade | Auditoria ordena problemas por severidade (`critico` > `importante` > `menor`) | [`codigo/04_auditar.R`](codigo/04_auditar.R), [`saidas/problemas.csv`](saidas/problemas.csv) |
| **m6** | Referência a script inexistente | Script [`codigo/verificar_dois.py`](codigo/verificar_dois.py) criado e verificado contra a API Crossref | [`codigo/verificar_dois.py`](codigo/verificar_dois.py) |
| **m7** | Mistura de anos censitários em `social` | Adicionadas notas no relatório e metadados detalhando Pop 2022, Rural 2010 e PIB 2021 | [`RELATORIO.md`](RELATORIO.md) Seção 5 |
| **m8** | Cálculo do PIB per capita | Explicitado que o indicador representa a razão do PIB 2021 pela população do Censo 2022 | [`RELATORIO.md`](RELATORIO.md) Tabela da Seção 5 |
| **m9** | Contagem de scripts do kit | Atualizada a documentação para elencar os 14 scripts integrados (00–08, 03b, 10, 10b, 11 e 99) | [`README.md`](README.md), [`CLAUDE.md`](CLAUDE.md) |
| **m10** | Classes de vegetação nativa | Detalhadas as classes 3, 4, 11, 12 e 29 como nativas; silvicultura (9) e mosaico (21) como não-nativas | [`RELATORIO.md`](RELATORIO.md), [`codigo/03_paisagem_gee.py`](codigo/03_paisagem_gee.py) |

---

## 4. O que Não Foi Feito e Por Quê

1. **Atribuição de dados reais de questionários de proprietários:** Não foi realizada inserção de dados fictícios em `dados/modelo_perfil_propriedade.csv` nem na tabela `perfil`. Conforme a regra metodológica estrita deste projeto, **nenhum dado socioambiental de campo deve ser inventado**. A tabela foi mantida como modelo vazio estruturado até que a pesquisadora colete seus questionários de campo.
2. **Reclassificação forçada de ocorrências fora dos 6 municípios:** Os 876 registros localizados fora dos polígonos municipais (ex.: em Quirinópolis e Chapadão do Céu) **não foram forçados para os municípios de estudo**. Foram mantidos com flag `fora_area = TRUE` nos dados brutos e excluídos do banco canônico para preservar a pureza espacial da amostra do PELD.

---

## 5. Verificação Automatizada Final

Para assegurar que nenhuma discrepância subsista, os dois seguintes testes foram executados com sucesso:

1. **Teste Unitário do Dicionário:**
   ```powershell
   Rscript codigo/10_teste_dicionario.R
   ```
   *Resultado:* 6 de 6 asserções aprovadas com sucesso, confirmando leitura, mapeamento de colunas não-GBIF e coerência de tipos.

2. **Verificação Numérica dos Relatórios:**
   ```powershell
   Rscript codigo/11_verificar_numeros.R
   ```
   *Resultado:* 32 de 32 asserções numéricas aprovadas com sucesso, comprovando correspondência exata entre o texto de `RELATORIO.md`, `REVISAO-ALVO.md`, `ROTEIRO-ENCONTRO.md` e as saídas oficiais em `saidas/` e `dados/banco/`.

---

## 6. Correções adicionais da rodada local (04/11, após a revisão)

1. **Fluxo completo com uma tabela da pesquisadora (03b + 05 + 06):** o `03b_atribuir_locais.py` foi generalizado para ler **todas** as `tabela_origem` de `observacao` no dicionário, descobrir as colunas de `lat`/`lon` de cada uma e gravar `id_local`/`fora_area`/`sem_coordenada` em cada CSV de `dados/bruto/`. O `05_padronizar.R` já iterava sobre o dicionário; o mapeador passou a usar a coluna `id_local` gravada no próprio CSV quando não há linha `id_local` no dicionário. Criado `codigo/10b_teste_fluxo_completo.R`, que copia `dados/exemplo/minha_flora.csv` para uma pasta temporária, roda `03b` + `05` + `06` e confirma as 6 linhas no banco (6 dentro dos 6 polígonos, 2.130 registros canônicos e 744 espécies no teste). O `99_rodar_tudo.R` passou a executar esse teste.
2. **Amostra, não universo:** o `01_baixar_gbif.R` passou a consultar e registrar o universo (`10.109` flora, `52.016` fauna: `47.849` aves + `4.167` mamíferos) em `dados/bruto/fontes.json`; `RELATORIO.md`, `README.md` e `REVISAO-ALVO.md` passaram a dizer **amostra de 1.500 por grupo**, não aleatória e não representativa do universo.
3. **Portabilidade:** `00_instalar.R` e `R/funcoes.R` usam `R_LIBS_USER` (sem `<usuário>`); `03_paisagem_gee.py` usa `GEE_PROJECT` (padrão desta máquina, configurável); `README.md` e `CLAUDE.md` explicam o que mudar em outra máquina.
4. **Consistência textual:** `ROTEIRO-ENCONTRO.md` e `REVISAO-ALVO.md` passaram de 6.872/9 para **8.613/12** (contagem atual do `resumo_auditoria.csv`); `RELATORIO.md` trocou “100% das métricas” por “números-chave listados” e a linha de PIB per capita foi rotulada como **média simples** (com a nota do total ponderado ≈ R$ 69.406); o `README.md` passou a indicar **2 a 3 minutos** de pipeline e o novo teste `10b`.
5. **Verificação final:** `Rscript codigo/99_rodar_tudo.R` rodou do zero em **2,52 min** e terminou com sucesso; `10_teste_dicionario.R` e `10b_teste_fluxo_completo.R` passaram; `11_verificar_numeros.R` passou nas **32 asserções** (incluindo 8.613/12 no `ROTEIRO` e na `REVISAO`).
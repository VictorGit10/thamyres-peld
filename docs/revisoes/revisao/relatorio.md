# Síntese da revisão de 3 passadas — kit PELD / Thamyres

**Alvo:** `REVISAO-ALVO.md` e os artefatos citados (`RELATORIO.md`, `README.md`, `codigo/04_auditar.R`, `codigo/05_padronizar.R`).
**Passadas:** R1 (Gemini 3.8 Flash High/Medium, retomada), R2 e R3 (Gemini 3.8 Flash Medium, contextos novos). As três leram o mesmo alvo e os mesmos arquivos; R2 e R3 foram feitas em paralelo.
**Regra:** não criar achado novo; esta síntese só deduplica, prioriza e preserva divergências.

---

## Bloqueadores — mudam a decisão de levar o kit para o encontro

### B1. O dicionário de colunas é código morto; a auditoria não audita as tabelas da pesquisadora
- **Origem:** R1-1, R2-1, R2-2, R3-1, R3-2.
- **Âncora:** `codigo/05_padronizar.R:14` (lê o CSV e nunca usa), `05:84-149` (nomes Darwin Core fixos), `codigo/04_auditar.R:13-37` (só checa a estrutura do dicionário), `README.md` Passos 1–4.
- **Risco:** o README promete que ela coloca `minha_flora.csv`, preenche o dicionário e roda `04`/`05`. Na prática, os scripts leem apenas `gbif_flora.csv`/`gbif_fauna.csv`; os arquivos dela são ignorados. O kit não cumpre a promessa central e pode rodar “sem erro” produzindo saídas que não são dela.
- **Recomendação:** implementar em `R/funcoes.R` um mapeador que leia `dicionario_colunas.csv`, carregue cada `tabela_origem`, renomeie `campo_origem` → `campo_destino`, aplique a `transformacao` e devolva o esquema canônico. Usar esse mapeador em `04` e `05`. Criar `codigo/10_teste_dicionario.R` com uma tabela fictícia de colunas não-GBIF (`Sp_Name`, `Dt_Coleta`, `Qtde`, `Lat`, `Lon`) e um bloco no dicionário; o teste falha se a tabela não for lida e convertida. Só depois atualizar README/ROTEIRO/CLAUDE.

### B2. Os números de riqueza por município do `RELATORIO.md` são fictícios
- **Origem:** R1-2 (R2/R3 não repetem o detalhe, mas confirmam que os números não são reproduzíveis).
- **Âncora:** `RELATORIO.md` Seção 5, L83–L88; `saidas/tabela_riqueza_locais.csv`; `figuras/02_riqueza_locais.png`.
- **Risco:** o texto diz Caiapônia 85/24/7 (total 116), Perolândia 30/25/6 (61), Jataí 287/149/28 (464), Serranópolis 137/33/15 (185); a tabela real tem Caiapônia 20/0/0 (20), Perolândia 1/6/0 (7), Jataí 215/16/4 (235), Serranópolis 330/158/37 (525). O texto e a figura se contradizem; qualquer leitor confere em 10 segundos.
- **Recomendação:** reescrever o parágrafo **a partir de `saidas/tabela_riqueza_locais.csv`**, sem digitação manual. Dizer que é riqueza acumulada 2010–2026, que espécies podem ocorrer em mais de um local (não somar para obter o total de 900) e que a comparação entre locais é limitada pelo esforço (ver M6). Gerar o trecho por script ou adicionar uma checagem que compare o texto ao CSV.

---

## Maiores — precisam ser corrigidos antes do encontro

### M1. Atribuição espacial ingênua: NA vira Caiapônia e municípios vizinhos são forçados para dentro dos 6 polos
- **Origem:** R1-5, R2-3, R2-10, R3-3, R3-4.
- **Âncora:** `05_padronizar.R:69-76` (`atribuir_local_mais_proximo`), `04_auditar.R:77-93`.
- **Risco:** `if (is.na(lat/lon)) return(banco_local$id_local[1])` atribui qualquer registro sem coordenada a Caiapônia. A distância Euclidiana em graus ignora a projeção. Registros de Quirinópolis, Chapadão do Céu, Costa Rica/MS e outros são forçados para um dos 6 polos; a auditoria chama isso de “grafia divergente”, quando são municípios distintos. Os “0 sem local” do `06` são artefato dessa atribuição forçada, não prova de cobertura.
- **Recomendação:** fazer junção espacial por polígono (point-in-polygon) com os GeoJSONs já baixados. Pode ser um `codigo/03b_atribuir_locais.py` com `geopandas` (`sjoin`), rodando antes do `05`; ou `sf` no R. Registros fora dos 6 polígonos e sem coordenada ficam `id_local = NA` / `fora_area = TRUE`, são **excluídos do banco canônico** e contados no relatório. Não usar “0 órfãos” como prova de cobertura; relatar “N dentro, N fora, N sem coordenada”.

### M2. “Campanha” e “esforço” são fabricados a partir do número de registros
- **Origem:** R1-3, R2-6, R3-5.
- **Âncora:** `05_padronizar.R:157-168` (`esforco = as.numeric(n())`, `esforco_unidade = "registros_amostrais"`).
- **Risco:** o número de ocorrências é a resposta, não o esforço. A taxa por unidade de esforço fica artificialmente 1 em todas as campanhas; o relatório condena a ausência de esforço e, ao mesmo tempo, inventa um. A “campanha” local × ano × grupo não é uma campanha de campo.
- **Recomendação:** `esforco = NA_real_`, `esforco_unidade = NA_character_` para fontes oportunistas. Renomear o conceito para “unidade de agregação local × ano × grupo” (ou `id_agregacao`) e explicar no relatório/README. Só preencher esforço quando a planilha primária trouxer horas-rede, km, armadilhas-noite etc.

### M3. Imputação silenciosa de ano/data (2020 e `-01-01`)
- **Origem:** R1-7, R2-4, R3-6.
- **Âncora:** `05_padronizar.R:90-91, 103, 123-124, 137`.
- **Risco:** registros sem ano ou fora de 2010–2026 viram 2020; datas parciais viram `2020-01-01`; isso cria campanhas fictícias em 2020. O `04` também chama 48 datas só-ano de “formato inválido”, quando são imprecisas.
- **Recomendação:** manter `ano = NA` e `data = NA` quando a precisão não permite; adicionar `precisao_data` (`dia`, `mes`, `ano`, `desconhecida`) e `ano_original`. Isolar registros sem data em agregação `_INDET`. No `04`, separar `data_imprecisa` (ano/mês) de `data_invalida`; contar e explicar.

### M4. Ausência de contagem vira pseudo-abundância `1`
- **Origem:** R2-5.
- **Âncora:** `05_padronizar.R:97-98, 131-132`; `06_juntar.R` `soma_individuos`.
- **Risco:** `individuos = 1.0` para todo registro sem contagem e `unidade = "presenca"`; funções que somam `individuos` produzem uma falsa abundância. O relatório diz que não se deve comparar abundância, mas a tabela entrega uma coluna somável.
- **Recomendação:** `individuos = NA_real_` quando não há contagem; criar `detectado = 1L`/`presenca = TRUE`; em `06`, separar `n_registros`, `n_presenca`, `n_individuos_reais` e nunca chamar a soma de presenças de abundância.

### M5. Incerteza espacial alta é auditada, mas não propagada
- **Origem:** R3-4.
- **Âncora:** `04_auditar.R:112-124`; `05_padronizar.R:117-149`.
- **Risco:** 639 registros de fauna com incerteza > 10 km (até 44 km) entram no banco e são associados a buffers de 5 km. A auditoria aponta o problema e a padronização o ignora.
- **Recomendação:** carregar `coordinateUncertaintyInMeters` em `observacao`; criar `valido_paisagem` (TRUE se incerteza ≤ raio do buffer, FALSE/NA caso contrário); excluir ou rodarsensibilidade. Relatar quantos ficam de fora.

### M6. Buffers em centróides municipais + n=6: o “controle MAUP” não sustenta conclusão ecológica
- **Origem:** R1-6, R2-7, R2-8, R3-8.
- **Âncora:** `RELATORIO.md:105-121`; `REVISAO-ALVO.md:61-64`.
- **Risco:** buffers de 5/10 km ao redor do centróide geométrico (muitas vezes urbano) são correlacionados com PIB municipal; a “inversão de sinal” pode ser instabilidade de 6 postos, e o próprio controle negativo mostra envelope nulo `[-0,7714; +0,7714]`, `p = 0,3030`. Apresentar isso como evidência de MAUP ecológico é sobreinterpretação.
- **Recomendação:** qualificar como **exercício didático de sensibilidade numérica**, não como resultado ecológico. Dizer que o próximo passo é calcular buffers ao redor das parcelas/propriedades reais e usar n suficiente. Não usar a inversão como “descoberta”.

### M7. Soma populacional errada em 30 habitantes
- **Origem:** R1-4.
- **Âncora:** `REVISAO-ALVO.md:41-45` (428.980).
- **Risco:** a soma dos seis valores é **429.010**; o número manual está errado.
- **Recomendação:** usar `sum(social$populacao)` e atualizar o alvo/relatório. Se o relatório não cita o total, citar o valor correto ou remover.

### M8. README/ROTEIRO/CLAUDE prometem um comportamento que o código não tem
- **Origem:** R1-1, R1-8, R2-2, R3-2.
- **Âncora:** `README.md` Passos 1–4; `ROTEIRO-ENCONTRO.md` Bloco 2; `CLAUDE.md` §3 item 5.
- **Risco:** “o dicionário faz a tradução”, “o R lê o dicionário”, “o kit está 100% pronto” são falsos no estado atual. Depois da refatoração (B1), atualizar as frases para o que o código realmente faz; temperar “100% pronto” para “teste executado; para as suas planilhas, preencha o dicionário e rode o teste”.
- **Recomendação:** atualizar os três arquivos junto com a refatoração; adicionar o exemplo `minha_flora.csv` e o comando do teste.

---

## Menores — úteis, mas não bloqueiam o encontro

- **m1. Deduplicação de espécie por nome científico apenas** (R3-7): usar `id_especie` (ex.: `taxonKey` ou `grupo + nome`) como PK; evitar colisão de homônimos entre flora e fauna.
- **m2. `perfil` é um stub não integrado** (R2-9, R3-10): ou implementar um `pivot_wider` + join condicional no `06`/`07`, ou renomear no relatório como “especificação de esquema futuro”. Não chamar de “solução” sem código.
- **m3. `suppressWarnings` esconde parsing** (R3-9): contar e registrar conversões que viram `NA`; aceitar vírgula decimal e DMS.
- **m4. Distância Euclidiana em graus** (R2-10): resolvida pela junção poligonal (M1); se mantiver distância, usar Haversine.
- **m5. Auditoria: “24 grafias” e ordenação de gravidade** (R1): o número real de grafias únicas é 23; usar contagem do script e ordenar `critico > importante > menor`.
- **m6. `REFERENCIAS.md` cita `codigo/verificar_dois.py`**, que não existe; mover/renomear o script de verificação para `codigo/` ou corrigir a citação.
- **m7. `social.csv` mistura anos** (população 2022, rural 2010, PIB 2021) e `ano = 2021`; adicionar `ano_pop`, `ano_rural`, `ano_pib` ou uma coluna `nota`; rótulo “agro no PIB” é, na verdade, valor adicionado da agropecuária / PIB.
- **m8. `pib_per_capita` mistura PIB 2021 com população 2022**: dizer isso na tabela/nota.
- **m9. “9 scripts”** no relatório: são 10 (00–08 + 99); corrigir.
- **m10. Classes de vegetação nativa**: listar 3, 4, 11, 12, 29 e dizer que silvicultura (9), mosaico (21) etc. ficam em “outras”.

---

## Respostas às questões da revisão

1. **Os números são reproduzíveis?** Parcialmente: os totais globais, o SQLite e as correlações saem dos scripts; a tabela de riqueza municipal narrada no relatório não sai de nenhum script e está errada; a soma populacional erra por 30.
2. **O método sustenta as conclusões?** As conclusões cautelosas (n=6, falácia ecológica, sem causalidade) estão corretas; a narrativa de “inversão de sinal” e o “controle MAUP” excedem o que os centróides permitem. A atribuição espacial forçada e o esforço circular precisam ser corrigidos.
3. **O kit entrega o prometido?** Ainda não: o dicionário é inerte e a auditoria não lê as tabelas da pesquisadora. O banco, as figuras e os controles funcionam.
4. **Serve para as tabelas dela?** No estado atual, não de imediato; depois de B1 + M1 + M2 + M3, sim.
5. **As limitações estão explícitas?** As conceituais sim; faltam as operacionais (buffers em centróides; necessidade de refatorar a ingestão; amostra de 1.500 por grupo, não o universo).

---

## Ordem de correção sugerida

1. B1 (mapeador + teste com tabela fictícia) e B2 (riqueza a partir do CSV).
2. M1 (point-in-polygon; excluir fora; contar), M2 (esforço NA), M3 (data/ano), M4 (pseudo-abundância), M5 (incerteza).
3. M6/M7/M8 (textos e números), m1–m10.
4. Rerodar `99_rodar_tudo.R`, atualizar `RELATORIO.md`, `README.md`, `ROTEIRO-ENCONTRO.md`, `CLAUDE.md`, `REVISAO-ALVO.md`, `REFERENCIAS.md`.
5. Criar `codigo/11_verificar_numeros.R` que confere os números-chave do relatório contra `saidas/*.csv`/`metricas_analise.json` e falha se divergirem.

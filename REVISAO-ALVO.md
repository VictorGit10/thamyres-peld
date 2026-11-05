# REVISAO-ALVO.md — Afirmações Centrais e Alvo da Revisão de Três Passadas

Este documento elenca as **12 afirmações quantitativas e conceituais centrais** do [`RELATORIO.md`](RELATORIO.md), apontando os scripts exatos e arquivos de dados dos quais cada número foi gerado, além das **limitações epistemológicas e metodológicas obrigatórias**. 

Este arquivo servirá como alvo estrito para as três passadas independentes de auditoria por IA (Confiabilidade dos Dados, Robustez Estatística/Ecológica e Comunicação/Acionabilidade).

---

## 1. As 12 Afirmações e Números Centrais

### Afirmação 1: Volume de Dados Brutos de Biodiversidade e Espacialização Poligonal
- **Enunciado:** O kit baixou uma **amostra de conveniência de 3.000 registros brutos** de ocorrência biológica no sudoeste goiano (caixa lat -19,0 a -17,0; lon -53,0 a -50,5; anos 2010–2026), divididos igualmente em 1.500 espécimes preservados de flora e 1.500 ocorrências de fauna (900 aves e 600 mamíferos). Essa amostra não é aleatória e não representa o universo disponível no GBIF. A junção espacial point-in-polygon contra as malhas oficiais do IBGE classificou **2.124 registros canônicos dentro dos 6 municípios** (1.263 flora e 861 fauna) e identificou **876 registros fora dos 6 polos** (237 flora e 639 fauna), que foram excluídos do banco canônico.
- **Script gerador:** [`codigo/01_baixar_gbif.R`](codigo/01_baixar_gbif.R) e [`codigo/03b_atribuir_locais.py`](codigo/03b_atribuir_locais.py)
- **Arquivo de saída:** [`saidas/resumo_espacializacao.csv`](saidas/resumo_espacializacao.csv), [`saidas/resumo_espacializacao.json`](saidas/resumo_espacializacao.json)

### Afirmação 2: Riqueza Taxonômica Padronizada Catalogada no Banco Canônico
- **Enunciado:** A consolidação taxonômica dos 2.124 registros canônicos resultou em **738 espécies distintas** catalogadas no banco relacional (`peld.sqlite`) com identificadores estáveis `ESP_001` a `ESP_738`, estruturadas em **182 famílias** e **76 ordens**, sendo **535 espécies de flora**, **160 espécies de aves** e **43 espécies de mamíferos**.
- **Script gerador:** [`codigo/05_padronizar.R`](codigo/05_padronizar.R) e [`codigo/07_analisar.R`](codigo/07_analisar.R)
- **Arquivo de saída:** [`dados/banco/especie.csv`](dados/banco/especie.csv), [`saidas/tabela_riqueza_locais.csv`](saidas/tabela_riqueza_locais.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 3: Diagnóstico de Qualidade e Total de Inconsistências Detectadas
- **Enunciado:** A auditoria automatizada por dicionário identificou **8.613 ocorrências de inconsistências** nos dados brutos, distribuídas em **12 tipos estruturais** catalogados entre as tabelas (incluindo as 876 ocorrências fora dos 6 polígonos e a tabela de exemplo `minha_flora`).
- **Script gerador:** [`codigo/04_auditar.R`](codigo/04_auditar.R)
- **Arquivo de saída:** [`saidas/problemas.csv`](saidas/problemas.csv), [`saidas/resumo_auditoria.csv`](saidas/resumo_auditoria.csv), [`saidas/diagnostico.md`](saidas/diagnostico.md)

### Afirmação 4: Ausência Estrutural de Esforço Amostral e Contagem
- **Enunciado:** 1.288 registros de flora (85,9%) e 1.105 registros de fauna (73,7%) não possuem contagem numérica de indivíduos (`individualCount` nulo), sendo tratados como `individuos = NA` com `presenca = 1L`. Além disso, 1.500 registros de flora (100%) carecem de medida de esforço amostral (`sampleSizeValue`), sendo mantidos como `esforco = NA` e categorizados como unidades de agregação temporal/espacial.
- **Script gerador:** [`codigo/04_auditar.R`](codigo/04_auditar.R) e [`codigo/05_padronizar.R`](codigo/05_padronizar.R)
- **Arquivo de saída:** [`saidas/resumo_auditoria.csv`](saidas/resumo_auditoria.csv), [`dados/banco/observacao.csv`](dados/banco/observacao.csv)

### Afirmação 5: Divergências Taxonômicas e Sinonímias Ativas
- **Enunciado:** 79 registros de flora (5,3%) e 77 registros de fauna (5,1%) possuem discrepância entre o nome científico fornecido na coleta (`scientificName`) e o nome aceito atualmente (`acceptedScientificName`), tendo sido harmonizados no dicionário biológico.
- **Script gerador:** [`codigo/04_auditar.R`](codigo/04_auditar.R)
- **Arquivo de saída:** [`saidas/resumo_auditoria.csv`](saidas/resumo_auditoria.csv)

### Afirmação 6: Incerteza Espacial, Município Ausente e Critério de Paisagem
- **Enunciado:** 1.499 de 1.500 registros de fauna (99,9%) possuem campo textual de município nulo, tornando mandatório o vínculo por sobreposição geográfica estrita (point-in-polygon). Para análises de uso da terra em buffers locais de 5 km, o filtro de qualidade exige incerteza reportada E $\le 5.000$ m: 1.414 ocorrências com incerteza ausente (`NA`, incluindo 100% da flora) e 534 de fauna com incerteza $> 5$ km recebem `valido_paisagem = 0L` (1.948 de 2.124, ou 91,7%), restando 176 registros de fauna (8,3%) com incerteza atestada $\le 5.000$ m.
- **Script gerador:** [`codigo/03b_atribuir_locais.py`](codigo/03b_atribuir_locais.py), [`codigo/04_auditar.R`](codigo/04_auditar.R) e [`codigo/05_padronizar.R`](codigo/05_padronizar.R)
- **Arquivo de saída:** [`saidas/resumo_auditoria.csv`](saidas/resumo_auditoria.csv), [`dados/banco/observacao.csv`](dados/banco/observacao.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 7: Perfil Populacional Oficial (Censo 2022)
- **Enunciado:** A população residente oficial do Censo 2022 para os seis municípios soma exatamente **429.010 habitantes**: Rio Verde (225.696), Jataí (105.729), Mineiros (70.081), Caiapônia (16.513), Serranópolis (8.027) e Perolândia (2.964).
- **Script gerador:** [`codigo/02_baixar_ibge.R`](codigo/02_baixar_ibge.R) e [`codigo/07_analisar.R`](codigo/07_analisar.R)
- **Arquivo de saída:** [`dados/bruto/social_municipios.csv`](dados/bruto/social_municipios.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 8: Taxa de População Rural e Estrutura Demográfica (Censo 2010)
- **Enunciado:** A proporção de população rural diverge fortemente na região: os polos agroindustriais possuem menos de 8% de residentes rurais (Rio Verde com 7,30% e Jataí com 7,95%), enquanto municípios periféricos atingem 26,03% (Serranópolis), 26,78% (Caiapônia) e 36,98% (Perolândia).
- **Script gerador:** [`codigo/02_baixar_ibge.R`](codigo/02_baixar_ibge.R)
- **Arquivo de saída:** [`dados/bruto/social_municipios.csv`](dados/bruto/social_municipios.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 9: Participação da Agropecuária no PIB Municipal (2021)
- **Enunciado:** Embora Rio Verde gere o maior PIB absoluto (R$ 16,3 bilhões), a agropecuária representa apenas 22,66% do seu valor adicionado bruto, enquanto em municípios de menor porte econômico a agropecuária domina a economia: Caiapônia (52,69%), Serranópolis (50,89%) e Perolândia (44,64%).
- **Script gerador:** [`codigo/02_baixar_ibge.R`](codigo/02_baixar_ibge.R)
- **Arquivo de saída:** [`dados/bruto/social_municipios.csv`](dados/bruto/social_municipios.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 10: Cobertura de Vegetação Nativa em 2024 (MapBiomas Coleção 11)
- **Enunciado:** Em 2024, a proporção municipal de vegetação nativa (classes 3, 4, 11, 12, 29) calculada no Earth Engine é de 43,28% em Mineiros, 38,88% em Caiapônia, 33,70% em Serranópolis, 20,17% em Jataí, 18,72% em Perolândia e 18,55% em Rio Verde.
- **Script gerador:** [`codigo/03_paisagem_gee.py`](codigo/03_paisagem_gee.py)
- **Arquivo de saída:** [`dados/bruto/paisagem.csv`](dados/bruto/paisagem.csv), [`saidas/metricas_analise.json`](saidas/metricas_analise.json)

### Afirmação 11: Sensibilidade de Escala e Inversão de Sinal (Exercício Didático de MAUP)
- **Enunciado:** A correlação não-paramétrica de Spearman entre vegetação nativa e indicadores socioeconômicos muda conforme a escala analisada: para nativa vs agro % PIB, varia de $\rho = 0,5429$ (município) para $\rho = 0,6571$ (buffer 5 km) e $\rho = 0,8857$ (buffer 10 km); para nativa vs PIB per capita, varia de $\rho = -0,6000$ (município) para $\rho = +0,4286$ (buffer 5 km e 10 km). Essa variação decorre da sensibilidade matemática de postos em $n=6$ e da posição do centroide, servindo de exercício didático e alerta contra a escolha de escalas arbitrárias.
- **Script gerador:** [`codigo/07_analisar.R`](codigo/07_analisar.R)
- **Arquivo de saída:** [`saidas/tabela_controle_escala.csv`](saidas/tabela_controle_escala.csv), [`figuras/03_escala_paisagem_social.png`](figuras/03_escala_paisagem_social.png)

### Afirmação 12: Controle Negativo e Ausência de Evidência Confirmatória
- **Enunciado:** O teste de permutação com 1.000 iterações aleatórias gerou um intervalo nulo bicaudal de 95% entre [-0,7714, 0,7714]; o coeficiente observado de 0,5429 situa-se dentro da distribuição esperada pelo acaso ($p$-valor empírico = 0,303), comprovando que a correlação não é estatisticamente distinguível de variação estocástica em amostras pequenas ($n=6$).
- **Script gerador:** [`codigo/07_analisar.R`](codigo/07_analisar.R)
- **Arquivo de saída:** [`saidas/distribuicao_nula_controle_negativo.csv`](saidas/distribuicao_nula_controle_negativo.csv), [`figuras/04_controle_negativo.png`](figuras/04_controle_negativo.png)

---

## 2. Limitações Metodológicas Obrigatórias

As passadas de revisão devem atestar que o relatório e a documentação NÃO omitem as quatro seguintes limitações essenciais:

1. **Risco Crítico de Falácia Ecológica (Piantadosi et al., 1988):** Correlações estimadas com dados municipais agregados (como % de PIB agropecuário ou % de moradores rurais) não revelam nem representam o perfil, as atitudes ou a tomada de decisão dos proprietários rurais individuais. Para modelar o perfil socioambiental de proprietários, é obrigatório utilizar entrevistas locais estruturadas com questionários padronizados (previstos em [`dados/modelo_perfil_propriedade.csv`](dados/modelo_perfil_propriedade.csv)).
2. **Poder Amostral Reduzido ($n=6$):** O conjunto de municípios analisado possui finalidade estritamente didática e metodológica de demonstração do pipeline. Ajustes de modelos estatísticos lineares ($R^2 = 0.1505$, $p = 0.4473$) em $n=6$ possuem incerteza massiva e não autorizam inferências causais.
3. **Ausência de Esforço Amostral Padronizado nos Dados Públicos:** Os registros biológicos provenientes de coleções de herbários e plataformas de ciência cidadã são oportunistas e não informam horas de esforço ou curvas de acumulação. Por essa razão, análises comparativas quantitativas devem se restringir à **riqueza observada** e **detecção/presença**, abstendo-se de comparar abundâncias absolutas.
4. **Natureza Híbrida do Kit (Real vs Stand-in vs Vazio):** Todos os números do relatório decorrem de medições públicas reais, mas funcionam como *stand-in* do ecossistema do sudoeste goiano enquanto as planilhas primárias de campo da pesquisadora não são ingeridas via dicionário de mapeamento.

---

## 2. Limitações Metodológicas Obrigatórias

As passadas de revisão devem atestar que o relatório e a documentação NÃO omitem as quatro seguintes limitações essenciais:

1. **Risco Crítico de Falácia Ecológica (Piantadosi et al., 1988):** Correlações estimadas com dados municipais agregados (como % de PIB agropecuário ou % de moradores rurais) não revelam nem representam o perfil, as atitudes ou a tomada de decisão dos proprietários rurais individuais. Para modelar o perfil socioambiental de proprietários, é obrigatório utilizar entrevistas locais estruturadas com questionários padronizados (previstos em [`dados/modelo_perfil_propriedade.csv`](dados/modelo_perfil_propriedade.csv)).
2. **Poder Amostral Reduzido ($n=6$):** O conjunto de municípios analisado possui finalidade estritamente didática e metodológica de demonstração do pipeline. Ajustes de modelos estatísticos lineares ($R^2 = 0.1505$, $p = 0.4473$) em $n=6$ possuem incerteza massiva e não autorizam inferências causais.
3. **Ausência de Esforço Amostral Padronizado nos Dados Públicos:** Os registros biológicos provenientes de coleções de herbários e plataformas de ciência cidadã são oportunistas e não informam horas de esforço ou curvas de acumulação. Por essa razão, análises comparativas quantitativas devem se restringir à **riqueza observada** e **detecção/presença**, abstendo-se de comparar abundâncias absolutas.
4. **Natureza Híbrida do Kit (Real vs Stand-in vs Vazio):** Todos os números do relatório decorrem de medições públicas reais, mas funcionam como *stand-in* do ecossistema do sudoeste goiano enquanto as planilhas primárias de campo da pesquisadora não são ingeridas via dicionário de mapeamento.

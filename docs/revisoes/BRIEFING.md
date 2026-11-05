# Briefing: página do encontro com a Thamyres

## Quem lê e em que situação
A Thamyres trabalha com biodiversidade e conservação no PELD de Goiás. Tem várias tabelas de fauna e flora, usa R e quer organizá-las para extrair informação. Também pretende cruzar a biodiversidade com a paisagem e o perfil socioambiental das pessoas. Vai ler a página na tela, durante um encontro individual de 40 minutos, e depois em casa.

**O papel do encontro não é decidir a metodologia do trabalho dela.** É mostrar um teste executado a partir do que ela escreveu: um kit que ela pode aplicar às planilhas dela, com os limites explícitos.

Voz: Victor, em nome do trabalho ("nós", "testamos"); com quem se fala é a Thamyres ("você"). Tom sóbrio, direto, curto. Nada de "mágico", "revolucionário"; nada de "a IA é perigosa".

## Fatos e números (todos do pacote `encontros-nov/thamyres`)

### O que foi baixado
- **GBIF:** 1.500 registros de flora (`taxonKey=6`, `PRESERVED_SPECIMEN`) e 1.500 de fauna (900 Aves + 600 Mammalia), bbox lat −19,0 a −17,0 e lon −53,0 a −50,5, 2010–2026. É uma **amostra de conveniência** das primeiras páginas; o universo da consulta é 10.109 de flora e 52.016 de fauna (47.849 aves + 4.167 mamíferos). Não é aleatória e não representa o universo (`dados/bruto/fontes.json`).
- **IBGE:** malhas e centroides dos 6 municípios (Caiapônia, Jataí, Mineiros, Perolândia, Rio Verde, Serranópolis); Censo 2022 (população), Censo 2010 (rural) e PIB 2021. População total: 429.010.
- **MapBiomas Coleção 11 no GEE:** vegetação nativa (classes 3, 4, 11, 12, 29), pastagem, agricultura, urbano e água; 2015, 2020 e 2024; município inteiro, buffer de 5 km e 10 km no centróide.

### O que foi executado
- `03b_atribuir_locais.py`: point-in-polygon com as malhas do IBGE; **2.124 dentro** dos 6 municípios (1.263 flora + 861 fauna) e **876 fora** (237 flora + 639 fauna); 0 sem coordenada. Os 876 fora ficam no arquivo bruto com `fora_area = TRUE` e não entram no banco canônico.
- `04_auditar.R`: **8.613 ocorrências em 12 tipos**. Principais: 3.000 sem esforço amostral (1.500 flora + 1.500 fauna), 2.395 sem contagem de indivíduos, 1.499 fauna sem município textual, 876 fora dos polígonos, 639 com incerteza > 10 km, 156 sinonímias, 48 datas só de ano.
- `05_padronizar.R`: **2.124 observações**, **738 espécies**, **182 famílias**, **76 ordens**, 0 órfãos. `id_especie` é PK; `observacao` tem FK. `esforco = NA`; `individuos = NA` quando não há contagem, com `presenca = 1`; `precisao_data` (`dia`/`ano`) e `ano_original`; `incerteza_metros` e `valido_paisagem` (1 apenas se a incerteza é conhecida e ≤ 5.000 m; 176 registros, 8,3%; 1.948 inválidos, 91,7%).
- `06_juntar.R`: **46 linhas × 45 colunas** na tabela de análise; 0 sem local, 0 sem paisagem, 0 sem social.
- `10_teste_dicionario.R`: 6 asserções; `10b_teste_fluxo_completo.R`: coloca `minha_flora.csv` em uma pasta temporária, roda `03b+05+06` e confirma as **6 linhas** no banco.
- `11_verificar_numeros.R`: **32 asserções**; `99_rodar_tudo.R`: **2,52 min**, 13 etapas.

### Riqueza por município/grupo (observada; não somar)
- Jataí: 234 flora (417 reg.), 12 aves (22), 3 mamíferos (5).
- Mineiros: 187 flora (426), 154 aves (429), 36 mamíferos (342).
- Serranópolis: 126 flora (322), 14 aves (16), 6 mamíferos (7).
- Rio Verde: 40 flora (73), 9 aves (11), 14 mamíferos (27).
- Caiapônia: 21 flora (25), 1 ave (1).
- Perolândia: 1 ave (1).
- Global: 738 espécies (535 flora, 160 aves, 43 mamíferos). As espécies podem ocorrer em mais de um município; não somar as linhas para obter 738.

### Controle de escala (didático)
- Spearman nativa × agro no PIB: 0,5429 (município), 0,6571 (buffer 5 km), 0,8857 (buffer 10 km).
- nativa × pop. rural: 0,2571 / 0,3714 / 0,7143.
- nativa × PIB per capita: −0,6000 / +0,4286 / +0,4286.
- Buffers no centróide municipal, n=6; não é resultado ecológico. O próximo passo é medir nas parcelas/propriedades.

### Controle negativo
- 1.000 permutações; ρ observado 0,5429; IC 95% nulo [−0,7714; +0,7714]; p = 0,303. Não há evidência de relação.

### O que é real, stand-in e vazio
- **Real:** GBIF, IBGE/SIDRA, MapBiomas/GEE, as malhas e o SQLite.
- **Stand-in:** os 6 municípios e as espécies públicas no lugar das planilhas primárias dela.
- **Vazio:** `dados/modelo_perfil_propriedade.csv` e a tabela `perfil` (0 registros); é a especificação para os questionários de campo.

## O que a página NÃO pode afirmar
- Que a amostra representa o PELD ou o universo do GBIF.
- Que a riqueza por município é uma medida de diversidade corrigida pelo esforço.
- Que a correlação de escala é um resultado ecológico; é um exercício com n=6 e centróides.
- Que os dados municipais medem "perfil de pessoas"; não medem.
- Que a IA "decidiu" a metodologia; ela executou o mecânico.
- Que o mapa/figuras são a tela final da tese dela; são um teste com dados públicos.

## Entrega
`TEXTO.md` (5 seções), `FORMULARIO.md`, `figuras.py` (7 PNGs reais), `montar.py`/`pagina.html` (offline, imagens embutidas), `BRIEFING.md`.

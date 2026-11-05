## O pedido: várias tabelas, fauna, flora e a paisagem ao redor

Esta é a resposta que você enviou ao formulário.

O pedido tinha duas partes: organizar as tabelas de fauna e flora do PELD para conseguir extrair informação, e preparar o encontro com a paisagem e o perfil socioambiental. Você já usava R. O teste partiu daí: um kit em R que **não exige renomear as suas planilhas** e um exemplo executado com dados públicos do sudoeste goiano.

## A IA montou uma ponte: o dicionário lê as colunas que você já tem

Um agente de IA (Gemini 3.8 Flash) executou o kit; nós escrevemos o pedido, definimos os controles e conferimos cada número. A peça central é o **dicionário de colunas**: uma tabela simples em que você diz que, na sua planilha, a espécie se chama `Sp_Name`, a data `Dt_Coleta`, a contagem `Qtde` e as coordenadas `Lat`/`Lon`. O kit lê isso e monta o banco sem tocar nos cabeçalhos.

As seis linhas de `minha_flora.csv` viram seis linhas de `observacao`: espécie, data, precisão, contagem ou presença e município. O município não é digitado: o **point-in-polygon** contra as malhas do IBGE encontra **2.124 pontos dentro dos seis municípios** e **876 fora** — estes são contados e excluídos, não forçados para dentro.

**Amostra, não universo:** o teste usa 1.500 registros de flora e 1.500 de fauna, uma amostra de conveniência das primeiras páginas do GBIF. Há 10.109 registros de flora e 52.016 de fauna disponíveis na consulta; a amostra não é aleatória e não representa o universo.

## O controle: 8.613 achados e 876 pontos fora

A auditoria olhou as 3.000 linhas do GBIF e as 6 da tabela de exemplo, e encontrou **8.613 ocorrências em 12 tipos**. Muitas são limitações da fonte, não erros de quem coletou: 3.000 registros sem esforço amostral (1.500 de flora e 1.500 de fauna), 1.499 de fauna sem município textual, 2.395 sem contagem de indivíduos (2.393 do GBIF + 2 da tabela de exemplo), 639 com incerteza maior que 10 km, 876 fora dos seis polígonos, 156 com sinonímia taxonômica e 48 com data só de ano.

O kit não preenche o que falta: `esforco = NA`, `individuos = NA` com uma coluna separada de presença, `precisao_data` e `ano_original`. O que entra no banco é o que tem origem. Depois do filtro: **2.124 observações, 738 espécies, 182 famílias, 76 ordens e zero órfãos**; a tabela de análise tem 46 linhas e 45 colunas.

Um exemplo do que teria dado errado: 99,9% dos registros de fauna não tinham o nome do município no texto. Se a seleção fosse `municipality == "Jataí"`, quase toda a fauna seria perdida. O point-in-polygon resolve isso com as coordenadas.

## O resultado: uma tabela pronta e três armadilhas que mudam a conclusão

A tabela de análise junta local, unidade de agregação, grupo, paisagem e socioeconomia. A riqueza observada é grande em Jataí (234 espécies de flora), Mineiros (154 de aves) e Serranópolis (126 de flora), mas **não é uma comparação justa de diversidade**: por célula município × grupo, os registros variam de 1 a 429; somando o município, de 1 a 1.197. Para comparar diversidade seria preciso rarefazer; o kit não faz isso.

A primeira armadilha é a **escala**. A correlação entre vegetação nativa e PIB per capita vai de **−0,60** no município inteiro para **+0,43** no buffer de 5 km. A correlação com agropecuária sobe de **0,54** para **0,89**; o 0,89 é descritivo e não passou por um teste próprio. Isso é um exercício didático com buffers no centróide municipal e **n=6** — não é um resultado ecológico. O próximo passo é medir a paisagem nas parcelas e propriedades reais.

A segunda é o **acaso**. O controle negativo embaralhou os dados 1.000 vezes e testou a correlação municipal de vegetação nativa com agropecuária (**0,54**): o intervalo nulo de 95% vai de **−0,77 a +0,77**, o valor está dentro dele e **p = 0,303**. Não há evidência para essa correlação com seis municípios; o **+0,89** do buffer de 10 km é outro par e não deve ser lido como resultado testado.

A terceira é o **perfil de pessoas**. População, PIB e ruralidade são agregados municipais; não medem o que um produtor pensa ou decide. O kit deixa uma tabela `perfil` vazia, com a especificação dos campos (a tabela é longa; o CSV modelo é largo), para quando você tiver entrevistas e dados de propriedade. A falácia ecológica é o risco principal.

## O que isso mostra: a IA faz o mecânico; a decisão continua com você

A IA escreveu o código, o dicionário, o point-in-polygon, o banco SQLite, as figuras e os testes. Nós definimos o pedido, os controles e conferimos os números; a revisão de três passadas encontrou erros na primeira versão — o dicionário era inerte e a riqueza por município estava inventada — e eles foram corrigidos.

O que continua sendo seu: decidir o que coletar, qual escala usar, o que uma espécie significa e como perguntar às pessoas.

O kit organiza as suas tabelas; a pergunta sobre as pessoas continua sendo sua.

## O pedido: organizar as tabelas e chegar à paisagem

Esta é a resposta que você enviou ao formulário.

Você pediu duas coisas: organizar as tabelas de fauna e flora do PELD e preparar a análise socioambiental da paisagem. O teste partiu daí: um kit em R, com scripts e um banco SQLite (um banco relacional em um arquivo), e um exemplo com dados públicos do sudoeste goiano, sem exigir que você renomeie as planilhas. O passo a passo está no “Como usar”, no fim da página.

## O dicionário é a ponte entre a sua planilha e o banco

O dicionário é um CSV de de-para: para cada planilha, você diz o nome do arquivo, a tabela de destino (`observacao`) e o de-para dos campos. `Sp_Name` é a espécie, `Dt_Coleta` a data, `Qtde` a contagem e `Lat`/`Lon` as coordenadas. O kit lê isso e monta o banco sem tocar nos cabeçalhos.

A tabela `minha_flora.csv` tem seis linhas criadas para o teste, não dados do PELD. Ela vira seis linhas de `observacao`, com espécie, data, precisão, contagem ou presença e município. As seis entram no banco do teste (2.130 observações, 744 espécies); o banco principal do exemplo tem 2.124 observações e 738 espécies, só com GBIF. O número 2.124 não inclui o exemplo.

O município não é digitado: o point-in-polygon testa cada coordenada contra as malhas do IBGE. A caixa do GBIF inclui municípios vizinhos: 2.124 pontos caem nos seis e 876 ficam fora, 237 de flora e 639 de fauna. Os de fora ficam no arquivo bruto com uma marca e saem do banco; não são empurrados para o município mais próximo. Os seis municípios são Caiapônia, Jataí, Mineiros, Perolândia, Rio Verde e Serranópolis, um exemplo da região do PELD CEMA/EBMN, não os sítios reais da sua pesquisa.

A amostra tem 1.500 registros de flora e 1.500 de fauna, das primeiras páginas de uma consulta ao GBIF. Não é aleatória; o universo da consulta é 10.109 de flora e 52.016 de fauna.

## A auditoria encontrou 8.613 avisos, e a maioria é limitação da fonte

Aqui “ocorrência” é aviso de auditoria, não registro de espécie. Uma linha pode ter mais de um aviso, por isso 8.613 é maior que as 3.006 linhas: 3.000 do GBIF e 6 do exemplo.

São 12 tipos no CSV, agrupados em 7 linhas na figura. Os maiores: 3.000 registros sem esforço amostral, 1.499 de fauna sem município no texto e 2.395 sem contagem de indivíduos; a figura mostra os outros, como 876 fora dos seis polígonos, 639 com incerteza maior que 10 km, 156 com sinonímia e 48 com data só de ano. Muitos não são erros de coleta: herbário não reporta esforço, o GBIF não preenche o município e a incerteza de 40 km vem da fonte.

O kit não preenche o que falta: o esforço fica `NA`, a contagem ausente fica `NA` com uma coluna de presença, e a data ganha `precisao_data` e `ano_original`. Nada é preenchido por chute.

Depois do filtro, o banco tem 2.124 observações, 738 espécies, 182 famílias, 76 ordens e nenhum registro sem local ou espécie correspondente. A tabela de análise tem 46 linhas e 45 colunas; cada linha é uma combinação de local, ano e grupo, não um registro individual. Uma seleção por `municipality == "Jataí"` perderia 99,9% da fauna, que não tem o município no texto; o point-in-polygon resolve com as coordenadas.

## O resultado: riqueza, escala e acaso

A riqueza observada é maior em Jataí, com 234 espécies de flora, e em Mineiros, com 154 de aves e 36 de mamíferos. Serranópolis tem 126 espécies de flora.

Não dá para comparar esses números diretamente: por célula de município e grupo, os registros vão de 1 a 429; somando o município, de 1 a 1.197. A riqueza cresce com o esforço. Para comparar diversidade seria preciso rarefazer, que é igualar o número de registros ou indivíduos; o kit não faz isso, mas no R dá para fazer com `vegan::rarefy` ou `iNEXT`.

A escala muda a correlação. Os buffers de 5 e 10 km são círculos em volta do centro geométrico do município, não das parcelas. A correlação entre vegetação nativa e agropecuária no PIB é 0,54 no município e 0,89 no buffer de 10 km; a figura mostra também o buffer de 5 km. A correlação com PIB per capita é −0,60 no município e +0,43 no buffer de 5 km. É um exercício didático com seis municípios, não um resultado ecológico; o próximo passo é medir a paisagem nas parcelas e propriedades reais.

O controle negativo embaralha os dados 1.000 vezes para ver o que o acaso produz. Ele testa o par municipal de vegetação nativa com agropecuária, 0,54: o intervalo nulo de 95% vai de −0,77 a +0,77, o valor está dentro e o p é 0,303. Não há evidência para essa correlação com seis municípios. O 0,89 do buffer de 10 km é outro par, descritivo, e não foi testado.

O perfil de pessoas não está nos dados municipais: população, PIB e ruralidade são agregados e não medem o que um produtor pensa ou decide. A tabela `perfil` está vazia; o modelo de propriedade é uma planilha larga e a tabela do banco é longa, e não há carregador pronto: é preciso transformar uma na outra. Concluir sobre pessoas a partir de municípios é a falácia ecológica.

## O que a IA fez e o que continua com você

A IA escreveu o código, o dicionário, o point-in-polygon, o banco SQLite, as figuras e os testes. Nós definimos o pedido, os controles e conferimos os números-chave; o `11_verificar_numeros.R` confere 32 deles, e a revisão independente está no repositório.

A primeira versão tinha dois erros; a revisão de três passadas e o script de verificação os encontraram, e a versão desta página é a corrigida.

O que continua com você: decidir o que coletar, qual escala usar, o que uma espécie significa e como perguntar às pessoas.

O kit organiza as tabelas. As decisões sobre o que coletar e como perguntar às pessoas continuam com você.

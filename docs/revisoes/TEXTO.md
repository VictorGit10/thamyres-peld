## O pedido: duas tarefas, uma infraestrutura

Você pediu duas coisas: organizar as tabelas de fauna e flora do PELD e preparar a análise socioambiental da paisagem, para entender a relação entre o perfil das pessoas e a conservação.

O que existe é um kit em R, com um passo em Python, e um banco SQLite — um banco relacional em um arquivo, que você abre no R ou no DB Browser for SQLite. O kit lê as planilhas sem renomear colunas, audita o que falta, atribui município pelas coordenadas, junta paisagem e socioeconomia e gera uma tabela de análise.

As planilhas reais do PELD ainda não estavam no teste; por isso o exemplo usa dados públicos do GBIF de seis municípios do sudoeste goiano. É o teste completo do caminho. Os números ecológicos do exemplo não são o produto: a primeira execução com os seus dados não será a primeira vez que o código roda. O passo a passo está no “Como usar”, no fim da página, com os arquivos e o link do repositório.

## O dicionário lê as suas colunas sem renomear nada

O dicionário de colunas é um CSV de de-para: uma tabela que diz qual coluna da sua planilha vira qual campo do banco. Para cada planilha, você informa o nome do arquivo e o campo de destino. `Sp_Name` vira espécie, `Dt_Coleta` vira data, `Qtde` vira contagem e `Lat`/`Lon` viram coordenadas. O kit lê esse mapa e monta o banco sem alterar os cabeçalhos originais.

O município não é digitado. O point-in-polygon — o teste que verifica se o ponto cai dentro do polígono do município — usa as malhas do IBGE. Dos 3.000 pontos do GBIF, 2.124 caem nos seis municípios e 876 ficam fora, 237 de flora e 639 de fauna. Os de fora permanecem no arquivo bruto com uma marca e saem do banco; não são empurrados para o município vizinho só para não perder o registro.

Os seis municípios são Caiapônia, Jataí, Mineiros, Perolândia, Rio Verde e Serranópolis, um exemplo da região do PELD CEMA/EBMN, não os sítios reais da sua pesquisa. Para usar os seus, é preciso incluir os municípios na lista, nas malhas e no mapa.

O banco principal, só com GBIF, tem 2.124 observações e 738 espécies. A amostra é de conveniência: 1.500 registros de flora e 1.500 de fauna, 900 aves e 600 mamíferos, das primeiras páginas de uma consulta; não é aleatória.

## A auditoria separa o que falta do que está errado

A auditoria é a rotina que vai examinar as suas planilhas. Ela mostra o que a fonte omite, o que o kit preserva e o que fica de fora.

Ela olha as 3.000 linhas do GBIF e as 6 do teste e encontra 8.613 avisos, reunidos em sete barras. As três maiores: 3.000 sem esforço amostral, 1.499 de fauna sem município textual e 2.395 sem contagem de indivíduos. As outras quatro completam o total com pontos fora, incerteza espacial, sinonímias e datas imprecisas.

A maioria decorre de limites da fonte, não de falhas de coleta. Herbários não relatam esforço, o GBIF omite municípios no texto e incertezas de 40 km vêm da base. O kit não inventa o que falta: o esforço fica `NA`; a contagem ausente fica `NA` com uma coluna de presença; a data ganha `precisao_data` e `ano_original`.

Como 99,9% da fauna não trazia município no texto, um filtro por município — por exemplo, `municipality == "Jataí"` — perderia quase toda a fauna; o problema é geral, não de Jataí. O point-in-polygon resolve com as coordenadas. Os 876 pontos externos continuam identificados no arquivo bruto e no mapa: são contados, não escondidos.

Depois do filtro, o banco principal, só com GBIF, tem 2.124 observações, 738 espécies e nenhum registro sem local ou espécie correspondente. A tabela de análise tem 46 linhas e 45 colunas; cada linha é uma combinação observada de local, ano e grupo, com riqueza, esforço, paisagem e socioeconomia lado a lado.

## O que o exemplo mostra: esforço, escala e acaso

Os números abaixo saem da amostra pública e dos seis municípios de exemplo. Servem para mostrar o que a tabela permite perguntar. As conclusões sobre o Cerrado ficam para quando os seus dados entrarem.

A riqueza observada acompanha o esforço. Por célula de município e grupo, os registros vão de 1 a 429; somando o município, de 1 a 1.197. Comparar áreas sem rarefazer seria comparar esforços, não diversidade. Rarefazer é igualar o número de registros ou indivíduos; o kit não faz isso, mas entrega o esforço para que você faça no R, com `vegan::rarefy` ou `iNEXT`.

A escala também muda a resposta. Entre vegetação nativa e participação da agropecuária no PIB, a correlação de Spearman é 0,54 no município, 0,66 no buffer de 5 km e 0,89 no buffer de 10 km. Os buffers são círculos em volta do centro geométrico do município, não das parcelas; o exemplo usa o centróide porque os dados públicos não têm as parcelas. Com os seus dados, a paisagem deve ser medida nas coordenadas das parcelas ou propriedades. Com seis municípios, os valores são descritivos: não dá para separar escala de instabilidade amostral.

O controle negativo embaralha os dados 1.000 vezes. Para o par municipal de 0,54, o intervalo de 95% vai de −0,77 a +0,77 e o p é 0,303: com seis municípios, o acaso ainda é uma explicação. O controle mostrou que essa pergunta precisa de mais unidades ou de dados de propriedade. O 0,89 do buffer de 10 km é descritivo e não foi testado.

População, PIB e ruralidade são agregados municipais; não medem o que um produtor pensa ou decide. A tabela `perfil` está vazia de propósito: é a estrutura pronta para as entrevistas. O que falta é o dado de campo e transformar o CSV modelo (uma linha por propriedade) no formato do banco (uma linha por variável). Concluir sobre pessoas a partir de municípios é a falácia ecológica.

São decisões que o kit obriga a enfrentar antes de concluir.

## O que está pronto e o que continua com você

O fluxo de fauna e flora está pronto para receber as suas planilhas: o dicionário aceita os seus cabeçalhos, o banco tem as sete tabelas e as chaves, e a auditoria, o point-in-polygon e a tabela de análise operam de ponta a ponta. O `10b` prova que uma tabela de colunas arbitrárias entra no fluxo; o `11_verificar_numeros.R` confere 32 números-chave.

O kit não substitui o desenho amostral do PELD. O que continua sendo decisão sua: quais perguntas priorizar, em que escala medir a paisagem e como interpretar os resultados para os sítios do projeto.

O próximo passo é trazer duas planilhas suas — uma de flora e uma de fauna — e, se já tiver, a planilha de propriedades. O “Como usar” mostra onde colocá-las; o resto do caminho já está testado.

O kit encurta o caminho até as suas perguntas. As respostas dependem dos seus dados.

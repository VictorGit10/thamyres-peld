# Roteiro do Encontro Individual (40 Minutos)

**Participantes:** Victor Amaral (LAPIG/UFG) & Pesquisadora do PELD Goiás  
**Objetivo:** Apresentar a solução prática de organização das tabelas ecológicas, demonstrar o kit em R em funcionamento com dados reais e alinhar a transição para as planilhas primárias da pesquisadora.

---

## Estrutura do Encontro (Bloco a Bloco)

```
[00:00 - 10:00] Bloco 1: A Realidade das Planilhas e o Diagnóstico de Auditoria (10 min)
[10:00 - 25:00] Bloco 2: A Ponte do Dicionário e o Banco SQLite sem Mudar o Excel (15 min)
[25:00 - 35:00] Bloco 3: Cruzamento Paisagem x Social e as Pegadinhas Metodológicas (10 min)
[35:00 - 40:00] Bloco 4: Próximos Passos e Tarefa Prática (5 min)
```

---

### Bloco 1: A Realidade das Planilhas e o Diagnóstico de Auditoria (10 min)
- **Foco visual:** Abrir [`saidas/diagnostico.md`](saidas/diagnostico.md) e a figura [`figuras/01_problemas_auditoria.png`](figuras/01_problemas_auditoria.png).
- **Mensagem principal:** *"O problema de organizar tabelas não é falta de organização pessoal; é que dados ecológicos de campo naturalmente misturam formatos, datas parciais, sinonímias taxonômicas e dados sem esforço reportado."*
- **Pontos a demonstrar:**
  1. Nos dados reais do sudoeste goiano, a auditoria catalogou **8.613 ocorrências de inconsistências em 12 tipos**: mais de 85% da flora e 73% da fauna vieram sem contagem numérica (`NA` em contagem), e 876 registros estavam fora dos 6 polígonos.
  2. Na fauna, 99,9% dos registros vieram sem o nome do município preenchido no texto. Se filtrássemos por texto, perderíamos quase toda a fauna.
  3. A auditoria automática do R aponta a linha exata e a gravidade de cada erro antes de tentar rodar qualquer modelo estatístico.

---

### Bloco 2: A Ponte do Dicionário e o Banco SQLite sem Mudar o Excel (15 min)
- **Foco visual:** Abrir [`dicionario_colunas.csv`](dicionario_colunas.csv), a tabela de teste [`dados/exemplo/minha_flora.csv`](dados/exemplo/minha_flora.csv) e rodar [`codigo/10_teste_dicionario.R`](codigo/10_teste_dicionario.R).
- **Mensagem principal:** *"Você não precisa passar dias renomeando colunas ou reformatando suas planilhas para um formato único. O motor de dicionário faz essa tradução dinamicamente para você."*
- **Pontos a demonstrar:**
  1. **O Dicionário Ativo:** Uma tabela de mapeamento onde você só precisa registrar: *"na minha planilha X, a espécie chama-se `Sp_Name`, a data é `Dt_Coleta`, a contagem é `Qtde` e as coordenadas são `Lat`/`Lon`"*.
  2. **Demonstração Prática:** Rodar o teste unitário `Rscript codigo/10_teste_dicionario.R` em tempo real na frente dela, mostrando como o R lê `minha_flora.csv` (sem qualquer coluna do GBIF), converte e padroniza para o esquema canônico sem erro.
  3. **Espacialização Poligonal (Point-in-Polygon):** Mostrar como o script Python com GeoPandas cruza cada ponto com os GeoJSONs dos 6 municípios, separando os registros canônicos (2.124 dentro) dos registros externos (876 fora).
  4. **O Banco Relacional (`peld.sqlite`) e a Tabela Pronta (`tabela_analise.csv`):** Integridade referencial com chaves estrangeiras validadas, separação de contagens reais de presenças (`individuos = NA` quando não há contagem) e esforço honesto (`esforco = NA` para dados oportunistas).

---

### Bloco 3: Cruzamento Paisagem x Social e as Pegadinhas Metodológicas (10 min)
- **Foco visual:** Abrir as figuras [`figuras/03_escala_paisagem_social.png`](figuras/03_escala_paisagem_social.png) e [`figuras/04_controle_negativo.png`](figuras/04_controle_negativo.png).
- **Mensagem principal:** *"Quando cruzamos biodiversidade com paisagem e pessoas, há duas grandes armadilhas: a sensibilidade matemática de escala (MAUP) e a falácia ecológica."*
- **Pontos a demonstrar:**
  1. **Sensibilidade de Escala (MAUP como Exercício Didático):** Mostrar como a correlação de Spearman inverte de sinal entre o município inteiro ($\rho = -0,6000$) e buffers de 5 km ($\rho = +0,4286$). Explicar que isso decorre da instabilidade de postos em $n=6$ e do centroide geométrico estar próximo à cidade, funcionando como alerta para nunca adotar uma única escala arbitrária.
  2. **Controle Negativo:** Mostrar que a correlação aparente de $\rho = 0,5429$ cai dentro da curva do acaso no teste de permutação ($p = 0,303$). Com $n=6$, qualquer regressão linear com $R^2 = 0,15$ não tem poder comprobatório.
  3. **A Falácia Ecológica:** Explicar por que os dados do IBGE municipal não medem o perfil das pessoas da região. Para analisar pessoas, precisamos de dados no nível da propriedade rural (mostrar a especificação relacional em [`dados/modelo_perfil_propriedade.csv`](dados/modelo_perfil_propriedade.csv)).

---

### Bloco 4: Próximos Passos e Tarefa Prática (5 min)
- **Foco visual:** Abrir o passo a passo no [`README.md`](README.md).
- **Mensagem principal:** *"A infraestrutura do kit, o motor de dicionário e os testes de integridade estão validados (`Rscript codigo/10_teste_dicionario.R` e `Rscript codigo/11_verificar_numeros.R`). Agora é plugar os seus dados reais."*

---

## 3 Perguntas-Chave para a Pesquisadora

1. **Esforço Amostral:** Suas planilhas de campo possuem colunas que registram o esforço real (ex.: horas de observação, número de redes-de-neblina/noite, área de parcelas) ou as coletas funcionam essencialmente como inventário de presença/ocorrência?
2. **Resolução Espacial:** Suas coletas de fauna e flora possuem coordenadas geográficas de pontos específicos (parcelas, transectos, armadilhas) ou estão vinculadas apenas ao nome da fazenda ou do município?
3. **Perfil de Pessoas:** A dimensão socioambiental que você pretende analisar virá de entrevistas e questionários aplicados diretamente com produtores/moradores das fazendas amostradas ou a intenção inicial era usar dados secundários municipais?

---

## O que Deixar como Próxima Tarefa para Ela

**Tarefa Concreta (estimada em 30 minutos):**
1. Selecionar **apenas duas planilhas** de seu acervo próprio (uma de flora e uma de fauna);
2. Copiar essas duas planilhas para a pasta `dados/bruto/`;
3. Abrir o [`dicionario_colunas.csv`](dicionario_colunas.csv) e adicionar as linhas mapeando os nomes originais das colunas dela para os campos canônicos (`grupo`, `especie`, `data`, `individuos`, `lat`/`lon`, `incerteza_metros` se houver). Use `grupo` exatamente como `Flora`, `Aves` ou `Mammalia`. **Não** mapeie `id_local` à mão: o `03b` calcula o município por point-in-polygon;
4. Rodar o fluxo completo (auditoria + espacialização + banco + tabela de análise):
   ```powershell
   python codigo/03b_atribuir_locais.py
   Rscript codigo/04_auditar.R
   Rscript codigo/05_padronizar.R
   Rscript codigo/06_juntar.R
   ```
5. Conferir [`saidas/diagnostico.md`](saidas/diagnostico.md) e [`saidas/tabela_analise.csv`](saidas/tabela_analise.csv) para ver os alertas e a tabela final das suas próprias planilhas.

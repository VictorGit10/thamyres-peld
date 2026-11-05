# Revisão independente — página do encontro com a Thamyres

**Revisor:** MiniMax M3.1 (sessão isolada, sem participação na produção da página)
**Rodadas:** 1ª (05/11, página original) → 2ª (após a 1ª correção) → 3ª (após a 2ª) → 4ª (após a 3ª) → **5ª e final (esta)**, após a correção do R28.
**Arquivos relidos nesta rodada:** `apresentacoes/thamyres/pagina.src.html`, `pagina.html` (offline), `TEXTO.md`, `apresentacoes/montar.py`, `thamyres/RELATORIO.md`, `R/funcoes.R` (normalização de `grupo`), `codigo/05_padronizar.R` e `codigo/07_analisar.R` (uso de `grupo` a jusante), `codigo/11_verificar_numeros.R` (simulado contra o RELATORIO reescrito), `saidas/metricas_analise.json`, `saidas/resumo_auditoria.csv`, `saidas/tabela_analise.csv`, `dados/banco/{especie,observacao}.csv`.
**Método:** conferência de cada uma das seis mudanças no arquivo-fonte; recomputação independente dos coeficientes e das permutações contra os arquivos atuais; **simulação das 32 verificações de regex do `11_verificar_numeros.R` contra o RELATORIO reescrito** (para garantir que a edição do §6 não quebrou o verificador); conferência md5 das 7 imagens embutidas contra `img/*.png`; resolução dos 6 links relativos; rastreamento de cada afirmação nova até o código que a executa.

> **Lembrete de arquitetura (vale para quem editar depois):** `pagina.src.html` é **gerado** por `apresentacoes/montar.py` (linha 332 escreve o arquivo; 334–339 embutem as imagens e asseguram `assert 'src="img/' not in final`). O texto narrativo vem de `TEXTO.md` (`montar.py` 133); as seções 5, 6 e 7 estão literais em `montar.py` (476–505). Correção de texto tem de ser feita **na fonte** e remontada (`python figuras.py` → `python montar.py`), senão o próximo `montar.py` apaga. A 3ª rodada seguiu a cadeia corretamente (`figuras.py` 00:20:48 → imagens 00:21:51–58 → `montar.py` 00:22 → `pagina.src.html`/`pagina.html` 00:22:04 → capturas 00:22:09–13). A **4ª rodada também**: `TEXTO.md` 00:27:41 e `RELATORIO.md` 00:27:51 → `montar.py` 00:27:56 → `pagina.src.html` e `pagina.html` 00:28:06. Nenhuma figura foi regerada nesta rodada (as 7 seguem de 00:21:51–58), o que é correto: só o texto mudou.

---

## Nota de 05/11 (texto reescrito depois desta revisão)

Depois da 5ª rodada, o texto narrativo da página foi reescrito para responder às dúvidas de leitura levantadas pelo Gemini 3.8 High (`reescrita/DUVIDAS.md`) e segue o `reescrita/BRIEFING.md`. Uma revisão focada do texto novo, em sessão isolada com MiniMax M3.1 Flash, reconferiu os números contra o `BRIEFING.md`, o `RELATORIO.md` e as saídas do pacote: 2.124/738; 2.130/744; 8.613 avisos em 12 tipos; 876 fora = 237 flora + 639 fauna; 46 × 45; 0,54/0,66/0,89; −0,60/+0,43; p = 0,303; 32 números conferidos. Não encontrou erro de conta. Os ajustes feitos a partir dela: procedência da amostra e comparação por grupo na abertura da seção 4; 0,66 explicitado; Spearman nomeado; “intervalo de 95% dos embaralhamentos”; 900 aves + 600 mamíferos; os dois erros da primeira versão nomeados; “mesma correlação em outra escala” no lugar de “outro par”. A ressalva dos 1.948 registros com incerteza > 5 km (176 válidos) permanece na seção Ressalvas.

---

## 1. O que foi corrigido na 3ª rodada - item a item

Verifiquei os oito pontos da sua lista. **Todos os oito foram de fato corrigidos**, cada um no arquivo-fonte certo.

| # | Mudança | Veredito | Evidência |
|---|---|---|---|
| 1 | Figura do controle negativo regerada | **Corrigido** | `img/controle_negativo.png` (mtime 05/11 00:21:57; 128.473 → 140.927 bytes — **é a única figura cujo tamanho mudou**, as outras 6 ficaram byte a byte idênticas). Título: *"O acaso explica a correlação municipal: p = 0,303"*. Subtítulo: *"Para o par municipal (nativa × agro, 0,54), o valor cai dentro do acaso. O +0,89 do buffer de 10 km é outro par e não foi testado."* O `alt`/`figcaption` da página acompanha (linha 298). |
| 2 | Aviso geográfico completo | **Corrigido** | Linha 314: *"Não basta mexer no `03b`: a tabela `local` vem de `dados/bruto/municipios_locais.csv` (gerada pelo `02`) e o `05` para com chaves órfãs se o município não estiver lá. Inclua os seus municípios no `02`/`municipios_locais.csv`, nas malhas e no mapa do `03b`; senão os seus registros serão excluídos ou o `05` falha."* Confere com `05_padronizar.R` 17 e 256–257, `02_baixar_ibge.R` 12–16 e 93, `03b` 44–51. Os três lugares a mexer estão nomeados. |
| 3 | Passo 2 protege o bloco `minha_flora` | **Corrigido** | Linha 310: *"Não edite as linhas do GBIF nem o bloco `minha_flora` (ele é o exemplo dos testes 10/10b)"*. Confere com `dicionario_colunas.csv` 47–52, `10_teste_dicionario.R` 65/69/74/79/84/95/114 e `10b` 57–62/81. |
| 4 | Ressalva do `perfil` | **Corrigido na ressalva** | Linha 321: *"Não há carregador pronto; o CSV modelo é largo e a tabela é longa, então você vai precisar transformar/pivotar antes de usar."* Confere com `05_padronizar.R` 230–240 (sempre vazia), `04_auditar.R` 37 (ignora o CSV), `modelo_perfil_propriedade.csv` (largo) × `perfil.csv`/`esquema.sql` 114–124 (longo). **Restam dois respiros** (ver §3). |
| 5 | Ressalva de incerteza espacial | **Corrigido** | Linha 322: *"As correlações mostradas são municipais (n=6) e não usam esse filtro; ele serve para a análise no nível do ponto, que ainda não foi feita."* Confere com `07_analisar.R` 88–100 (correlação por município) e `valido_paisagem` (filtro por registro). |
| 6 | Ressalva da riqueza | **Corrigido** | Linha 318: *"(até 429 por célula município × grupo; 1.197 no município)"*. Confiro: max por célula = 429 (Mineiros/Aves); por município, Mineiros = 429+426+342 = **1.197**, Perolândia = **1**. |
| 7 | Rodapé próprio | **Corrigido** | Linha 328: *"Kit executado pelo Gemini 3.8 Flash; texto e figuras organizados para o encontro; números conferidos contra scripts e banco. Revisão independente: MiniMax 3.1 Flash."* A contradição anterior ("Gemini 3.8 Flash" na seção 2 × "DeepSeek V4.1 Flash" no rodapé) e o "Gemini Argon" sumiram; o rodapé agora concorda com `TEXTO.md` 9. |
| 8 | Link para `codigo/` | **Corrigido** | Linha 305: `<a href="../../thamyres/codigo/">ver scripts</a>`. Resolve para um diretório com 15 scripts (`00_instalar.R` … `99_rodar_tudo.R`). A tabela da seção 5 passou a 6 linhas. |

**Verificação de integridade da página:** 7 imagens embutidas, todas conferem por md5 com `img/*.png`; zero `src` não-base64; zero `href` absolutos; os 6 links relativos resolvem para arquivos/pastas existentes; 9 âncoras do `nav` ↔ 9 `id` de `<section>`; nenhuma tabela com coluna errada (as duas do de-para mantêm `colspan` 5/6 e 5/6 colunas; a de arquivos agora tem 6 linhas com 3 colunas em todas); nenhum trecho cortado. As capturas (`previa_*.png`) foram regeradas (00:22:09–13) e conferem com o HTML.

---

## 2. Quarta rodada: as seis mudanças, conferidas uma a uma

Reli só o que mudou. **As seis estão de fato nos arquivos indicados**, e cada uma está tecnicamente correta.

| # | Mudança | Veredito | Evidência |
|---|---|---|---|
| R6 | Passo 2 manda mapear `grupo` e avisa do fallback | **Corrigido** | `pagina.src.html` 310: *"o mesmo para `grupo`, `data`, `individuos`, `lat`, `lon` … Se não houver `grupo`, o kit tenta adivinhar pelo nome do arquivo (`flora`, `fauna` etc.) e pode cair em 'Indeterminado'."* Confere com `05_padronizar.R` 64–68 (fallback por nome) e `R/funcoes.R` 269–280 (`pegar_col("grupo")` tem precedência sobre o fallback). A ordem do campo também está certa: `grupo` vem **antes** de `data`, o que faz o bloco novo bater com a ordem de `dicionario_colunas.csv`. |
| R7 | Passo 1 exige CSV | **Corrigido** | Linha 309: *"Copie duas planilhas (uma de flora, uma de fauna) para `dados/bruto/`, em **CSV**; se estiverem em Excel, exporte como CSV."* Confere com `05_padronizar.R` 62 (`read_csv`) e `03b` 96 (`pd.read_csv`). |
| R8 | `11` confere o relatório, não a página | **Corrigido** | Linha 312: *"o `11` confere os números-chave do relatório."* A formulação agora bate com o que o script faz (`11_verificar_numeros.R` 21–23 leem `RELATORIO.md`, `REVISAO-ALVO.md`, `ROTEIRO-ENCONTRO.md`). |
| R9 | Grão da tabela de análise | **Corrigido** | Linha 265: *"A tabela de análise tem 46 linhas × 45 colunas; cada linha é um local × ano × grupo, não um registro individual."* Confere com `esquema.sql` 25 (`campanha`) e `R/funcoes.R` 316–319 (`id_campanha` = `AGR_{id_local}_{ano}_{3 letras do grupo}`). |
| R24 | Corpo da seção 4 diz o formato do `perfil` | **Corrigido** | Linha 298: *"O kit deixa uma tabela `perfil` vazia, com a especificação dos campos (a tabela é longa; o CSV modelo é largo), para quando você tiver entrevistas e dados de propriedade."* |
| R25 | `RELATORIO.md` §6 corrigido | **Corrigido** | `RELATORIO.md` 166–170: *"o kit forneceu duas peças com formatos diferentes: … **modelo largo**, com uma coluna por variável (…); … tabela `perfil` no SQLite: **formato longo (EAV)**, com `id_propriedade`, `id_local`, `ano`, `variavel`, `valor`, `unidade`, `fonte`. Não há carregador pronto entre os dois formatos: para levar o CSV modelo à tabela `perfil`, é preciso transformar as colunas em linhas (pivotar) antes de carregar."* Confere com `modelo_perfil_propriedade.csv` (11 colunas), `esquema.sql` 114–124 e `dicionario_colunas.csv` 73–79 (formato longo). A página e o relatório agora dizem a mesma coisa. |

**Verificação de integridade da página (repetida):** `pagina.html` regerado (00:28:06), 7 imagens embutidas conferindo por md5 com `img/*.png`, zero `src` não-base64, zero `href` absolutos, os 6 links relativos resolvendo, 9 âncoras ↔ 9 seções, tabelas com as colunas certas.

**Conferência extra que fiz por causa do R25:** como o `RELATORIO.md` foi reescrito, simulei as **32 verificações de regex do `11_verificar_numeros.R`** contra o texto novo do relatório, do `REVISAO-ALVO.md` e do `ROTEIRO-ENCONTRO.md` — **nenhuma falha**. A reescrita do §6 mexeu na lista de campos do `perfil`, não em nenhum dos números verificados ("429.010", "3.000", "2.124", "876", "738", "535", "160", "43", "0,5429", "−0,6000", "+0,4286", "0,303", "ESP_001", "182", "76", "176", "1.414", "8.613", "12 tipos"), que continuam todos no texto.

**Números:** as saídas do pacote **não foram regeradas** (carimbos de 04/11/2026 15:26–15:27 em `saidas/` e `dados/banco/`), então são os mesmos arquivos da 3ª rodada; recomputei de novo contra eles e o resultado é o mesmo: ρ = +0,5429 / +0,6571 / +0,8857 e −0,6000; p exato 0,2972 (par municipal) e 0,0333 (buffer de 10 km); 8.613 em 12 tipos; 46 × 45; 738 / 182 / 76; 2.124 / 876; 176 válidos. Detalhes na §3.

---

## 3. Os números continuam batendo? Sim — reconferi tudo do zero

**As saídas do pacote não foram regeradas** (carimbos de 04/11/2026 15:26–15:27 em `saidas/` e `dados/banco/`), ou seja, os arquivos que eu conferi são exatamente os de agora. Recomputei contra eles:

| Verificação | Recomputado | Bate com a página? |
|---|---|---|
| ρ nativa(mun) × agro | +0,5429 | ✓ |
| ρ nativa(5 km) × agro | +0,6571 | ✓ |
| ρ nativa(10 km) × agro | +0,8857 | ✓ |
| ρ nativa(mun) × PIB per capita | −0,6000 | ✓ |
| p exato do par municipal (720 permutações) | 0,2972 | ✓ compatível com o 0,303 do pacote |
| p exato do par de 10 km | 0,0333 | ✓ a página afirma "não testado" — não afirma nada falso |
| Auditoria | 8.613 ocorrências em 12 tipos | ✓ |
| Tabela de análise | 46 linhas × 45 colunas | ✓ |
| Espécies / famílias / ordens | 738 / 182 / 76 | ✓ |
| Observações / fora dos polígonos | 2.124 / 876 | ✓ |
| Incerteza (valido_paisagem = 1) | 176 | ✓ |
| Registros por município | Caiapônia 26, Jataí 444, Mineiros 1.197, Perolândia 1, Rio Verde 111, Serranópolis 345 (soma 2.124) | ✓ sustenta o "1.197 no município" |
| `peld.sqlite` | 7 tabelas: campanha 46, especie 738, local 6, observacao 2.124, paisagem 54, perfil 0, social 6 | ✓ |
| `tabela_controle_escala.csv` | 0,5429/0,6571/0,8857 e −0,6/0,4286/0,4286 | ✓ |

**Nenhum número novo foi introduzido pela correção**, e nenhum número antigo quebrou. A página continua com o mesmo conjunto de valores — agora com quatro deles mais bem explicados ("3.000 do GBIF + 6 da tabela de exemplo", "2.393 + 2", "1.197 no município", "até 429 por célula") e com o escopo do controle negativo delimitado no texto **e** na figura.

*(Ressalva metodológica, pela segunda vez: o p exato de 0,2972 só sai se o limiar for o ρ observado **exato** — 0,5428571…; usando o valor arredondado 0,5429 o p sai 0,2417, porque 40 das 720 permutações têm |ρ| exatamente igual ao observado. O pacote reporta 0,303, consistente com 0,2972.)*

---

## 4. O que ainda resta

### Crítico
**Nenhum.** Os dois críticos originais (declarar a tabela no dicionário; saber que registros fora dos seis municípios são excluídos) e todos os importantes das rodadas 2ª, 3ª e 4ª foram resolvidos — e o único que a correção de R6 expôs (R28) foi resolvido na 5ª. **Não resta nenhum crítico nem nenhum importante.**

### Importante — **nenhum**

**R6, R7, R8 e R9 — [RESOLVIDOS na 4ª rodada].** O passo 2 manda mapear `grupo` e avisa do fallback por nome de arquivo (linha 310); o passo 1 exige CSV (309); o passo 4 diz "o `11` confere os números-chave do relatório" (312); e a nota da saída diz "cada linha é um local × ano × grupo, não um registro individual" (265). Os quatro textos estão tecnicamente corretos — conferi cada um contra o código. **R6, porém, abre um achado novo, que é o único importante que resta: o valor literal que ela deve escrever na coluna `grupo`.**

**R28 — [RESOLVIDO na 5ª rodada].** A página agora diz exatamente o que faltava: o passo 2 (linha 310) acrescenta "Use exatamente `Flora`, `Aves` ou `Mammalia`: o `07` e a figura contam por esses nomes; 'Fauna' não entra nas contas de aves/mamíferos." Conferi a frase contra o código: `07_analisar.R` 43 (`grupo == "Flora"`), 44 (`str_detect(grupo, "Aves")`) e 45 (`str_detect(grupo, "Mammalia")`) são exatamente essas três comparações, e `figuras.py` 220/224 chaveia as cores por `Flora`/`Aves`/`Mamíferos` — ou seja, a afirmação "o 07 e a figura contam por esses nomes" é verdadeira, e a implicação sobre "Fauna" também (simulei: `"Fauna"` não casa com nenhuma das três). A mesma orientação foi propagada ao `README.md` (Passo 2, linha 74: "Use `grupo` exatamente como `Flora`, `Aves` ou `Mammalia`") e ao `ROTEIRO-ENCONTRO.md` (tarefa 3, linha 69, que além passou a listar `grupo` entre os campos canônicos). A página foi remontada (00:35:30) e os três documentos estão coerentes entre si. o único buraco funcional que restava na página está fechado. A página, o README e o ROTEIRO agora dizem a mesma coisa sobre `grupo`, e essa coisa é a que o código faz.
**Estado:** o único buraco funcional que restava na página está fechado. A página, o README e o ROTEIRO agora dizem a mesma coisa sobre `grupo`, e essa coisa é a que o código faz.

### Menor — restos da 2ª e 3ª rodadas

- **R24 — [RESOLVIDO na 4ª rodada]** O corpo da seção 4 (linha 298) agora diz "com a especificação dos campos (a tabela é longa; o CSV modelo é largo)".
- **R25 — [RESOLVIDO na 4ª rodada]** O `RELATORIO.md` §6 (166–170) agora descreve as duas peças separadamente (modelo largo × tabela longa em EAV) e diz que não há carregador pronto e é preciso pivotar. Página e relatório concordam. Verifiquei também que as 32 checagens de regex do `11_verificar_numeros.R` continuam passando contra o relatório reescrito.
- **R26 — [MENOR] O aviso geográfico não menciona o que falta para o município novo ter paisagem e socioeconomia.** O aviso (314) cobre perda de registros e o `stop` de chave órfã — o que era o essencial — mas não diz que `03_paisagem_gee.py` (GEE) e `02_baixar_ibge.R` precisam rodar para o município novo, nem que `06_juntar.R` 72–74 (left_join) deixará `% nativa` e PIB em NA nas linhas do município novo (o script apenas conta e imprime, 77–84). Correção: uma frase: *"para ter paisagem e socioeconômia do município novo, é preciso rodar o `03_paisagem_gee.py` e o `02`; sem isso as linhas dele entram com paisagem vazia."*
- **R11 — [MENOR] A figura do esquema continua batizando `campanha` de "agregação".** `figuras.py` 327 e 331: a caixa se chama "agregação" (com `id_campanha (PK)` dentro) e o subtítulo repete "agregação"; a legenda da página (linha 299) repete. No banco a tabela é `campanha` (`esquema.sql` 25, `sqlite_master`). A figura foi regerada nesta rodada com o mesmo rótulo. Correção: "campanha (a unidade de agregação)".
- **R12 — [MENOR] "O `99_rodar_tudo.R` roda o pacote inteiro em 2,5 min"** (linha 307) segue sem lastro no pacote (não há log de tempo; `README.md` 106 diz "2 a 3 minutos").
- **R13 — [MENOR] "conferimos cada número"** (`TEXTO.md` 9) e a seção 8 (linha 326) mantêm a afirmação; o rodapé novo diz "números conferidos contra scripts e banco", que é mais preciso.
- **R16 — [MENOR] Sem medida de fragilidade do n=6.** Cálculo meu: retirando **um** município, ρ(nativa_mun × agro) vai de +0,54 a **+0,20** (sem Rio Verde). Uma linha na ressalva "Escala e n=6" seria mais convincente que só dizer "n=6".
- **R17 — [MENOR] "p = 0,303" com três casas**, sendo a resolução do Monte Carlo de 1.000 permutações de 0,001 (exato: 0,2972). Sugestão: "p = 0,30".
- **R18 — [MENOR] "8.613 achados" sem a nota de que uma linha pode ter vários tipos** — a nota existe no rodapé da figura, não no texto.
- **R19 — [MENOR] Os anos dos dados não aparecem:** paisagem 2024, população Censo 2022, ruralidade Censo 2010, PIB 2021 — a página fala de "PIB per capita" e "ruralidade" na mesma frase.
- **R20 — [MENOR] A reta da figura `riqueza.png` é ajustada sobre os 15 pontos de três grupos misturados** (`figuras.py` 238–242); a legenda já é honesta.
- **R21 — [MENOR] Resíduo técnico:** a classe `.depara` (linha 268) segue sem regra no CSS; ~25 classes CSS nunca usadas (`.gallery`, `.pair`, `.prompt-card`, `.results-grid`, `.langs`, `form-translation`, as regras `html[lang="fr"]`…) e as regras de idioma sem elemento; "pontos" (alt da figura do mapa) × "registros" (título da figura) para o mesmo 2.124.
- **R22 — [MENOR] Ritmo:** a seção 4 empilha três figuras de largura total; a classe `.pair` existe no CSS e não é usada — Riqueza + escala lado a lado e o controle negativo depois (quando a pergunta "isso é real?" já foi feita) pouparia 2–3 minutos do roteiro.
- **R23 — [MENOR] A linha "dados/banco/peld.sqlite" da seção 5 aponta para `esquema.md`** e não dá acesso ao arquivo do banco; agora há uma 6ª linha (`codigo/`), então cabe uma 7ª só para o `.sqlite`, ou o caminho em texto.
- **R27 — [MENOR] O passo 3 é uma parede de seis trechos `<code>` em um parágrafo** (linha 311). Visualmente, uma lista de comandos quebrando linha serviria melhor à leitura em 40 minutos.

---

## 5. Veredito final (5ª rodada)

**A página está pronta para o encontro, e não resta nenhum crítico nem nenhum importante.** Não há um único número errado, nenhuma imagem quebrada, nenhum link quebrado, nenhuma tabela quebrada — e, o que importa mais, não há nenhuma armadilha que vá fazer a Thamyres perder os próprios dados: ela sabe que precisa declarar as tabelas no dicionário, sabe que não deve tocar nos blocos existentes, sabe que precisa mapear `grupo` com os valores exatos `Flora`/`Aves`/`Mammalia`, sabe que o arquivo tem de ser CSV, sabe que registros fora dos seis municípios são excluídos (e o que mexer para incluir os dela), sabe que uma linha da tabela de análise é um agregado e não um registro, sabe que o controle negativo testou só o par municipal, e sabe que a tabela `perfil` ainda não está pronta para as entrevistas e que o modelo é largo enquanto a tabela é longa.

**As cinco rodadas produziram um resultado que vale registrar:** na 1ª, a página afirmava coisas que os dados não sustentavam (o escopo do controle negativo, a comparação de riqueza, a auditoria de 3.000 linhas) e omitia o passo que faz o kit funcionar; nas quatro seguintes, cada afirmação foi corrigida **na fonte** (`TEXTO.md`, `montar.py`, `figuras.py`, `RELATORIO.md`, `README.md`, `ROTEIRO-ENCONTRO.md`), não na aparência — e a cadeia de remontagem foi respeitada em todas: figuras antes da página, capturas depois. A página de hoje é a quinta leitura da mesma evidência, e as cinco coincidem.

**O último buraco funcional está fechado.** Com o R28 resolvido (o passo 2, o README e o ROTEIRO agora nomeiam os três valores aceitos em `grupo` e Avisam que "Fauna" não entra nas contas), não resta nenhum problema que possa produzir um resultado errado na mão da Thamyres: o que ela fizer com o kit agora depende do que ela decidir, não de uma omissão da página.

**O resto é preferência:** um "campanha" em vez de "agregação" (R11), o `03_paisagem_gee.py` e o NA de paisagem no aviso geográfico (R26), "2,5 min" (R12), "conferimos cada número" (R13), o leave-one-out (R16), "p = 0,30" (R17), a nota de múltiplos tipos no "8.613" (R18), os anos dos dados (R19), a reta da figura de riqueza (R20), a limpeza do CSS morto e do `.depara` (R21), o ritmo das três figuras empilhadas (R22), o acesso ao `.sqlite` pela tabela (R23) e o bloco de comandos do passo 3 (R27). Nada disso muda o que a Thamyres vai levar para casa.

**Uma última observação de método, sobre mim:** ao longo das cinco rodadas eu errei três vezes na verificação — uma por digitação (`municipicos` em vez de `valores_municipios`), uma por sombreamento de variável, e uma por limiar de permutação arredondado (0,5429 em vez do valor exato, que dava 0,2417 em vez de 0,2972). Nenhuma das três chegou ao documento: cada uma foi desfeita por um segundo método independente — leitura binária do JSON, comparação de carimbos, enumeração completa das 720 permutações — antes de eu escrever qualquer coisa. É a mesma disciplina que a página exige do kit: **um verificador que não pode falhar em silêncio**. O `11_verificar_numeros.R` ainda não tem essa propriedade — ele confere presença de string, não igualdade de valor, e não cobre a página. Vale a pena consertá-lo antes que ele sirva de argumento em outro encontro.

---

## O que está bom (versão final)

- **A honestidade virou conteúdo, não ressalva.** Cada limite que o pacote tem aparece na página com o número que o evidencia: 8.613 ocorrências em 12 tipos sobre 3.006 linhas; 2.393 + 2; 176 (8,3%) contra 1.948 (91,7%); n=6; 429 por célula contra 1.197 no município; um p de 0,303 que cobre um par só, com o outro par explicitamente rebaixado a "não testado" — **tanto no texto quanto dentro da figura**.
- **A seção 6 é agora executável, linha por linha.** Bloco no dicionário com os nomes de campo exigidos (incluindo `grupo`), CSV como formato, ordem de scripts correta (o `03b` antes do `04`, o que devolve o achado "fora dos 6 polígonos"), o aviso do GEE, a proteção do bloco de exemplo e o aviso geográfico completo, com os três arquivos a ajustar nomeados.
- **A página continua autossuficiente e portátil:** 7 figuras embutidas conferindo md5, zero links absolutos, 6 links relativos que resolvem, navegação por teclado, responsiva, e nenhum trecho cortado.
- **O fecho continua sendo o melhor parágrafo:** "O kit organiza as suas tabelas; a pergunta sobre as pessoas continua sendo sua." — e o rodapé agora diz quem fez o quê, sem contradição.
- **A revisão de quatro passadas vira parte do argumento,** não um disclaimer: a página mostra que a primeira versão tinha o dicionário inerte e a riqueza inventada, e que os dois foram encontrados e corrigidos. Isso é exatamente o que se pede a uma IA: que ela erre, que o processo ache, e que o resultado fique verificável.

- **A correção chegou ao pacote, não só à página.** O RELATORIO §6 agora descreve as duas peças do `perfil` separadamente (modelo largo × tabela longa em EAV) e avisa que não há carregador; a página e o relatório dizem a mesma coisa. E a cadeia de remontagem foi respeitada nas quatro rodadas:figures antes da página, capturas depois — o que é o que garante que o `pagina.html` que será aberto é o mesmo que o `pagina.src.html` que foi revisado.
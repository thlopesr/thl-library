# Convenções do projeto THL-Library

> Nota criada em 2026-09-24. Regras definidas pelo responsável do projeto — valem para todo código novo ou alterado. É a referência de convenções para agentes; o [`AGENTS.md`](../../AGENTS.md) da raiz (Codex e similares, criado em 2026-09-24) resume estas regras e aponta para cá.

## 1. Codificação de arquivos — **ISO-8859-1**

- **Padrão do projeto: ISO-8859-1 (Latin-1), sempre.** Vale para os fontes ABL (`.cls`, `.p`, `.w`, `.i`) de `Fontes\thl`, `Fontes\thl-lib`, `Fontes\thl-extensions` e `Utils\`.
- Não gravar fontes em UTF-8 nem com BOM. Ao editar um arquivo, **preservar os bytes** fora do trecho alterado (evitar ferramentas que regravam o arquivo inteiro em outra codificação).
- Comentários e strings podem ter acentos, desde que gravados em ISO-8859-1.
- **Exceção — front-end web (`Fontes\web\`: `.ts`, `.html`, `.scss`, `.json`): UTF-8**, padrão do Angular/Node (decisão de 2026-09-24). Documentação `.md` também em UTF-8.
- **Final de linha (`.gitattributes` na raiz, 2026-09-24):** no repositório todo texto fica com LF; no disco, fontes ABL (`.cls/.p/.w/.i/.df`), config do PDSOE e scripts Windows em **CRLF**; web e `.md` em **LF**. O `.gitattributes` **não converte codificação** (sem `working-tree-encoding`) — só marca `encoding=ISO-8859-1` nos fontes ABL para exibição em ferramentas Git. No primeiro commit após criá-lo, usar `git add --renormalize .`.

**Situação em 2026-09-25 (`file -b --mime-encoding`, fontes `.cls/.p/.w/.i`):**

| Pasta | UTF-8 | 8 bits (CP850 dos templates TOTVS)* | ISO-8859-1 | ASCII puro (compatível) |
|---|---|---|---|---|
| `Fontes\thl` | **0** | **0** | 131 | 16 |
| `Fontes\thl-lib` | 41 | — | — | 59 |
| `Fontes\thl-extensions` | 11 | — | 1 | 14 |
| `Utils` | 3 | — | 1 | 6 |

\* O `file` mostra "unknown-8bit". Nas telas/RPWs de `Fontes\thl` convertidos em 2026-09-25 os bytes eram **CP850** (código de página dos templates TOTVS: `Relat\xa2rio` = "Relatório", `Manuten\x87\xc6o` = "Manutenção"), não Windows-1252 — a conversão para ISO-8859-1 precisa decodificar como CP850, não apenas reclassificar o arquivo.

- `Fontes\thl`: os últimos UTF-8 (`thl0120.w`, `thl0221.w`, `thl0222rp.p`) foram convertidos em 2026-09-25; os acentos que já estavam perdidos (`�`) foram restaurados pela mesma linha em outra tela do mesmo template. Fontes novos de 2026-09-25 (`thl0020*`, `thl0210*`, `thl0250*`, `Utils\scripts\carga-thl-aplicacao.p`) já nasceram em ISO-8859-1.
- **2026-09-25 — decisão do responsável: tudo em ISO-8859-1.** Os trechos CP850 dos templates em `Fontes\thl` foram convertidos palavra a palavra (os arquivos misturavam CP850 e ISO-8859-1): 1.279 ocorrências em 126 arquivos, mais os rótulos corrompidos (`\xbb` + CP850) do thl0032. `Fontes\thl` está 100% ISO-8859-1/ASCII. ⚠️ O ambiente precisa compilar/ler as telas como ISO-8859-1 (`-cpstream`/`-cpinternal`); até lá os acentos aparecem trocados.
- **Pendente:** os 52 UTF-8 de `thl-lib`/`thl-extensions` e os 3 de `Utils`, com recompilação e teste. Fontes de `Fontes\thl` ainda em LF ou EOL misto (anterior à conversão): `thl0021-g01`, `thl0030-q01`, `thl0031-q01/-z01`, `thl0032-z01`, `thl0040-g01/-z01`, `thl0050.w/-g01/-z01`, `thl0051b/c/d/e-q01`, `thl0221rp.p`, `api/geterpuser.p`.

## 2. Pacote ABL = caminho da pasta, em minúsculas

- O pacote declarado em `class`/`interface`/`enum` deve ser **idêntico** ao caminho a partir de `Fontes\`, inclusive em maiúsculas e minúsculas: `Fontes\thl-lib\integration\messaging\inbound\core\InboundMessage.cls` → `thl-lib.integration.messaging.inbound.core.InboundMessage`.
- Tudo abaixo de `Fontes\` fica em **minúsculas** (kebab-case quando composto). O mesmo vale para `USING`, `INHERITS`, `NEW`, `CAST` e para os nomes gravados em `thl-objeto.classe-objeto`.
- Em 2026-09-24 a grafia `Inbound`/`Outbound` foi corrigida no código (44 ocorrências, 33 arquivos): as 126 classes batem pacote × pasta.

## 3. Onde colocar o código

- Genérico e reutilizável → `Fontes\thl-lib\`. **Nunca** tabelas de cliente (`nit-*`, `es_*`) em `thl-lib`.
- Específico de um sistema externo → `Fontes\thl-extensions\erp\<sistema>\…` (Services/enums) ou `Fontes\thl-extensions\integration\<sistema>\…` (mensagens, conectores).
- Telas e RPWs Datasul → `Fontes\thl\`.

## 4. Front-end web (`Fontes\web\`)

- Padrão: **componentes standalone por feature** — `src/app/<feature>/{pages,components,models,services}` + `<feature>-routing.ts` com `loadComponent`; compartilhados em `shared/components/thl-*`. Não usar `NgModule` (a pasta `modules\` foi migrada e removida em 2026-09-24).
- Design de telas: skill `thl-poui-design` (PO UI + Angular + componentes `thl-*` + TOTVS `@totvs/po-theme`); código: skill `thl-web-coding`.

## 5. Nomes

- Termos técnicos em inglês (camelCase para métodos/variáveis, PascalCase para classes); nomes de domínio Datasul em português (`NotaFiscalMessage`, `EmbarqueService`).
- Interfaces com prefixo `I` (em subpasta `interfaces\`); enums com sufixo `Enum` (exceção legada: `ExecutionMode`).
- Caminhos em `RUN`/`{include}` sempre com `/` (portável para PASOE/Linux).

## 6. Banco de dados — nomes de índice (decisão de 2026-09-24)

O OpenEdge não declara chave primária nem estrangeira: o índice cumpre esse papel. O prefixo diz qual é:

| Prefixo | Papel | Regras |
|---|---|---|
| `pk-<nome>` | **Chave primária** (de negócio) | Sempre `UNIQUE`; **uma por tabela**. Não precisa ser o índice `PRIMARY` do OpenEdge (ex.: em `thl-mensagem` o `PRIMARY` é `idx-objeto-criacao`) |
| `fk-<tabela-pai>` | **Chave estrangeira** — relação com a tabela pai | Campos = chave da tabela pai, na mesma ordem; não único. Pode repetir o nome em tabelas diferentes (`fk-mensagem`, `fk-objeto`). Dispensável quando é idêntico à `pk-` (relação 1:1) |
| `idx-<critério>` | **Índice de busca** | Existe para uma consulta concreta; o nome diz o critério (`idx-objeto-criacao`). Chave alternativa única também é `idx-` + `UNIQUE` (ex.: `idx-ip`, `idx-rota-publica`) |

- Índice novo só com consulta que o use; conferir a escolha com `COMPILE … XREF` (linha `SEARCH`). A seleção do ABL é por regra, não por custo: igualdades iniciais → primeiro intervalo → `BY` → `PRIMARY` → ordem alfabética.
- Não usar `use-index` para "forçar" índice: resolver empates pelo desenho (remover o concorrente ou torná-lo `PRIMARY`).
- **Implantação:** índice criado online em tabela com dados nasce **inativo** → `proutil <db> -C idxactivate` (ou `idxbuild`). Índice inativo não pode virar `PRIMARY`: trocar o primário exige um segundo `.df` depois da ativação. `RENAME INDEX` e `DROP INDEX` não reconstroem nada. Recompilar os programas das tabelas alteradas.
- Renomeação do `.df` atual para este padrão (44 renomeações + 1 remoção): ver [data/schema.md §6](data/schema.md).

## 7. Numeração dos programas Datasul (`Fontes\thl\`) — decisão de 2026-09-25

O número diz o **tipo** do programa (faixa) e o **assunto** (dezena). Consulta e tarefa usam o **mesmo final `NN`** do cadastro do assunto.

| Faixa | Tipo | Exemplo |
|---|---|---|
| `thl00NN` | Cadastro (`w-cadsim`, `w-cadpaifilho*`) | `thl0050` Tabela Auditoria |
| `thl01NN` | Consulta / monitor | `thl0150` Consulta de auditoria |
| `thl02NN` | Tarefa: tela de parâmetros (`w-relat`) + RPW `thl02NNrp.p` | `thl0250` Expurgo da auditoria |
| `thl03NN` | Relatório | a definir |

| Dezena (`NN`) | Assunto | Cadastros | Consultas | Tarefas |
|---|---|---|---|---|
| 0x | Ambiente | 0001 Ambiente, 0002 Parâmetro | — | — |
| 1x | E-mail | 0010 Email, 0011 Grupo Email Usuário | 0110 | 0210 Expurgo de e-mails |
| 2x | Objeto de integração / mensageria | 0020 Aplicação, 0021 Objeto, 0022 Parâmetro Objeto | 0120 Mensageria | 0220 Reprocessamento outbound (+ `thl0220z.p` agendador), 0221 Inbound agendado, 0222 Expurgo de mensagens |
| 3x | Conexão REST | 0030 URI, 0031 Path, 0032 Autenticação, 0033 Cabeçalho | — | — |
| 4x | Inbound | 0040 Rota | — | — |
| 5x | Auditoria | 0050 Tabela Auditoria, 0051 Parâmetros | 0150 | 0250 Expurgo da auditoria |

- Assunto novo começa numa **dezena nova**; dentro dela, de 1 em 1.
- Satélites mantêm o número e o sufixo: `-q01` query, `-v01` viewer, `-b01` browse, `-z01` zoom, `-g01` vá para; telas filhas `thlNNNNa..h`; RPW `thlNNNNrp.p`; utilitário `thlNNNNz.p`.
- **Cabeçalhos com o nome do próprio arquivo:** `i-prgvrs.i`, `ut9000.i`, `i-license-manager.i` e, no RPW, `c-programa` — é o que registra o programa no Datasul (vários estavam copiados de outro programa antes de 2026-09-25).
- **Validação nos viewers de cadastro:**
  - O `local-assign-record` chama a validação explicitamente, antes do `dispatch 'assign-record'`: `run pi-validate.` + `if return-value = 'ADM-ERROR':U then return 'ADM-ERROR':U.` (não usar `{include/i-valid.i}` junto, para não validar duas vezes).
  - Toda validação fica no `Pi-validate` e termina com foco no campo (`apply "entry"`) e `return "ADM-ERROR":U`.
  - Mensagens via `utp/ut-msgs.p`: **registro pai / relacionado não encontrado → mensagem 2**, com o nome da tabela por `{include/i-vldprg.i}` + `{utp/ut-table.i mgnitro <tabela> 1}` + `run utp/ut-msgs.p (input "show":U, input 2, input return-value)`; **demais validações (obrigatório, duplicado, domínio) → mensagem 17006** com `"Título~~Ajuda"`. Em ambos, `{include/i-vldprg.i}` logo antes do `ut-msgs.p` (orientação do template). Checagens da chave só com `adm-new-record`; em filhos, a parte da chave do pai vem de `find <pai> where rowid(<pai>) = v-row-parent`.
    - Exemplo **2**: no thl0002 (aba Variável) o ambiente informado não existe no thl0001 → mensagem 2 com o nome da tabela Ambiente.
    - Exemplo **17006**: no thl0021 (Objeto) a classe (`classe-objeto`) não pode ficar vazia → mensagem 17006 (`"Classe não informada~~Informe o nome completo da classe da mensagem."`).
  - Chave do registro fora de `ENABLED-FIELDS`, em `ADM-CREATE-FIELDS` + `ADM-ASSIGN-FIELDS` (editável só na inclusão).
  - **Eliminação com vínculo:** o viewer do cadastro pai sobrepõe `local-delete-record`: `if available <pai>` + `can-find(first <filho> where …)` → `ut-msgs.p` **17006** (`"Título~~Ajuda"`, citando o programa do vínculo) e `return 'ADM-ERROR':U`; senão `dispatch 'delete-record'`. Ex.: thl0020 não elimina aplicação com objetos no thl0021.
  - ⚠️ `{include/i-vldprg.i}` **só dentro do `Pi-validate`**, depois do `{include/i-vldfrm.i}`: ele usa `i_page-viewer`, definida pelo `i-vldfrm.i`. Em outra procedure (ex.: `local-delete-record`) dá erro 201/198 na compilação.
- **Zoom em viewer** (`{include/zoomvar.i &prog-zoom=… &campo=… &campozoom=…}`): `&campozoom` é o nome do campo **na tabela do zoom** — no zoom de usuário `fnzoom/z01fn017.w` (`usuar_mestre`) é `cod_usuario`/`nom_usuario`, com sublinhado. O browse do zoom devolve os campos em `pi-retorna-valor`, e cada campo devolvido precisa estar no `FIELDS(...)` da query do browse (senão volta vazio).
- Não reaproveitar número sem registrar em ADR: o `.r` antigo que sobrar no PROPATH abre a tela errada sem erro. Histórico e DE-PARA: [adr/renumeracao-cadastros-depara.md](adr/renumeracao-cadastros-depara.md).


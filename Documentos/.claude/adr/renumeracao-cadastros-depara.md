---
tipo: adr
modulo: cadastros
status: aceita
updated: 2026-09-25
camada: ambos
tags: [adr, cadastros]
---

# ADR — Renumeração dos programas de cadastro (DE-PARA inicial)

> **Executada nos fontes em 2026-09-25** (ver §6). As seções 2–5 mostram o levantamento **antes** da troca: os nomes "Atual" e as linhas do §5 referem-se aos arquivos antigos.
>
> Levantamento original: somente leitura, nenhum fonte alterado. Levantamento feito em 2026-09-25 por varredura de `Fontes\` (todos os `thl*.w` e `thl*.p`), `Database\thl.df` e `Utils\`. Nota de contexto: [thl/camada-datasul.md](../thl/camada-datasul.md).

## 1. Convenção de numeração

- Cada bloco começa numa **dezena nova** e segue de 1 em 1 dentro dela.
- A faixa **`thl00NN` é exclusiva de cadastro**. **Consulta = `thl01NN`**, com o mesmo `NN` do cadastro relacionado (ex.: cadastro `thl0050` → consulta `thl0150`) — decidido em 2026-09-25, substitui a proposta inicial `thl1xxx` (ver §7). **Tarefa (execução) = `thl02NN`** (§8). Relatório ainda a definir.
- Satélites mantêm o sufixo: `thlNNNN-q01` (SmartQuery), `-v01` (SmartViewer), `-b01` (SmartBrowser), `-z01` (zoom/pesquisa), `-g01` (vá para); telas filhas `thlNNNNa..h`.

| Novo | Cadastro | Bloco |
|---|---|---|
| thl0001 | Ambiente | 000x — ambiente |
| thl0002 | Parâmetro | 000x |
| thl0010 | Email | 001x — e-mail |
| thl0011 | Grupo Email Usuário | 001x |
| thl0020 | Aplicação (**ainda não existe**) | 002x — objeto de integração |
| thl0021 | Objeto | 002x |
| thl0022 | Parâmetro Objeto (inclui Objeto × Usuário em pasta) | 002x |
| thl0030 | URI | 003x — conexão REST |
| thl0031 | Path | 003x |
| thl0032 | Autenticação | 003x |
| thl0033 | Cabeçalho | 003x |
| thl0040 | Rota | 004x — inbound |
| thl0050 | Tabela Auditoria | 005x — auditoria |
| thl0051 | Tabela Auditoria Parâmetros | 005x |

Confirmados pelo responsável antes do levantamento: `thl0005 → thl0021` (Objeto) e `thl0020 → thl0050` (Tabela Auditoria).

## 2. Tabela DE-PARA

Associação feita **pela tabela principal** (`OPEN QUERY` da SmartQuery / `EXTERNAL-TABLES` do viewer), não pelo nome. "Nº refs" = ocorrências do número atual em `Fontes\` + `Database\thl.df` (entre parênteses, quantas estão **fora** da família do próprio programa — detalhe no §5). O status refere-se ao **número novo**: OK = livre hoje; CONFLITO = hoje pertence a outro programa; DÚVIDA = correspondência a confirmar; NOVO = programa ainda não existe.

| Atual | Novo | Cadastro | Tabela principal | SmartObjects | Nº refs | Status |
|---|---|---|---|---|---|---|
| thl0002 | thl0001 | Ambiente | `thl-ambiente` | `w-cadsim`: q01, v01; zoom z01 (→ b01); vá para g01 | 35 (0) | OK |
| thl0003 | thl0002 | Parâmetro | `thl-ambiente-param` | `w-cadpaifilho-ambos`: q01, v01, b01 (`-variavel`), b02 (`-prog`); zoom z01 (→ b03); g01; filhas `thl0003a` (`w-incmdp`, usa q01/v01), `thl0003b` (`-variavel`: b-q02, b-v01), `thl0003c` (`-prog`: c-q01, c-v01) | 117 (0) | CONFLITO — thl0002 é Ambiente |
| thl0011 | thl0010 | Email | `thl-email-param` | `w-cadsim`: q01, v01; z01 (→ b01) e g01 **sem uso** | 29 (1) | CONFLITO — thl0010 é Rota |
| thl0004 | thl0011 | Grupo Email Usuário | `thl-ambiente-param-grupo` (+ `-grupo-usuar`) | `w-cadpaifilho-ambos`: q01, v01, b01 (`-grupo-usuar`); filhas `thl0004a` (`w-incmdp`, q01/v01), `thl0004b` (b-q02, b-v01). Sem zoom/vá para | 73 (5) | CONFLITO — thl0011 é Email |
| — | thl0020 | Aplicação | — (não existe `thl-aplicacao`; hoje `aplicacao` é `character` solto em 5 tabelas) | — | — | NOVO + CONFLITO — thl0020 é Tabela Auditoria |
| thl0005 | thl0021 | Objeto | `thl-objeto` | `w-cadsim`: q01, v01; zoom z01 (→ b01); g01. **q01/z01/g01 são reusados por thl0006** | 55 (21) | CONFLITO — thl0021 é Tabela Auditoria Parâmetros |
| thl0006 | thl0022 | Parâmetro Objeto (+ Objeto × Usuário) | `thl-objeto` (pai) → `thl-objeto-parametro`, `thl-objeto-usuario` | `w-cadpaifilho-filho`: **`thl0005-q01`**, v01, b01 (`-parametro`), b02 (`-usuario`, pasta); zoom/vá para **de thl0005**; filhas `thl0006a` (a-q02, a-v01..v04), `thl0006b` (b-q01, b-v01); `thl0006a-q01` sem uso | 106 (8) | OK |
| thl0007 | thl0030 | URI | `thl-conexao-rest` | `w-cadsim`: q01, v01; z01 (→ b01) e g01 **sem uso** | 34 (0) | DÚVIDA — ver §2.1 |
| thl0008 | thl0031 | Path | `thl-conexao-rest-path` | `w-cadsim`: q01, v01; z01 (→ b01); g01 | 38 (2) | OK |
| thl0009 | thl0032 | Autenticação | `thl-conexao-rest-autenticacao` | `w-cadsim`: q01, v01; z01 (→ b01); g01 | 36 (1) | OK |
| thl0012 | thl0033 | Cabeçalho | `thl-conexao-rest-header` | `w-cadsim`: q01, v01; z01 (→ b01); g01 | 35 (0) | OK |
| thl0010 | thl0040 | Rota | `thl-inbound-rota` | `w-cadsim`: q01, v01; z01 (→ b01); g01 | 35 (0) | OK |
| thl0020 | thl0050 | Tabela Auditoria | `thl-audit-tabela` | `w-cadsim`: q01, v01; z01 (→ b01); g01. **q01/z01/g01 são reusados por thl0021** | 61 (31) | OK |
| thl0021 | thl0051 | Tabela Auditoria Parâmetros | `thl-audit-tabela` (pai) → `-acesso`, `-campo`, `-notificacao`, `-purge` | `w-cadpaifilho-filho`: **`thl0020-q01`**, v01, b01 (`-acesso`), b02 (`-campo`), b03 (`-notificacao`), b04 (`-purge`); zoom/vá para **de thl0020**; filhas `thl0021b` (acesso), `c` (campo), `d` (notificação), `e` (purge), cada uma com q01/v01 | 116 (1) | OK |
| thl0021h | thl0051h? | (auxiliar de Tabela Auditoria Parâmetros) | temp-table `ttFieldSchemaAux` (usa `SchemaUtil`) | `w-window` avulsa, sem SmartObjects; **nenhuma referência** | 2 (0) | DÚVIDA — ver §2.1 |

Títulos das janelas: a maioria ainda tem o texto do template (`Manutenção <Insira o complemento>`: thl0002–0006, thl0011, thl0021); os demais têm `Manutenção Conexão REST` (0007), `Manutenção Path Conexão REST` (0008), `Manutencao Autenticacao REST` (0009 **e 0012** — cópia), `Manutencao Rota Inbound` (0010), `Manutencao Audit Tabela` (0020). O título exibido de fato vem do cadastro do programa no menu Datasul (`ut9000.i`).

### 2.1 Dúvidas

- **thl0007 → thl0030 (URI):** a tabela `thl-conexao-rest` é a *conexão REST* (URL base + indicadores de autenticação e cabeçalho), e a tela se chama "Conexão REST". Encaixa em "URI" por eliminação (Path, Autenticação e Cabeçalho casam com as outras três tabelas do bloco). Confirmar se "URI" é o novo nome funcional da conexão.
- **thl0021h:** janela de seleção de campos (vinculados × não vinculados) sobre o schema da tabela auditada; ninguém a chama (órfã). Decidir se vira filha `thl0051h` (uso provável em `thl0021c`, Campo Auditado) ou se é descartada.
- **Identificação do programa errada nos cabeçalhos** (não muda a correspondência, mas deve ser corrigida na migração, porque `i-prgvrs.i`/`ut9000.i` registram o programa no Datasul): `thl0021.w` se identifica como **`thl0006`**; `thl0021b/d/e.w` e os satélites `thl0021b/c/d/e-q01/-v01` como **`thl0020b..e`**; `thl0020.w` tem `i-prgvrs.i XX9999`; `thl0006b.w` usa `thl0006B`.

## 3. Cadastros sem encaixe

- **Nenhuma janela principal de cadastro ficou sem linha.** As 13 janelas `w-cadsim`/`w-cadpaifilho-*` existentes foram associadas.
- Telas filhas (`thl0003a/b/c`, `thl0004a/b`, `thl0006a/b`, `thl0021b/c/d/e`) seguem o pai e trocam só o número.
- **Fora do escopo (não são cadastro):** `thl1986` (+a/b, monitor de mensageria), `thl1988`/`thl1988rp.p` (reprocessamento), `thl1989`/`thl1989rp.p`/`thl1989z.p` (expurgo/agendamento), `thl1991`/`thl1991rp.p` (inbound agendado), `thl2000` (+a, monitor de e-mail), `thl2020` (+b, consulta de auditoria).
- **Linhas da tabela sem programa atual:** somente **Aplicação (thl0020)**. Para existir, precisa de uma tabela mestre nova (ex.: `thl-aplicacao`) — hoje `aplicacao` é um `character` sem cadastro em `thl-inbound-rota`, `thl-mensagem`, `thl-objeto`, `thl-objeto-parametro` e `thl-objeto-usuario`.
- **Tabelas `thl-*` sem cadastro** (e que não pedem cadastro): `thl-audit-registro*` (eventos), `thl-audit-registro-notificar` (fila), `thl-mensagem*` (movimento), `thl-email` (log).

## 4. Conflitos de número e ordem de migração

| Número novo | Ocupado hoje por | Libera quando |
|---|---|---|
| thl0001 | — (livre) | — |
| thl0002 | Ambiente (thl0002) | thl0002 → thl0001 |
| thl0010 | Rota (thl0010) | thl0010 → thl0040 |
| thl0011 | Email (thl0011) | thl0011 → thl0010 |
| thl0020 | Tabela Auditoria (thl0020) | thl0020 → thl0050 |
| thl0021 | Tabela Auditoria Parâmetros (thl0021) | thl0021 → thl0051 |
| thl0022, thl0030–0033, thl0040, thl0050, thl0051 | — (livres) | — |

Não há ciclo. Dependências: `0021→0051` antes de `0005→0021`; `0020→0050` antes de criar Aplicação; `0010→0040` antes de `0011→0010`, que vem antes de `0004→0011`; `0002→0001` antes de `0003→0002`.

**Ordem sugerida** (cada passo = família inteira: principal, satélites, filhas, cabeçalhos `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

1. **Auditoria, juntos:** `thl0020 → thl0050` e `thl0021 → thl0051` (thl0051 usa `thl0020-q01/-z01/-g01`; migrar no mesmo passo e já corrigir os cabeçalhos `thl0006`/`thl0020b..e`).
2. **Rota:** `thl0010 → thl0040`.
3. **Conexão REST:** `thl0007 → thl0030`, `thl0008 → thl0031`, `thl0009 → thl0032`, `thl0012 → thl0033` (os comentários `Ponto de validação manual THL0008/THL0009` nos viewers de 0009/0010/0012 são só texto).
4. **Objeto, juntos:** `thl0005 → thl0021` e `thl0006 → thl0022` (thl0022 usa `thl0005-q01/-z01/-g01`). Depende do passo 1.
5. **E-mail em cadeia:** `thl0011 → thl0010` (depende do passo 2), depois `thl0004 → thl0011`.
6. **Ambiente em cadeia:** `thl0002 → thl0001`, depois `thl0003 → thl0002`.
7. **Criar Aplicação `thl0020`** (tabela nova no `.df` + cadastro), só depois do passo 1.
8. **Fora de `Fontes\`:** atualizar o cadastro de programas/menu do Datasul (programa, título, permissões de segurança, favoritos); recompilar cada família; apagar os `.r` antigos do PROPATH; atualizar pelo Data Dictionary as descrições do `Database\thl.df` que citam os números (`thl0004`, `thl0005`, `thl0006`, `thl0011`, `thl0020/thl0021`); atualizar as notas em `Documentos\` que citam os números (`data/schema.md`, `thl/camada-datasul.md`, `util/util.md` e 3 guias em `Documentos\tecnico\`).

**Impacto em código OO e RPW: nenhum.** Não há referência aos programas de cadastro em `.cls`, em `thl1xxx`/`thl2xxx`, em RP/RPW (`thl1988rp`, `thl1989rp`, `thl1989z`, `thl1991rp`), em `resourcen.p`, em `Utils\` nem no front-end web. Todas as referências estão nas próprias telas `Fontes\thl\thl00*` e nas descrições do `.df`.

**Observação para a próxima etapa (consulta/execução/relatório):** a faixa `thl1xxx`/`thl2xxx` já tem programas cujo final não segue a regra "mesmo final do cadastro" (`thl1986`, `thl1988`, `thl1989`, `thl1991`, `thl2000`, `thl2020`). Em especial, `thl2020` (consulta de auditoria) ocupa o futuro `thl2020` (execução de Aplicação) e, pela regra, seria `thl1050`.

### 4.1 DE-PARA por arquivo

| Família atual | Família nova | Arquivos (sufixos) |
|---|---|---|
| thl0002 | thl0001 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0003 | thl0002 | `.w`, `-q01`, `-v01`, `-b01`, `-b02`, `-b03`, `-z01`, `-g01`, `a`, `b`, `b-q02`, `b-v01`, `c`, `c-q01`, `c-v01` |
| thl0004 | thl0011 | `.w`, `-q01`, `-v01`, `-b01`, `a`, `b`, `b-q02`, `b-v01` |
| thl0005 | thl0021 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0006 | thl0022 | `.w`, `-v01`, `-b01`, `-b02`, `a`, `a-q01`, `a-q02`, `a-v01..v04`, `b`, `b-q01`, `b-v01` |
| thl0007 | thl0030 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0008 | thl0031 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0009 | thl0032 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0010 | thl0040 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0011 | thl0010 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0012 | thl0033 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0020 | thl0050 | `.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` |
| thl0021 | thl0051 | `.w`, `-v01`, `-b01..b04`, `b`, `b-q01`, `b-v01`, `c`, `c-q01`, `c-v01`, `d`, `d-q01`, `d-v01`, `e`, `e-q01`, `e-v01`, `h` (dúvida) |

Total: 110 arquivos `thl00*.w` em 13 famílias (109 + `thl0021h`). Nenhum `thl00*.p`.

## 5. Referências por programa (arquivo:linha)

Busca pelo número atual (`thlNNNN` seguido ou não de letra/sufixo, sem diferenciar maiúsculas) em `Fontes\`, `Database\` e `Utils\` (sem `node_modules`/`dist`). "Externas" = fora dos arquivos cujo nome começa pelo próprio número. Obs.: as referências `thl0020b..e` dentro de `thl0021*` são cabeçalhos com identificação errada (§2.1), não chamadas.

### thl0002 → thl0001 (35 refs: 35 na própria família, 0 externas)

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0002-b01.w` (1): 17
- `Fontes/thl/thl0002-g01.w` (2): 14, 362
- `Fontes/thl/thl0002-q01.w` (1): 17
- `Fontes/thl/thl0002-v01.w` (1): 17
- `Fontes/thl/thl0002-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0002.w` (20): 15, 109, 110, 505, 508, 509, 513, 515, 516, 519, 520, 526, 527, 528, 530, 531, 532, 533, 540, 659

### thl0003 → thl0002 (117 refs: 117 na própria família, 0 externas)

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0003-b01.w` (1): 17
- `Fontes/thl/thl0003-b02.w` (1): 17
- `Fontes/thl/thl0003-b03.w` (1): 17
- `Fontes/thl/thl0003-g01.w` (2): 14, 362
- `Fontes/thl/thl0003-q01.w` (1): 17
- `Fontes/thl/thl0003-v01.w` (1): 17
- `Fontes/thl/thl0003-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0003.w` (38): 15, 107, 108, 109, 110, 455, 458, 459, 472, 474, 475, 476, 478, 479, 485, 486, 487, 492, 493, 494, 495, 502, 505, 509, 517, 520, 521, 524, 525, 528, 533, 541, 544, 545, 548, 549, 552, 674
- `Fontes/thl/thl0003a.w` (17): 15, 91, 92, 270, 281, 331, 334, 335, 339, 342, 343, 346, 347, 348, 351, 471, 488
- `Fontes/thl/thl0003b-q02.w` (1): 17
- `Fontes/thl/thl0003b-v01.w` (1): 17
- `Fontes/thl/thl0003b.w` (18): 15, 93, 94, 281, 292, 342, 345, 346, 350, 353, 354, 357, 358, 359, 362, 482, 487, 505
- `Fontes/thl/thl0003c-q01.w` (1): 17
- `Fontes/thl/thl0003c-v01.w` (1): 17
- `Fontes/thl/thl0003c.w` (18): 15, 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 476, 481, 499

### thl0004 → thl0011 (73 refs: 68 na própria família, 5 externas)

**Externas (fora da família do programa):**

- `Database/thl.df:91` — `thl0004` — DESCRIPTION "Grupos de destinatários de e-mail usados em notificações e envios da THL (cadastro thl0004)."
- `Database/thl.df:126` — `thl0004` — DESCRIPTION "Usuários que compõem um grupo de e-mail, com e-mail alternativo opcional (cadastro thl0004)."
- `Database/thl.df:130` — `thl0004` — DESCRIPTION "Código do grupo de e-mail (thl-ambiente-param-grupo, cadastrado no thl0004)."
- `Database/thl.df:907` — `thl0004` — DESCRIPTION "Código do grupo de e-mail (thl-ambiente-param-grupo, cadastrado no thl0004)."
- `Database/thl.df:1552` — `thl0004` — DESCRIPTION "Código do grupo de e-mail (thl-ambiente-param-grupo, cadastrado no thl0004)."

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0004.w` (29): 15, 103, 104, 105, 453, 456, 457, 470, 478, 481, 482, 486, 490, 492, 493, 496, 497, 498, 503, 504, 506, 507, 508, 509, 510, 517, 520, 521, 643
- `Fontes/thl/thl0004a.w` (17): 15, 91, 92, 264, 275, 325, 328, 329, 333, 336, 337, 340, 341, 342, 345, 465, 482
- `Fontes/thl/thl0004b.w` (18): 15, 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 476, 481, 499

### thl0005 → thl0021 (55 refs: 34 na própria família, 21 externas)

**Externas (fora da família do programa):**

- `Fontes/thl/thl0006.w:101` — `thl0005-q01` — DEFINE VARIABLE h_thl0005-q01 AS HANDLE NO-UNDO.
- `Fontes/thl/thl0006.w:102` — `thl0005-v01` — DEFINE VARIABLE h_thl0005-v01 AS HANDLE NO-UNDO.
- `Fontes/thl/thl0006.w:409` — `thl0005-v01` — OUTPUT h_thl0005-v01 ).
- `Fontes/thl/thl0006.w:410` — `thl0005-v01` — RUN set-position IN h_thl0005-v01 ( 2.71 , 1.72 ) NO-ERROR.
- `Fontes/thl/thl0006.w:423` — `thl0005-q01` — INPUT  'thl/thl0005-q01.w':U ,
- `Fontes/thl/thl0006.w:425` — `thl0005-z01` — INPUT  'ProgPesquisa = thl\thl0005-z01.w,
- `Fontes/thl/thl0006.w:426` — `thl0005-g01` — ProgVaPara = thl\thl0005-g01.w,
- `Fontes/thl/thl0006.w:429` — `thl0005-q01` — OUTPUT h_thl0005-q01 ).
- `Fontes/thl/thl0006.w:430` — `thl0005-q01` — RUN set-position IN h_thl0005-q01 ( 2.00 , 60.00 ) NO-ERROR.
- `Fontes/thl/thl0006.w:436` — `thl0005-v01` — /* Links to SmartViewer h_thl0005-v01. */
- `Fontes/thl/thl0006.w:437` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_thl0005-q01 , 'Record':U , h_thl0005-v01 ).
- `Fontes/thl/thl0006.w:437` — `thl0005-v01` — RUN add-link IN adm-broker-hdl ( h_thl0005-q01 , 'Record':U , h_thl0005-v01 ).
- `Fontes/thl/thl0006.w:442` — `thl0005-q01` — /* Links to SmartQuery h_thl0005-q01. */
- `Fontes/thl/thl0006.w:443` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_thl0005-q01 ).
- `Fontes/thl/thl0006.w:444` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_thl0005-q01 ).
- `Fontes/thl/thl0006.w:445` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_thl0005-q01 ).
- `Fontes/thl/thl0006.w:450` — `thl0005-v01` — RUN adjust-tab-order IN adm-broker-hdl ( h_thl0005-v01 ,
- `Fontes/thl/thl0006.w:453` — `thl0005-v01` — h_thl0005-v01 , 'AFTER':U ).
- `Fontes/thl/thl0006.w:473` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_thl0005-q01 , 'Record':U , h_thl0006-b01 ).
- `Fontes/thl/thl0006.w:497` — `thl0005-q01` — RUN add-link IN adm-broker-hdl ( h_thl0005-q01 , 'Record':U , h_thl0006-b02 ).
- `Database/thl.df:2284` — `thl0005` — DESCRIPTION "Programa Datasul de consulta do registro de negócio do objeto. Cadastrado no thl0005; ainda não é

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0005-b01.w` (1): 16
- `Fontes/thl/thl0005-g01.w` (1): 361
- `Fontes/thl/thl0005-q01.w` (1): 16
- `Fontes/thl/thl0005-v01.w` (1): 17
- `Fontes/thl/thl0005-z01.w` (9): 15, 81, 333, 336, 337, 340, 341, 344, 465
- `Fontes/thl/thl0005.w` (20): 15, 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0006 → thl0022 (106 refs: 98 na própria família, 8 externas)

**Externas (fora da família do programa):**

- `Fontes/thl/thl0021.w:15` — `thl0006` — {include/i-prgvrs.i thl0006 12.00.00.000}
- `Fontes/thl/thl0021.w:672` — `thl0006` — {utp/ut9000.i "thl0006" "12.00.00.000"}
- `Database/thl.df:2410` — `thl0006` — DESCRIPTION "Indicador de persistência (reenvio) da integração. Cadastrado no thl0006; ainda não é lido pela b
- `Database/thl.df:2421` — `thl0006` — DESCRIPTION "Frequência de execução do processamento agendado ou batch. Cadastrado no thl0006; ainda não é lid
- `Database/thl.df:2443` — `thl0006` — DESCRIPTION "Quantidade de tentativas da persistência. Cadastrado no thl0006; ainda não é lido pela biblioteca
- `Database/thl.df:2454` — `thl0006` — DESCRIPTION "Quantidade de dias da persistência. Cadastrado no thl0006; ainda não é lido pela biblioteca."
- `Database/thl.df:2465` — `thl0006` — DESCRIPTION "Tipo de registro (log) da requisição. Cadastrado no thl0006; ainda não é lido pela biblioteca."
- `Database/thl.df:2510` — `thl0006` — DESCRIPTION "Tipo de registro (log) do retorno. Cadastrado no thl0006; ainda não é lido pela biblioteca."

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0006-b01.w` (1): 17
- `Fontes/thl/thl0006-b02.w` (1): 19
- `Fontes/thl/thl0006-v01.w` (1): 16
- `Fontes/thl/thl0006.w` (19): 15, 103, 104, 406, 457, 465, 468, 469, 472, 473, 476, 481, 489, 492, 493, 496, 497, 500, 622
- `Fontes/thl/thl0006a-q01.w` (1): 16
- `Fontes/thl/thl0006a-q02.w` (1): 17
- `Fontes/thl/thl0006a-v01.w` (1): 17
- `Fontes/thl/thl0006a-v02.w` (1): 17
- `Fontes/thl/thl0006a-v03.w` (1): 17
- `Fontes/thl/thl0006a-v04.w` (1): 17
- `Fontes/thl/thl0006a.w` (42): 15, 94, 95, 96, 97, 98, 278, 289, 348, 351, 352, 364, 367, 368, 371, 372, 373, 376, 381, 384, 385, 391, 392, 393, 396, 401, 404, 405, 411, 412, 413, 416, 421, 424, 425, 431, 432, 433, 436, 556, 561, 579
- `Fontes/thl/thl0006b-q01.w` (1): 16
- `Fontes/thl/thl0006b-v01.w` (1): 17
- `Fontes/thl/thl0006b.w` (18): 15, 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 476, 481, 499

### thl0007 → thl0030 (34 refs: 34 na própria família, 0 externas)

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0007-b01.w` (1): 17
- `Fontes/thl/thl0007-g01.w` (2): 14, 361
- `Fontes/thl/thl0007-q01.w` (1): 17
- `Fontes/thl/thl0007-v01.w` (2): 17, 436
- `Fontes/thl/thl0007-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0007.w` (18): 15, 109, 110, 499, 502, 503, 507, 510, 511, 517, 518, 519, 521, 522, 523, 524, 531, 650

### thl0008 → thl0031 (38 refs: 36 na própria família, 2 externas)

**Externas (fora da família do programa):**

- `Fontes/thl/thl0009-v01.w:486` — `THL0008` — /* Ponto de validaÆo manual THL0008:
- `Fontes/thl/thl0012-v01.w:422` — `THL0008` — /* Ponto de validaÆo manual THL0008:

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0008-b01.w` (1): 17
- `Fontes/thl/thl0008-g01.w` (2): 14, 361
- `Fontes/thl/thl0008-q01.w` (1): 17
- `Fontes/thl/thl0008-v01.w` (2): 17, 438
- `Fontes/thl/thl0008-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0008.w` (20): 15, 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0009 → thl0032 (36 refs: 35 na própria família, 1 externas)

**Externas (fora da família do programa):**

- `Fontes/thl/thl0010-v01.w:431` — `THL0009` — /* Ponto de validacao manual THL0009:

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0009-b01.w` (1): 17
- `Fontes/thl/thl0009-g01.w` (2): 14, 361
- `Fontes/thl/thl0009-q01.w` (1): 17
- `Fontes/thl/thl0009-v01.w` (1): 17
- `Fontes/thl/thl0009-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0009.w` (20): 15, 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0010 → thl0040 (35 refs: 35 na própria família, 0 externas)

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0010-b01.w` (1): 17
- `Fontes/thl/thl0010-g01.w` (2): 14, 362
- `Fontes/thl/thl0010-q01.w` (1): 17
- `Fontes/thl/thl0010-v01.w` (1): 17
- `Fontes/thl/thl0010-z01.w` (9): 15, 81, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0010.w` (20): 15, 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0011 → thl0010 (29 refs: 28 na própria família, 1 externas)

**Externas (fora da família do programa):**

- `Database/thl.df:1537` — `thl0011` — DESCRIPTION "Modelos de envio de e-mail: remetente, cópia, assunto, mensagem, importância e grupo de destinatá

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0011-g01.w` (1): 362
- `Fontes/thl/thl0011-z01.w` (8): 80, 340, 343, 344, 347, 348, 351, 472
- `Fontes/thl/thl0011.w` (18): 15, 106, 107, 505, 508, 509, 513, 516, 517, 523, 524, 525, 527, 528, 529, 530, 537, 656

### thl0012 → thl0033 (35 refs: 35 na própria família, 0 externas)

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0012-b01.w` (1): 17
- `Fontes/thl/thl0012-g01.w` (2): 14, 361
- `Fontes/thl/thl0012-q01.w` (1): 17
- `Fontes/thl/thl0012-v01.w` (1): 17
- `Fontes/thl/thl0012-z01.w` (9): 15, 81, 333, 336, 337, 340, 341, 344, 465
- `Fontes/thl/thl0012.w` (20): 15, 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0020 → thl0050 (61 refs: 30 na própria família, 31 externas)

**Externas (fora da família do programa):**

- `Fontes/thl/thl0021-v01.w:434` — `THL0020` — /* Ponto de validacao manual THL0020:
- `Fontes/thl/thl0021.w:101` — `thl0020-q01` — DEFINE VARIABLE h_thl0020-q01 AS HANDLE NO-UNDO.
- `Fontes/thl/thl0021.w:425` — `thl0020-q01` — INPUT  'thl/thl0020-q01.w':U ,
- `Fontes/thl/thl0021.w:427` — `thl0020-z01` — INPUT  'ProgPesquisa = thl\thl0020-z01.w,
- `Fontes/thl/thl0021.w:428` — `thl0020-g01` — ProgVaPara = thl\thl0020-g01.w,
- `Fontes/thl/thl0021.w:431` — `thl0020-q01` — OUTPUT h_thl0020-q01 ).
- `Fontes/thl/thl0021.w:432` — `thl0020-q01` — RUN set-position IN h_thl0020-q01 ( 2.00 , 60.00 ) NO-ERROR.
- `Fontes/thl/thl0021.w:439` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_thl0020-q01 , 'Record':U , h_thl0021-v01 ).
- `Fontes/thl/thl0021.w:444` — `thl0020-q01` — /* Links to SmartQuery h_thl0020-q01. */
- `Fontes/thl/thl0021.w:445` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_thl0020-q01 ).
- `Fontes/thl/thl0021.w:446` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_thl0020-q01 ).
- `Fontes/thl/thl0021.w:447` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_thl0020-q01 ).
- `Fontes/thl/thl0021.w:475` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_thl0020-q01 , 'Record':U , h_thl0021-b02 ).
- `Fontes/thl/thl0021.w:499` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_thl0020-q01 , 'Record':U , h_thl0021-b01 ).
- `Fontes/thl/thl0021.w:523` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_thl0020-q01 , 'Record':U , h_thl0021-b03 ).
- `Fontes/thl/thl0021.w:547` — `thl0020-q01` — RUN add-link IN adm-broker-hdl ( h_thl0020-q01 , 'Record':U , h_thl0021-b04 ).
- `Fontes/thl/thl0021b-q01.w:16` — `thl0020b-q01` — {include/i-prgvrs.i thl0020b-q01 12.00.00.000}
- `Fontes/thl/thl0021b-v01.w:17` — `thl0020b-v01` — {include/i-prgvrs.i thl0020b-v01 12.00.00.000}
- `Fontes/thl/thl0021b.w:15` — `THL0020B` — {include/i-prgvrs.i THL0020B 12.00.00.000}
- `Fontes/thl/thl0021b.w:476` — `THL0020B` — {utp/ut9000.i "THL0020B" "12.00.00.000"}
- `Fontes/thl/thl0021c-q01.w:16` — `thl0020c-q01` — {include/i-prgvrs.i thl0020c-q01 12.00.00.000}
- `Fontes/thl/thl0021c-v01.w:17` — `thl0020c-v01` — {include/i-prgvrs.i thl0020c-v01 12.00.00.000}
- `Fontes/thl/thl0021d-q01.w:16` — `thl0020d-q01` — {include/i-prgvrs.i thl0020d-q01 12.00.00.000}
- `Fontes/thl/thl0021d-v01.w:17` — `thl0020d-v01` — {include/i-prgvrs.i thl0020d-v01 12.00.00.000}
- `Fontes/thl/thl0021d.w:15` — `THL0020D` — {include/i-prgvrs.i THL0020D 12.00.00.000}
- `Fontes/thl/thl0021d.w:476` — `THL0020D` — {utp/ut9000.i "THL0020D" "12.00.00.000"}
- `Fontes/thl/thl0021e-q01.w:16` — `thl0020e-q01` — {include/i-prgvrs.i thl0020e-q01 12.00.00.000}
- `Fontes/thl/thl0021e-v01.w:17` — `thl0020e-v01` — {include/i-prgvrs.i thl0020e-v01 12.00.00.000}
- `Fontes/thl/thl0021e.w:15` — `THL0020E` — {include/i-prgvrs.i THL0020E 12.00.00.000}
- `Fontes/thl/thl0021e.w:476` — `THL0020E` — {utp/ut9000.i "THL0020E" "12.00.00.000"}
- `Database/thl.df:574` — `thl0020` — DESCRIPTION "Configuração das tabelas auditadas: quais operações registrar, nível de sensibilidade e campos da

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0020-g01.w` (1): 368
- `Fontes/thl/thl0020-v01.w` (1): 513
- `Fontes/thl/thl0020-z01.w` (8): 81, 333, 336, 337, 340, 341, 344, 465
- `Fontes/thl/thl0020.w` (19): 109, 110, 499, 502, 503, 507, 509, 510, 513, 514, 520, 521, 522, 524, 525, 526, 527, 534, 653

### thl0021 → thl0051 (116 refs: 115 na própria família, 1 externas)

**Externas (fora da família do programa):**

- `Database/thl.df:574` — `thl0021` — DESCRIPTION "Configuração das tabelas auditadas: quais operações registrar, nível de sensibilidade e campos da

**Na própria família** (cabeçalho `i-prgvrs.i`/`ut9000.i`, handles `h_thlNNNN-*`, `init-object`, atributos `ProgPesquisa`/`ProgVaPara`/`ProgIncMod`):

- `Fontes/thl/thl0021-b02.w` (1): 17
- `Fontes/thl/thl0021-b03.w` (1): 17
- `Fontes/thl/thl0021-b04.w` (1): 17
- `Fontes/thl/thl0021.w` (40): 102, 103, 104, 105, 106, 408, 411, 412, 438, 439, 452, 455, 459, 467, 470, 471, 474, 475, 478, 483, 491, 494, 495, 498, 499, 502, 507, 515, 518, 519, 522, 523, 526, 531, 539, 542, 543, 546, 547, 550
- `Fontes/thl/thl0021b.w` (16): 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 481, 499
- `Fontes/thl/thl0021c.w` (18): 15, 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 476, 481, 499
- `Fontes/thl/thl0021d.w` (16): 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 481, 499
- `Fontes/thl/thl0021e.w` (16): 93, 94, 275, 286, 336, 339, 340, 344, 347, 348, 351, 352, 353, 356, 481, 499
- `Fontes/thl/thl0021h.w` (2): 17, 638

## 6. Execução (2026-09-25)

Feita por script, autorizada pelo responsável:

- **110 arquivos renomeados** conforme §4.1 (todas as famílias de uma vez, em duas fases com nomes temporários, porque as cadeias 0011→0010→0040 e 0003→0002→0001 se cruzam). Dúvidas resolvidas pelo padrão proposto: `thl0007 → thl0030` (URI) e `thl0021h → thl0051h`.
- **Conteúdo:** todo `thlNNNN` do mapa trocado num único passo, byte a byte (ISO-8859-1 e CRLF preservados; mesmo número de linhas; fora dos cabeçalhos só mudaram dígitos). Isso cobre `init-object`, handles `h_thlNNNN-*`, `ProgPesquisa`/`ProgVaPara`/`ProgIncMod` e comentários.
- **Cabeçalhos corrigidos:** `i-prgvrs.i` e `ut9000.i` de todos os 110 arquivos agora identificam o próprio arquivo (antes: `thl0021.w` = `thl0006`, `thl0021b/d/e*` = `thl0020b..e`, `thl0020.w` = `XX9999`, `thl0006b.w` = `thl0006B`).
- **Conferência:** 0 problemas — todo `thl/…w` referenciado existe; nenhum número fora do mapa; nenhum BOM.
- **Documentação:** `README.md`, `thl/camada-datasul.md`, `data/schema.md`, `util/util.md` e 3 guias em `Documentos	ecnico\` com os números novos. Changelogs antigos do `INDEX.md` mantidos como histórico.

**Pendente (responsável):**

1. Compilar as 13 famílias no PDSOE / `Utils/scripts/compilar-thl.p` (não há compilador no ambiente do agente).
2. Datasul: cadastrar os programas novos (menu, título, permissões de segurança), remover os antigos e **apagar os `.r` antigos** do PROPATH — publicação de uma vez por ambiente (os números 0002, 0010, 0011 e 0021 mudaram de significado).
3. `Database	hl.df`: atualizar pelo Data Dictionary as descrições que citam `thl0004`, `thl0005`, `thl0006`, `thl0011`, `thl0020/thl0021`.
4. Git: os arquivos antigos aparecem como apagados e os novos como não versionados; o Git detecta a renomeação ao adicionar os dois lados.
5. ~~Criar Aplicação (`thl0020`)~~ — **feito em 2026-09-25**: tabela `thl-aplicacao` no `.df` e cadastro `thl0020` (`w-cadsim`) gerado da família thl0021. Falta ligar o campo `aplicacao` das demais tabelas ao cadastro (validação/zoom).

## 7. Consultas (2026-09-25)

Regra decidida pelo responsável: consulta = `thl01` + o `NN` do cadastro relacionado.

| Atual | Novo | Consulta | Cadastro relacionado | Arquivos |
|---|---|---|---|---|
| thl2000 | thl0110 | Monitor de e-mail (`thl-email`) | thl0010 Email | `.w`, `a` |
| thl1986 | **thl0120** | Monitor de mensageria (`thl-mensagem*`) + reenvio outbound | bloco 002x (objeto de integração) — definido pelo responsável | `.w`, `a`, `b`, `b-v01`, `b-v02` |
| thl2020 | thl0150 | Consulta de auditoria (`thl-audit-registro*`) | thl0050 Tabela Auditoria | `.w`, `b` |

Execução (script, mesmo método do §6): 9 telas renomeadas; `thlNNNN` trocado byte a byte (CRLF preservado); `i-prgvrs.i`, `ut9000.i` e `i-license-manager.i` com o nome do próprio arquivo; `&GLOBAL-DEFINE Program` corrigido onde apontava para outra família (`thl2020b` dizia `thl2000a` → agora `thl0150b`; `thl0120a` mantém `thl0120`, do pai). Comentários "padrão thl1986" (agora thl0120) em `MensageriaService`, `MensageriaConteudoService` e `MensageriaMessage` atualizados (só comentário). Nenhuma referência no front-end web. Documentação (`README.md`, `Documentos
egocio\`, `Documentos	ecnico\`, notas `.claude`, skill `thl-qa`) atualizada; nessa passada também foram corrigidos os números de cadastro em maiúsculas (`THL0006`…) que a primeira varredura não pegou em `Documentos
egocio\`.

**Pendências:**

- `thl0120.w` continua chamando `RUN thl	hl0120h.w` (antes `thl1986h.w`), tela que não existe; `thl0120b-v01/-v02` continuam órfãos — mantidos como estavam, por decisão do responsável.
- ~~`thl0120.w` (antigo `thl1986.w`) já estava em **UTF-8**~~ — **convertido para ISO-8859-1 em 2026-09-25**.
- `Database	hl.df`: descrições citam `thl2000` (`thl-email`, índice por programa/data) e `thl1986` (`thl-objeto-usuario`) — atualizar pelo Data Dictionary.
- Compilar; menu/permissões Datasul; apagar `.r` antigos (`thl1986*`, `thl2000*`, `thl2020*`).
- RPWs `thl1988`, `thl1989`/`thl1989z.p`, `thl1991` ainda na numeração antiga — `thl1989z.p` é chamado por `SchedulingService` e `InboundSchedulingService` (`run thl/thl1989z.p`), então renomeá-lo exigirá mexer em `.cls`.

> Ajuste 2026-09-25: o monitor de mensageria foi primeiro renomeado para `thl0121` e, por decisão do responsável, passou para **`thl0120`** (mesma troca byte a byte; tamanho e CRLF conferidos).

## 8. Tarefas (2026-09-25)

Regra: tarefa (tela de parâmetros + RPW) = `thl02NN`. As três tarefas de mensageria ficam no bloco 002x, em sequência (decisão do responsável).

| Atual | Novo | Tarefa |
|---|---|---|
| thl1988.w / thl1988rp.p | **thl0220.w / thl0220rp.p** | Reprocessamento outbound (`OutboundMessageService:reprocess`) |
| thl1989z.p | **thl0220z.p** | Agendador RPW chamado por `SchedulingService` e `InboundSchedulingService` |
| thl1991.w / thl1991rp.p | **thl0221.w / thl0221rp.p** | Processamento inbound agendado (`InboundMessageService:processScheduled`) |
| thl1989.w / thl1989rp.p | **thl0222.w / thl0222rp.p** | Expurgo de mensagens (`delete` de mensagem, conteúdo, histórico, item, ped-exec) |

### 8.1 Defeito corrigido junto (autorizado pelo responsável)

Antes da troca, os identificadores dos dois runners estavam invertidos: `thl1988rp.p` (reprocessamento) se declarava `thl1989rp`/`c-programa 'thl1989'`, e `thl1989rp.p` (expurgo) se declarava `thl1988rp`/`'thl1988'`. O agendador `thl1989z.p` criava o `ped_exec` das mensagens **outbound** com `nom_prog_ext = 'thl/thl1989rp.p'`, isto é, **o runner de expurgo**. Com isso a mensagem outbound agendada nunca era enviada: o `tt-param` do agendador não tem `qtd-dias` e a mensagem nova tem `dt-integracao = ?`. E uma mensagem já integrada que fosse reagendada podia ser apagada.

Agora o ramo outbound do `thl0220z.p` aponta para `thl0220`/`thl/thl0220rp.p` (`thl0220rp.txt`, `thl0220.LST`) e o ramo inbound para `thl0221`/`thl/thl0221rp.p`. O `tt-param` do agendador tem os mesmos 13 campos, na mesma ordem, do runner de reprocessamento, que filtra `dt-integracao = ?`. Os identificadores internos (`i-prgvrs.i`, `c-programa`) de cada runner agora batem com o arquivo.

### 8.2 Execução

Script com mapa por arquivo (necessário por causa da inversão). Troca byte a byte: tamanho e CRLF conferidos nos 7 fontes e nas 2 classes. Em `SchedulingService.cls`, o `run thl	hl1989z.p` virou `run thl/thl0220z.p` (barra no padrão do projeto). Nenhuma referência no front-end web. Backup em `scratchpad/backup-tarefas/`.

**Pendências:**

1. **Esvaziar a fila RPW antes de publicar:** pedidos `ped_exec` pendentes criados com `thl/thl1989rp.p` ou `thl/thl1991rp.p` não encontram mais o programa (e os `thl1989rp` pendentes rodariam o expurgo). Deixar a fila executar ou cancelar esses pedidos antes de trocar os `.r`.
2. Cadastrar no Datasul os programas `thl0220`, `thl0221` e `thl0222` (menu e programa RPW, porque `ped_exec.cod_prog_dtsul` usa esses códigos) e remover `thl1988`, `thl1989` e `thl1991`. Apagar os `.r` antigos.
3. Recompilar as telas, os `rp.p`, o `thl0220z.p`, `SchedulingService` e `InboundSchedulingService`.
4. Testar o agendamento outbound (forma de execução 2 = agendar): o pedido criado deve apontar para `thl/thl0220rp.p` e a mensagem deve ser enviada.
5. `Database	hl.df`: a descrição de `thl-objeto-parametro.cod-servid-exec` cita `thl1989z.p`. Atualizar pelo Data Dictionary.
6. ~~`thl0221.w` e `thl0222rp.p` estão em UTF-8~~ — **convertidos para ISO-8859-1 em 2026-09-25**.

> Atualização 2026-09-25: as pendências de "descrições do `Database\thl.df`" dos §6, §7 e §8 foram resolvidas. As 18 citações de programa passaram para a numeração nova e o trailer foi conferido.

> Novo 2026-09-25: **thl0210 / thl0210rp.p** — expurgo de e-mails (bloco 001x, mesmo `NN` do cadastro thl0010 e da consulta thl0110), gerado a partir do thl0222 com a chave `idx-data-envio` de `thl-email`.

> Novo 2026-09-25: **thl0250 / thl0250rp.p** — expurgo da auditoria (bloco 005x, mesmo `NN` do cadastro thl0050 e da consulta thl0150), gerado a partir do thl0210.

# Camada Datasul (`Fontes\thl\`)

> Nota criada em 2026-09-24 (lacuna L3 do diagnóstico). Telas `.w` (ADM/SmartObjects Datasul), programas RPW `.p`, endpoint REST e includes que consomem a `thl-lib`. As finalidades foram inferidas das tabelas que cada programa manipula.

## 1. Convenção de nomes

`thlNNNN.w` (tela principal, chamada pelo menu Datasul) + satélites `thlNNNN-b01.w` (browse), `-v01.w` (viewer), `-q01.w` (query), `-g01.w` (goto), `-z01.w` (zoom); telas filhas `thlNNNNa..h.w`; RPW `thlNNNNrp.p`; utilitário `thlNNNNz.p`. As telas ligam zoom/goto por atributos ADM (`ProgPesquisa`, `ProgVaPara`, `ProgIncMod`).

Numeração por faixa e assunto — `thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa (tela + RPW), mesmo `NN` do assunto: [convencoes.md §7](../convencoes.md). O padrão vigente é ISO-8859-1; a conversão dos templates CP850 é registrada em [convencoes.md §1](../convencoes.md). A revisão de 02/10/2026 não revalidou a codificação byte a byte.

## 2. Cadastros

Faixa `thl0xxx` exclusiva de cadastro, um bloco por dezena (renumerada em 2026-09-25 — DE-PARA em [adr/renumeracao-cadastros-depara.md](../adr/renumeracao-cadastros-depara.md)).

| Programa             | Nome Extenso  | Tabela principal                                                   | Finalidade                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------- | ------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| thl0001              | thl\thl0001.w | `thl-ambiente`                                                     | Ambientes de execução. Não elimina ambiente com variáveis de parâmetro (`local-delete-record`, 17006). API REST: [extensions/thl.md](../extensions/thl.md) (`/resourcen/ambiente`).                                                                                                                                                                                                                                                                                                                                                       |
| thl0002 (+a/b/c)     | thl\thl0002.w | `thl-ambiente-param`, `-variavel`, `-prog`                         | Parâmetros de ambiente, variáveis e programas vinculados. Na aba Variável (`thl0002b-v01`), `cod-ambiente` com zoom do thl0001 (F5/duplo clique) e nome do ambiente ao lado (`*` = todos os ambientes); validado no `Pi-validate` na inclusão (mensagem TOTVS 2, aceita `*`). Aba Programa (`thl0002-b02` → `thl0002c`): só incluir e eliminar (o registro só tem a chave). Não elimina parâmetro com variáveis ou programas (`local-delete-record`, 17006). API REST: `/resourcen/parametro-ambiente`, `parametro-variavel`, `parametro-programa` ([extensions/thl.md](../extensions/thl.md)). |
| thl0010              | thl\thl0010.w | `thl-email-param`                                                  | Parâmetros de envio de e-mail                                                                                                                                                                                                                                                                                                                                               |
| thl0011 (+a/b)       | thl\thl0011.w | `thl-ambiente-param-grupo`, `-grupo-usuar`                         | Grupos de e-mail e seus usuários. Zoom `-z01` (browse `-b02`) e vá para `-g01` criados em 2026-09-25 (`-b01` é o browse dos usuários). Usuário (`thl0011b-v01`) com zoom `fnzoom/z01fn017.w`. Não elimina grupo usado no thl0010 ou na notificação do thl0051 (`local-delete-record`, 17006). |
| thl0020              | thl\thl0020.w | `thl-aplicacao`                                                    | Aplicações (sistemas externos). `w-cadsim` gerado em 2026-09-25 a partir da família thl0021: q01, v01 (código só na inclusão, obrigatório e único), b01, z01, g01. Não elimina aplicação com objetos no thl0021 (`local-delete-record`, 17006). |
| thl0021              | thl\thl0021.w | `thl-objeto`                                                       | Objetos de integração. Campo `aplicacao` com zoom do thl0020 (F5/duplo clique) e validado no `Pi-validate` (mensagem TOTVS 2). Zoom `-z01` (browse `-b01`) mostra Aplicação e Objeto e devolve os dois (`aplicacao`, `objeto`). |
| thl0022 (+a/b)       | thl\thl0022.w | `thl-objeto-parametro`, `thl-objeto-usuario`                       | Parâmetros por operação/estabelecimento e usuários do objeto (usa query/zoom/vá para de thl0021). Aba Parâmetro (`thl0022a`): estabelecimento com zoom `adzoom/z01ad107.w`. Aba Usuário (`thl0022-b02` → `thl0022b`): só incluir e eliminar; `thl0022b-v01` refeito em 2026-09-25 no padrão do thl0051b (zoom `fnzoom/z01fn017.w`, nome do usuário ao lado, validação 2/17006). |
| thl0030              | thl\thl0030.w | `thl-conexao-rest`                                                 | Conexões REST (URI). Não elimina conexão com autenticação (thl0032) ou cabeçalho (thl0033) (`local-delete-record`, 17006). |
| thl0031              | thl\thl0031.w | `thl-conexao-rest-path`                                            | Paths/endpoints da conexão                                                                                                                                                                                                                                                                                                                                                  |
| thl0032              | thl\thl0032.w | `thl-conexao-rest-autenticacao`                                    | Autenticação (token). `cod-conexao` com zoom do thl0030 (F5/duplo clique). Mantém vá para/zoom próprios (`-g01`/`-z01`): os do thl0030 devolvem o ROWID de `thl-conexao-rest`, e a query reposiciona pela própria tabela. |
| thl0033              | thl\thl0033.w | `thl-conexao-rest-header`                                          | Header provider da conexão. `cod-conexao` com zoom do thl0030 (F5/duplo clique); vá para/zoom próprios, como no thl0032. |
| thl0040              | thl\thl0040.w | `thl-inbound-rota`                                                 | Rotas públicas inbound. `aplicacao` e `objeto` com zoom do thl0021 (F5/duplo clique em qualquer um preenche os dois), sem descrição ao lado. Validado no `Pi-validate` (mensagem TOTVS 2). |
| thl0050              | thl\thl0050.w | `thl-audit-tabela`                                                 | Tabelas auditadas. Não elimina tabela com campo, acesso, notificação ou expurgo no thl0051 (`local-delete-record`, 17006). |
| thl0051 (+b/c/d/e/h) | thl\thl0051.w | `thl-audit-tabela` → `-acesso`, `-campo`, `-notificacao`, `-purge` | Configuração de auditoria (acesso, campos, notificação, expurgo); usa query/zoom/vá para de thl0050. Acesso (`thl0051b`) com zoom de usuário `fnzoom/z01fn017.w`; notificação (`thl0051d`) com zoom de grupo do thl0011. |

Todos os cabeçalhos `i-prgvrs.i`/`ut9000.i` identificam o próprio arquivo (corrigidos na renumeração).

## 3. Monitores e consultas

Consultas na faixa `thl01NN`, com `NN` = final do cadastro relacionado (thl0110 ↔ Email thl0010, thl0120 = consulta do bloco 002x objeto de integração, thl0150 ↔ Tabela Auditoria thl0050) — renumeradas em 2026-09-25 (antes thl2000, thl1986, thl2020). Tarefas (tela de parâmetros + RPW) na faixa `thl02NN`: `thl0210` expurgo de e-mails (bloco 001x); `thl0250` expurgo da auditoria (bloco 005x); bloco 002x: `thl0220` reprocessamento outbound, `thl0221` inbound agendado, `thl0222` expurgo, `thl0220z.p` agendador (antes thl1988, thl1991, thl1989 e thl1989z.p). Na renumeração foi corrigido o agendador, cujo ramo outbound apontava para o runner de expurgo ([ADR §8](../adr/renumeracao-cadastros-depara.md)).

| Programa              | Tabelas                                                     | Finalidade                                                                                                                                                                                                                                                                                        |
| --------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| thl0120 (+a/b)        | `thl-mensagem`, `-item`, `-conteudo`, `thl-objeto`          | **Monitor de mensageria**: filtra mensagens, mostra conteúdo e **reenvia** (`dynamic-new tt-thl-mensagem.pacote + objeto` e `new OutboundMessageService(...)`). Descrições via includes `i01..i03thl011.i`. ⚠️ `RUN thl\thl0120h.w` aponta para tela apagada                                      |
| thl0110 (+a)          | `thl-email`                                                 | **Monitor de e-mail**                                                                                                                                                                                                                                                                             |
| thl0150 (+b)          | `thl-audit-registro`, `-detalhe`, `thl-audit-tabela-acesso` | Consulta de auditoria                                                                                                                                                                                                                                                                             |
| thl0210 / thl0210rp.p | `thl-email`                                                 | Parâmetros + RPW de **expurgo de e-mails**: faixa de programa (`cod-prog-dtsul`) e dias mantidos; percorre `idx-data-envio` programa a programa (igualdade no programa + intervalo em `data-envio`) e elimina os envios anteriores a hoje − dias (mínimo 1)                                       |
| thl0250 / thl0250rp.p | `thl-audit-tabela-purge` / `thl-audit-registro*`            | Parâmetros + RPW de **expurgo da auditoria**: seleção só pela faixa de `pk-purge` (banco, tabela); dias vêm de `retencao-dias` de cada tabela (0/branco = ignorada); elimina registro + detalhe + notificar por `idx-tabela-data`, grava `dt-ultima-execucao`; relatório só com resumo por tabela. ⚠️ Em 2026-10-02 o fonte compara `thl-audit-registro.banco` **sem** o prefixo `sh` (linha 130) e grava `dt-ultima-execucao` em registro `no-lock` (linha 149): pela leitura, não apaga nada — ver [auditoria.md](../logging/auditoria.md) |
| thl0220 / thl0220rp.p | `thl-objeto` / `thl-mensagem`                               | Parâmetros + RPW de **reprocessamento outbound** (`OutboundMessageService:reprocess( codigo-mensagem )`)                                                                                                                                                                                          |
| thl0221 / thl0221rp.p | `thl-objeto` / `thl-mensagem`                               | Parâmetros + RPW de **processamento inbound agendado** (`InboundMessageService:processScheduled( codigo-mensagem )`)                                                                                                                                                                              |
| thl0222 / thl0222rp.p | `thl-objeto` / `thl-mensagem*`                              | Parâmetros + RPW de **expurgo** (percorre mensagem, conteúdo, histórico, item e ped-exec, com `delete`)                                                                                                                                                                                           |

## 4. Programas chamados pela `thl-lib`

| Programa | Chamado por | Função |
|---|---|---|
| `thl0220z.p` | `SchedulingService` e `InboundSchedulingService` (`run thl/thl0220z.p`) | Recebe `codigo-mensagem`, cria o pedido de execução RPW (`ped_exec`, `ped_exec_param`) e `thl-mensagem-ped-exec`; devolve `num-ped-exec`. Runner por `sentido-fluxo`: outbound → `thl/thl0220rp.p`, inbound → `thl/thl0221rp.p` |
| `api/geterpuser.p` | `ContextService:getErpUser()` (`run thl/api/geterpuser.p`) | Ponte para a variável `NEW GLOBAL SHARED c-seg-usuario` |

Essas chamadas criam dependência da `thl-lib` para a camada Datasul (diagnóstico, Etapa 2 §5).

## 5. Endpoint REST

`integration\api\v1\resourcen.p` — procedure `piPrincipal` registrada via `utp/ut-api-action.i` para POST/PATCH/PUT/GET/DELETE nas rotas `/*/*` e `/*/*/*`. Monta o `InboundObjectContext`, resolve a rota com `InboundRouteResolver` e chama `InboundMessageService:receive`. Fluxo completo em `integration/messaging-inbound.md`. URL usada pelo app web: `/api/thl/integration/v1/resourcen/<rota>`.

## 6. Includes

| Include | Conteúdo |
|---|---|
| `include\i01thl011.i` | Situação: 1=Pendente, 2=Erro, 3=Sucesso, 4=Não aplicável |
| `include\i02thl011.i` | Método: 1=POST … 5=GET, 6=INSERT, 7=UPDATE, 8=SELECT, 99=Não aplicável |
| `include\i03thl011.i` | Modelo de integração: 1=Rest, 2=Soap ("Saop"), 3=Database, 4=File |
| `include\i04thl011.i` | Forma de execução: 1=Online, 2=Agendar, 3=Batch — sem referência no código (o cabeçalho diz `i03thl011.i`) |
| `include\i01thl026.i` | Situação 1=Normal, 5=Crítico, 9=Restrito — sem referência no código |
| `include\ninc\i01nit026.i` | Tipos Normal/Complementar/Redespacho/Serviço — sem referência no código; prefixo `nit` |

## Observações

- Caminhos com `\` (`thl\thlNNNN…`) em 33 atributos/`RUN` — não portáveis para Linux.
- Órfãos prováveis (sem referência): `thl0022a-q01`, `thl0120b-v01/v02`, `thl0051h` (ver diagnóstico, Etapa 2 §4.3).
- A codificação obrigatória é ISO-8859-1; CP850 aparece apenas como origem histórica dos templates. Ver [convencoes.md §1](../convencoes.md).

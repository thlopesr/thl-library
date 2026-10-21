---
tipo: modulo
camada: ambos
status: vigente
tags: [datasul, telas, rpw]
updated: 2026-10-21
---

# Camada Datasul (`Fontes\thl\`)

> Nota criada em 2026-09-24 (lacuna L3 do diagnóstico). Telas `.w` (ADM/SmartObjects Datasul), programas RPW `.p`, endpoint REST e includes que consomem a `thl-lib`. As finalidades foram inferidas das tabelas que cada programa manipula.

## 1. Convenção de nomes

`thlNNNN.w` (tela principal, chamada pelo menu Datasul) + satélites `thlNNNN-b01.w` (browse), `-v01.w` (viewer), `-q01.w` (query), `-g01.w` (goto), `-z01.w` (zoom); telas filhas `thlNNNNa..h.w`; RPW `thlNNNNrp.p`; utilitário `thlNNNNz.p`. As telas ligam zoom/goto por atributos ADM (`ProgPesquisa`, `ProgVaPara`, `ProgIncMod`).

Numeração por faixa e assunto — `thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa (tela + RPW), mesmo `NN` do assunto: [convencoes.md §7](../convencoes.md). O padrão vigente é ISO-8859-1; a conversão dos templates CP850 é registrada em [convencoes.md §1](../convencoes.md). A revisão de 02/10/2026 não revalidou a codificação byte a byte.

## 2. Cadastros

Faixa `thl0xxx` exclusiva de cadastro, um bloco por dezena (renumerada em 2026-09-25 — DE-PARA em [adr/renumeracao-cadastros-depara.md](../adr/renumeracao-cadastros-depara.md)).

| Programa             | Nome Extenso  | Tabela principal                                                   | Finalidade                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------- | ------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| thl0001              | thl\thl0001.w | `thl-ambiente`                                                     | Ambientes de execução. Eliminar o ambiente elimina também as variáveis de parâmetro dele (`local-delete-record`, cascata na mesma transação). API REST: [extensions/thl.md](../extensions/thl.md) (`/resourcen/ambiente`).                                                                                                                                                                                                                                                                                                                                                       |
| thl0002 (+a/b/c)     | thl\thl0002.w | `thl-ambiente-param`, `-variavel`, `-prog`                         | Parâmetros de ambiente, variáveis e programas vinculados. Na aba Variável (`thl0002b-v01`), `cod-ambiente` com zoom do thl0001 (F5/duplo clique) e nome do ambiente ao lado (`*` = todos os ambientes); validado no `Pi-validate` na inclusão (mensagem TOTVS 2, aceita `*`). Aba Programa (`thl0002-b02` → `thl0002c`): só incluir e eliminar (o registro só tem a chave). Não elimina parâmetro com variáveis ou programas (`local-delete-record`, 17006). API REST: `/resourcen/parametro-ambiente`, `parametro-variavel`, `parametro-programa` ([extensions/thl.md](../extensions/thl.md)). |
| thl0010              | thl\thl0010.w | `thl-email-param`                                                  | Parâmetros de envio de e-mail                                                                                                                                                                                                                                                                                                                                               |
| thl0011 (+a/b)       | thl\thl0011.w | `thl-ambiente-param-grupo`, `-grupo-usuar`                         | Grupos de e-mail e seus usuários. Zoom `-z01` (browse `-b02`) e vá para `-g01` criados em 2026-09-25 (`-b01` é o browse dos usuários). Usuário (`thl0011b-v01`) com zoom `fnzoom/z01fn017.w`. Não elimina grupo usado no thl0010 ou na notificação do thl0051 (`local-delete-record`, 17006); sem esses vínculos, elimina junto os usuários do grupo. |
| thl0020              | thl\thl0020.w | `thl-aplicacao`                                                    | Aplicações (sistemas externos). `w-cadsim` gerado em 2026-09-25 a partir da família thl0021: q01, v01 (código só na inclusão, obrigatório e único), b01, z01, g01. Não elimina aplicação com objetos no thl0021 (`local-delete-record`, 17006). |
| thl0021              | thl\thl0021.w | `thl-objeto`                                                       | Objetos de integração. Campo `aplicacao` com zoom do thl0020 (F5/duplo clique) e validado no `Pi-validate` (mensagem TOTVS 2). Zoom `-z01` (browse `-b01`) mostra Aplicação e Objeto, filtra por faixa de **aplicação** e de **objeto** (13/10/2026) e devolve os dois (`aplicacao`, `objeto`). Vá para `-g01` pede aplicação **e** objeto (chave `pk-objeto`). Eliminar o objeto elimina também operações (`thl-objeto-parametro` e a extensão REST), usuários e rota (`local-delete-record`, cascata); `thl-mensagem` não é tocada. |
| thl0022 (+a/b)       | thl\thl0022.w | `thl-objeto-parametro`, `thl-objeto-usuario`                       | Parâmetros por operação/estabelecimento e usuários do objeto (usa query/zoom/vá para de thl0021). Aba Parâmetro (`thl0022a`): estabelecimento com zoom `adzoom/z01ad107.w`. Aba Usuário (`thl0022-b02` → `thl0022b`): só incluir e eliminar; `thl0022b-v01` refeito em 2026-09-25 no padrão do thl0051b (zoom `fnzoom/z01fn017.w`, nome do usuário ao lado, validação 2/17006). |
| thl0030              | thl\thl0030.w | `thl-conexao-rest`                                                 | Conexões REST (URI). Eliminar a conexão elimina também a autenticação (thl0032) e os cabeçalhos (thl0033) dela (`local-delete-record`, cascata). |
| thl0031              | thl\thl0031.w | `thl-conexao-rest-path`                                            | Paths/endpoints da conexão                                                                                                                                                                                                                                                                                                                                                  |
| thl0032              | thl\thl0032.w | `thl-conexao-rest-autenticacao`                                    | Autenticação (token). `cod-conexao` com zoom do thl0030 (F5/duplo clique). Mantém vá para/zoom próprios (`-g01`/`-z01`): os do thl0030 devolvem o ROWID de `thl-conexao-rest`, e a query reposiciona pela própria tabela. |
| thl0033              | thl\thl0033.w | `thl-conexao-rest-header`                                          | Header provider da conexão. `cod-conexao` com zoom do thl0030 (F5/duplo clique); vá para/zoom próprios, como no thl0032. |
| thl0040              | thl\thl0040.w | `thl-objeto-rota`                                                  | Rota do objeto (uma por objeto; antes `thl-inbound-rota`, ver [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §9). `aplicacao` e `objeto` com zoom do thl0021 (F5/duplo clique em qualquer um preenche os dois), sem descrição ao lado. Validado no `Pi-validate` (mensagem TOTVS 2). Zoom `-z01` filtra por faixa de aplicação e de objeto (13/10/2026). |
| thl0050              | thl\thl0050.w | `thl-audit-tabela`                                                 | Tabelas auditadas. Eliminar a tabela elimina também campo, acesso, notificação e expurgo dela no thl0051 (`local-delete-record`, cascata). Zoom `-z01` filtra por faixa de banco e de tabela (13/10/2026). |
| thl0051 (+b/c/d/e/h) | thl\thl0051.w | `thl-audit-tabela` → `-acesso`, `-campo`, `-notificacao`, `-purge` | Configuração de auditoria (acesso, campos, notificação, expurgo); usa query/zoom/vá para de thl0050. Acesso (`thl0051b`) com zoom de usuário `fnzoom/z01fn017.w`; notificação (`thl0051d`) com zoom de grupo do thl0011. Campo (`thl0051c`): viewer com o tamanho do `thl0051b-v01` (os botões ficavam cobertos) e nível de sensibilidade em COMBO-BOX (1 Normal, 5 Critico, 9 Restrito), como nos thl0050/thl0051b/thl0051d. |

Todos os cabeçalhos `i-prgvrs.i`/`ut9000.i` identificam o próprio arquivo (corrigidos na renumeração).

## 3. Monitores e consultas

Consultas na faixa `thl01NN`, com `NN` = final do cadastro relacionado (thl0110 ↔ Email thl0010, thl0120 = consulta do bloco 002x objeto de integração, thl0150 ↔ Tabela Auditoria thl0050) — renumeradas em 2026-09-25 (antes thl2000, thl1986, thl2020). Tarefas (tela de parâmetros + RPW) na faixa `thl02NN`: `thl0210` expurgo de e-mails (bloco 001x); `thl0250` expurgo da auditoria (bloco 005x); bloco 002x: `thl0220` reprocessamento outbound, `thl0221` inbound agendado, `thl0222` expurgo, `thl0220z.p` agendador (antes thl1988, thl1991, thl1989 e thl1989z.p). Na renumeração foi corrigido o agendador, cujo ramo outbound apontava para o runner de expurgo ([ADR §8](../adr/renumeracao-cadastros-depara.md)).

| Programa              | Tabelas                                                     | Finalidade                                                                                                                                                                                                                                                                                        |
| --------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| thl0120 (+a/b/c)      | `thl-mensagem`, `-item`, `-conteudo`, `thl-objeto`          | **Monitor de mensageria**: filtra mensagens, mostra conteúdo e **reenvia** (`dynamic-new tt-thl-mensagem.pacote + objeto` e `new OutboundMessageService(...)`). Descrições via includes `i01..i03thl011.i`. ⚠️ `RUN thl\thl0120h.w` aponta para tela apagada; `thl0120c.w` (janela de detalhe, 2026-10-13): recebe o conteúdo da mensagem (`longchar`, parâmetro `conteudo`) e o mostra no editor `ed-conteudo`; aberta pelo botão **Detalhar** de `thl0120b.w` (`copy-lob tt-conteudo.conteudo`, `run thl\thl0120c.w ( conteudo )`). ⚠️ O cabeçalho do `thl0120c.w` mantém o placeholder do template (`i-prgvrs.i XX9999 9.99.99.999` e `ut9000.i "XX9999"`) e o `run` do `thl0120b.w` usa `\` no caminho: fora da convenção (§7 de `convencoes.md`); só registrado, não corrigido. Não compilado                                      |
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

## 5.1 Módulo no menu Datasul

Os programas estão cadastrados no módulo **TOTVS Helper Library**, no menu **Foundation** (informado pelo usuário em 2026-10-21, com capturas do menu; conferido só nas imagens, não no cadastro do Datasul). A tela do módulo agrupa por abas — **Tarefas** (5: `thl0210`, `thl0220`, `thl0221`, `thl0222`, `thl0250`), **Relatórios** (0), **Consultas** (4) e **Cadastros** (15). Os mesmos recursos de consulta e cadastro existem em PO UI, nos apps `web` (Consulta Geral: métricas gerais, de mensageria, de e-mail e de auditoria) e `cadastro` (Painel de Cadastros), descritos em [web/app-web.md](../web/app-web.md). Rascunho do comunicado aos usuários: [relatorios/comunicado-programas-thl.md](../../relatorios/comunicado-programas-thl.md).

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

## Alterações de 2026-10-03 (não compiladas; dependem do delta `Database\delta-thl-2026-10-03.df`)

Decisões em [adr/metricas-conteudo-expurgo-mensagens.md](../adr/metricas-conteudo-expurgo-mensagens.md).

| Programa | Mudança |
|---|---|
| `thl0020-v01.w` | Campo **Interna** (`thl-aplicacao.ind-interna`, toggle) na linha da descrição; a descrição passou de 70 para 50 colunas para caber |
| `thl0021-v01.w` | Campos **Ret. Sucesso** e **Ret. Erro** (`thl-objeto.retencao-dias-sucesso` / `-erro`) no bloco inferior; `Pi-validate` recusa valor negativo (17006) |
| `thl0022a-v03.w` | **Grava Conteúdo** (`thl-objeto-parametro.tipo-grava-conteudo`, radio-set vertical: Sempre, Somente em Erro, Nunca) à direita dos campos de persistência |
| `thl0222.w` | O campo "Manter Dias" continua definido (e na `tt-param`), mas é escondido na abertura da tela: a retenção vem do objeto |
| `thl0222rp.p` | Reescrito do laço principal em diante — ver abaixo |
| `thl\include\i05thl011.i` | Domínio de `tipo-grava-conteudo` (novo) |

**Expurgo de mensagens (`thl0222rp.p`):**

- Percorre `thl-objeto` na faixa de objetos da tela e, para cada um, elimina as mensagens por situação geral: `sit-mensagem` = 3 com mais de `retencao-dias-sucesso` dias; 2 e 1 com mais de `retencao-dias-erro` dias. Zero ou vazio = não expurga aquela situação.
- Corte por **data de criação** (`dt-criacao` < meia-noite de hoje − dias), pelo índice `idx-objeto-situacao`. Antes era por `dt-integracao` e pelo "Manter Dias" da tela — mensagem pendente (sem data de integração) nunca era eliminada; agora sai pelo prazo de erro.
- Uma transação por mensagem (com conteúdo, histórico, itens e pedido de execução), como antes.
- A faixa de código de mensagem da tela continua valendo.
- O relatório passou a trazer o **resumo por objeto** (prazos e quantidades eliminadas) e o total, em vez de uma linha por mensagem.
- Mensagem de objeto que não existe mais em `thl-objeto` não é alcançada pelo expurgo.
- ⚠️ Mensagens anteriores ao campo ficam com `sit-mensagem` = 1 até rodar `Utils\scripts\acerto-thl-sit-mensagem.p`; enquanto isso seguem o prazo de erro.
- ⚠️ Os objetos já cadastrados recebem os iniciais 21/42 ao carregar o delta: revisar os que precisam de histórico maior antes do primeiro expurgo.

**Telas — pontos a conferir no AppBuilder:** as posições foram escolhidas por leitura do layout, sem abrir a tela. Conferir sobreposição de rótulos em `thl0021-v01.w` (linha dos combos) e o espaço do radio-set em `thl0022a-v03.w`.

## thl0021 — classes de processor e service (2026-10-04, não compilado; depende do delta `delta-thl-2026-10-04.df`)

- `thl0021-v01.w`: campos **Processor** (`thl-objeto.classe-processor`) e **Service** (`thl-objeto.classe-service`) logo abaixo da classe da message. O bloco do meio ganhou duas linhas (retângulo de 2.25 para 4.25), o bloco inferior desceu duas linhas e a altura do viewer foi de 7.25 para 9.25.
- `thl0021.w`: frame e janela duas linhas mais altos (frame 9.92 → 11.92; janela 9.29 → 11.29), para o viewer caber.
- `Pi-validate`: classe processor obrigatória; classe service obrigatória quando o sentido é **Entrada** (17006). A classe da message já era obrigatória.
- Layout definido por leitura — conferir no AppBuilder.

## thl0021 — classes lidas em execução (2026-10-04)

Os campos **Classe**, **Processor** e **Service** do `thl0021` passaram a ser lidos pelo `InboundConfigLoader`: objeto de entrada com qualquer um em branco é recusado na chamada. Valores iniciais do banco: `…inbound.core.InboundMessage` e `thl-lib.integration.messaging.inbound.core.Processor`; o Service é digitado. Ver [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

## thl0022a — ação, classes da operação e aba REST (2026-10-05, não compilado; depende do delta `delta-thl-2026-10-05.df`)

| Arquivo | Mudança |
|---|---|
| `thl0022a-v01.w` | **Ação** (`thl-objeto-parametro.acao`, combo) na chave, abaixo da operação; chave ganhou uma linha e o resto desceu (altura 6.25 → 7.25). `Pi-validate`: ação obrigatória (17006) e duplicidade pela chave com a ação. `local-assign-record`: cria a extensão REST junto, quando o objeto é REST. Novo `local-delete-record`: elimina a extensão com a operação |
| `thl0022a-v02.w` | O método saiu daqui (foi para a aba REST); altura 4.25 → 3.25 |
| `thl0022a-v04.w` | Classes só da operação (message, processor, service), abaixo do servidor; altura 1.25 → 6.5 |
| `thl0022a-v05.w` (novo) | Aba **REST**: método (campo da operação, copiado para a extensão), campos obrigatórios e chave externa (campos de tela gravados na extensão em `local-assign-record`, exibidos em `local-display-fields`). `Pi-validate` confere os dois arrays JSON com `JsonUtil:nameListToCsv` (17006) |
| `thl0022a.w` | Pasta com a quinta página (`REST`), viewer ligado por `Record` e `Group-Assign` como os demais |
| `include\i06thl011.i` (novo) | Domínio da ação: Criar, Alterar, Eliminar, Consultar |

- Layout definido por leitura — conferir no AppBuilder, em especial a largura dos rótulos e o rótulo da pasta.
- ⚠️ A aba REST só grava a extensão se tiver sido aberta (páginas são criadas sob demanda). Sem abrir, a extensão nasce só com a chave e o verbo vale o da operação.
- ⚠️ O viewer da aba REST lê a chave pelo próprio buffer no `Group-Assign`; confirmar na inclusão se a ação já está disponível nesse ponto.
- `thl0220z.p` não mudou: procura a operação por `find first` sem a ação.

## thl0040 — início da operação (2026-10-06, não compilado; depende do delta `delta-thl-2026-10-06.df`)

`thl0040-v01.w`: campo `thl-objeto-rota.inicio-operacao` (na época ainda `thl-inbound-rota`) na mesma linha do Ativo (coluna 60). `Pi-validate`: 0, ou entre 2 e a quantidade de segmentos da rota pública (17006). A mesma regra está no `ObjetoRotaService` (antes `InboundRotaService`; propriedade `inicioOperacao`). Posição do campo definida por leitura — conferir no AppBuilder.

## thl0040 — rota do objeto (2026-10-06, não compilado; a tabela está em `Database\Definition\thl.df`)

A tela passou a manter `thl-objeto-rota`, com a chave aplicação + objeto.

| Arquivo | Mudança |
|---|---|
| `thl0040-v01.w` | Chave = aplicação e objeto (só na inclusão, com o zoom de objeto que já existia); rota pública, ativa e início da operação abaixo. Saíram código e descrição. `Pi-validate`: objeto que já tem rota e rota pública repetida (17006). Altura 6.75 → 5.75 |
| `thl0040-b01.w` | Colunas aplicação, objeto, rota pública e ativa; filtro por faixa de aplicação |
| `thl0040-g01.w` | Vá-para com aplicação e objeto |
| `thl0040-q01.w` | Só a tabela e a chave |

`thl0040.w` e `thl0040-z01.w` não citam a tabela e não mudaram. Layout definido por leitura — conferir no AppBuilder.

## thl0022a — um campo só para o método (2026-10-07, não compilado)

- `thl0022a-v01.w`: o campo da chave (`thl-objeto-parametro.acao`) aparece como **Método**, com a lista pelo tipo do objeto (`pi-atualiza-parent`: REST = Post, Put, Patch, Delete, Get; Banco = Insert, Update, Select). `local-assign-record` copia o valor para a coluna antiga `metodo`.
- `thl0022a-v05.w` (aba REST): saiu o Método; entrou **Mensagem Simples** (veio da aba Conexão), porque o viewer precisa de ao menos um campo da tabela; continuam campos obrigatórios e chave externa.
- `thl0022a-v02.w` (aba Conexão): ficou com os dois parâmetros de ambiente; altura 3.25 → 2.25.
- `include\i06thl011.i`: domínio com os métodos.

## thl0022a — aba Classe (2026-10-07, não compilado)

Novo `thl0022a-v06.w`: aba **Classe**, com as três classes só da operação (message, processor, service; em branco vale a do objeto). A aba Servidor (`thl0022a-v04.w`) voltou a ter só o servidor de execução. `thl0022a.w`: sexta página na pasta (`Principal|Conexao|Persistencia|Servidor|REST|Classe`), viewer ligado por `Record` e `Group-Assign` como os demais. Layout por leitura — conferir no AppBuilder se os seis rótulos cabem na largura da pasta.

## thl0022a — método na chave (2026-10-08, não compilado; depende do delta de 2026-10-08)

`thl0022a-v01.w`: o campo da chave passou de `thl-objeto-parametro.acao` para `thl-objeto-parametro.metodo` (listas de campos, frame, `pi-atualiza-parent`, `Pi-validate`, criação e exclusão da extensão REST); saiu a cópia para a coluna antiga. `thl0022a-v05.w`: a extensão é lida e criada pela chave com `metodo`. `include\i06thl011.i` segue como o domínio do campo.

## thl0002 — exclusão em cascata e zoom por programa (2026-10-08, não compilado)

- **Eliminar o parâmetro** (`thl0002-v01.w`, `local-delete-record`) elimina também as variáveis (`thl-ambiente-param-variavel`, thl0002b) e os programas (`thl-ambiente-param-prog`, thl0002c) dele, na mesma transação do ADM; antes a exclusão era **bloqueada** quando havia filhos. A API (`ParametroAmbienteService:delete`) segue a mesma regra.
- **Zoom** (`thl0002-z01.w`): ganhou a aba **Programa**, ao lado de Parametro. O browse novo `thl0002-b04.w` lista `thl-ambiente-param-prog` (programa, parâmetro e descrição do parâmetro), com filtro por faixa de programa (`cod-prog-dtsul`), e devolve o **pai**: a linha manda o `rowid` de `thl-ambiente-param` (segunda tabela da query) como `New-Line`, que é o que a consulta do thl0002 reposiciona. Um parâmetro com vários programas aparece uma vez por programa.
- Layout por leitura, sem AppBuilder: conferir as duas abas do zoom e a largura das colunas.

## Exclusão em cascata nos cadastros pai (2026-10-08, não compilado)

Mesma regra do thl0002, aplicada às demais telas com tabela filha: o `local-delete-record` guarda a chave do pai, abre `do transaction`, despacha o `delete-record` e elimina os filhos subordinados (`for each … exclusive-lock … delete`); erro em qualquer passo desfaz tudo.

| Tela | Elimina junto | Continua bloqueando |
|---|---|---|
| `thl0001-v01.w` | variáveis de parâmetro (`thl-ambiente-param-variavel`) | — |
| `thl0011-v01.w` | usuários do grupo (`thl-ambiente-param-grupo-usuar`) | grupo usado em `thl-email-param` ou `thl-audit-tabela-notificacao` (referência de outra tabela) |
| `thl0021-v01.w` (procedimento novo) | `thl-objeto-parametro-rest`, `thl-objeto-parametro`, `thl-objeto-usuario`, `thl-objeto-rota` | — (`thl-mensagem` fica) |
| `thl0030-v01.w` | `thl-conexao-rest-autenticacao`, `thl-conexao-rest-header` | — |
| `thl0050-v01.w` | `thl-audit-tabela-campo`, `-acesso`, `-notificacao`, `-purge` | — |
| `thl0020-v01.w` | — | aplicação com objetos: **mantido bloqueado** (levaria objetos de integração inteiros) |

As APIs (`AmbienteService`, `GrupoEmailService`, `ObjetoService`, `ConexaoRestService`, `AuditoriaTabelaService`) seguem a mesma regra no `delete()`, dentro de `do transaction`.

## thl0040 — chave tripla (2026-10-13, não compilado; depende do `delta-thl-2026-10-13.df`)

- `thl0040-v01.w`: a **rota pública** passou para a chave (`ADM-CREATE-FIELDS` e `ADM-ASSIGN-FIELDS`, fora de `ENABLED-FIELDS`): só na inclusão. `Pi-validate`: no lugar de "o objeto já tem rota", recusa a **mesma rota no mesmo objeto** (17006, "O objeto já tem esta rota"); a regra "rota pública já usada por outro objeto" continua.
- `thl0040-g01.w`: o vá-para usa `FIND FIRST` (aplicação + objeto) e vai para a primeira rota do objeto.
- `thl0040-b01`, `-q01`, `-z01`: sem mudança (a ordem padrão passa a ser a da nova chave).
- Cascata do `thl0021` (eliminar objeto) já eliminava todas as rotas do objeto (`for each`).

## thl0110, thl0120 e thl0150 — filtro de data e hora (2026-10-13, não compilado)

Alinha as telas de consulta ao filtro da API (`yyyy-MM-ddTHH:mm`, padrão últimas 24 horas).

| Arquivo | Mudança |
|---|---|
| `thl0110a.w` (filtro de e-mail) | `fi-data-envio-ini/-fin`: `DATE` → `DATETIME` (`99/99/9999 HH:MM:SS`), largura 12.57 → 21; o `screen-value` inicial usa `string( valor, "99/99/9999 HH:MM:SS" )` |
| `thl0120a.w` (filtro de mensageria) | os quatro campos de data (`fi-data-criacao-*`, `fi-data-integracao-*`): `DATE` → `DATETIME`, largura 15 → 21; mesmo `string( valor, formato )` |
| `thl0150b.w` (filtro de auditoria) | `fi-dat-criacao-ini/-fin`: `DATE` → `DATETIME`, largura 12.57 → 21; mesmo `string( valor, formato )` |
| `thl0110.w` | padrão `data-envio-ini/-fin`: de `add-interval( now, -24, 'hours' )` até **amanhã** (`today + 1`; antes hoje − 1 a hoje + 1) |
| `thl0120.w` | padrão de `dt-criacao-*` e `dt-integracao-*`: de 24 horas atrás até **amanhã** (antes hoje − 3 a hoje + 1) |
| `thl0150.w` | padrão de `dat-criacao-*`: de 24 horas atrás até **amanhã** (antes hoje − 2 a hoje, que deixava de fora o dia corrente) |

O fim do padrão é amanhã (não `now`): `now` é fixado quando a tela abre e deixava de fora mensagem criada depois, ou gravada pelo PASOE com horário à frente do desta sessão (corrigido em 2026-10-14). Antes o filtro era `DATE` e só cortava por dia (a hora ficava 00:00); agora a hora entra na faixa. As variáveis compartilhadas já eram `datetime` (`like` do campo), então as consultas (`>=`/`<=`) não mudaram. Layout por leitura, sem AppBuilder: conferir as larguras e a sobreposição dos campos "até" nas três janelas. Os `.r` precisam ser recompilados.

## thl0021 e thl0022 — classes por sentido do fluxo (2026-10-15, não compilado)

**Regra:** objeto de **saída** tem só a classe da mensagem (habilitada e obrigatória); objeto de **entrada** tem mensagem, processor e service, todas obrigatórias. A operação (thl0022) nasce com as classes do objeto (thl0021) e segue a mesma regra, pelo sentido do objeto pai.

| Arquivo | Mudança |
|---|---|
| `thl0021-v01.w` | `pi-habilita-classes`: saída deixa só `classe-objeto` habilitada; entrada habilita as três (na abertura da edição e ao trocar o sentido). `pi-padroes-classes` (na inclusão): mostra no começo os valores padrão do thl0002, lidos por `new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:... )` (`using thl-lib.core.environment.EnvironmentResource` e `thl-extensions.erp.thl.enum.ClassVariableEnum`, como a `thl0050-v01.w` faz com o `SchemaUtil`), o mesmo dos Services da API; o parâmetro `thl.classe` é achado pelo programa vinculado na aba Programa do thl0002. `Pi-validate`: processor e service só são exigidos na entrada (antes o processor era sempre exigido). Valores já gravados nos campos desabilitados não são apagados |
| `thl0022a-v06.w` (aba Classe) | Na inclusão mostra no começo as classes do objeto (antes só copiava ao gravar); a classe que o objeto não tem recebe o padrão do thl0002 por `EnvironmentResource` e `ClassVariableEnum`, e o mesmo fallback vale na cópia ao gravar. Mesma habilitação e mesmo `Pi-validate` (antes não validava nada). Buffer próprio `b-objeto-classe` para o objeto; sem operação cadastrada, o objeto vem da viewer principal por `Group-Assign` |
| `thl0022a-v03.w` (aba Persistência) | `pi-habilita-persistencia`: operação de **entrada** deixa `persistente`, `frequência`, `dias` e `tentativas` desabilitados; **saída** habilita. Log da requisição, log do retorno e Grava Conteúdo valem nos dois sentidos. Esses quatro campos de persistência ainda **não são lidos por nenhum código de execução** (só cadastro e API). Mesmo `pi-acha-objeto` das outras abas (`b-objeto-sentido`, `Group-Assign`); não apaga valor gravado |
| `thl0022a-v04.w` (aba Servidor) | `pi-habilita-servidor`: o servidor de execução (`cod-servid-exec`) só fica habilitado quando a forma de execução não é Online (Batch ou Agendar). A forma vem da tela da `thl0022a-v01.w` (`pi-devolve-forma`, mesmo antes de gravar); a v01 avisa a aba ao mudar a forma (`pi-notifica-forma`). Não apaga valor. O `Pi-validate` recusa (17006) servidor preenchido com forma Online (`pi-acha-forma`). A API recusa `servidorExecucao` preenchido em operação Online (`formaExecucao` 1), erro 17006 |
| `thl0022a-v05.w` (aba REST) | `pi-habilita-contrato`: operação de **saída** deixa `campos obrigatórios` e `chave externa` desabilitados (só a entrada lê o contrato do payload, em `InboundConfigLoader:setContract`); entrada habilita. Mesmo `pi-acha-objeto` da aba Classe (buffer `b-objeto-sentido`, `Group-Assign`). Não apaga valor já gravado; `ind-mensagem-simples` continua habilitado nos dois sentidos |
| `thl0022a-v01.w` | Novo `pi-devolve-parent` (rowid do objeto), usado pela aba Classe. Ao gravar, classe ainda em branco depois de copiar do objeto recebe o padrão do thl0002 (`EnvironmentResource` e `ClassVariableEnum`, `using` no topo; processor e service só na entrada), como `ObjetoParametroService` |

**Valores padrão no thl0002 (parâmetro `thl.classe`, ambiente `*`):** variáveis `mensagem.entrada` (ex.: `thl-lib.integration.messaging.inbound.core.InboundMessage`), `mensagem.saida`, `processor.entrada` (ex.: `thl-lib.integration.messaging.inbound.core.Processor`) e `service.entrada`. Parâmetro ou variável ausente: o campo fica em branco, sem valor fixo no código. Carga pronta em `Database\Data\OpenEdge\carga-thl-classe\`: `thl002.d` (o parâmetro), `thl003.d` (os programas que o enxergam: `ObjetoService`, `ObjetoParametroService`, `thl0021-v01`, `thl0022a-v01` e `thl0022a-v06`) e `thl005.d` (as quatro variáveis, com `mensagem.entrada` e `processor.entrada` preenchidas e `mensagem.saida` e `service.entrada` em branco); carregar `thl002` antes de `thl003` e `thl005`. **O vínculo programa → parâmetro é obrigatório**: o `EnvironmentResource` sem argumento acha o parâmetro pelo programa na pilha de chamadas e, sem vínculo, lança erro; nas telas e nos Services a chamada usa `no-error` e o campo fica em branco. Só o thl0021 usa o padrão; o thl0022 usa o que está no objeto.

Pontos a conferir depois de compilar: a aba Classe numa inclusão sem nenhuma operação anterior (depende do `get-link-handle` do `Group-Assign`, não testado), e a troca do sentido na inclusão do objeto. As APIs `ObjetoService` e `ObjetoParametroService` aplicam a mesma regra.

## Seleção por aplicação, objeto, operação e método nos RPW (2026-10-21, não compilado)

`thl0220`, `thl0221` e `thl0222` (telas e `rp`) filtravam só por faixa de código da mensagem e de objeto (combo-box, que listava os objetos do usuário em `thl-objeto-usuario`). Passam a filtrar pela chave completa, em faixas De/Até: **aplicação**, **objeto** (agora fill-in), **operação** e **método** (`thl-mensagem.metodo`; não existe campo `acao` no banco), este em combo-box De/Até com as opções `N - Descrição` (0 Nao informado, 1 Post, 2 Put, 3 Patch, 4 Delete, 5 Get, 6 Insert, 7 Update, 8 Select), valor inteiro, de 0 a 8 por padrão. A `tt-param` ganhou `aplicacao-ini/fin`, `operacao-ini/fin` e `metodo-ini/fin`, na mesma ordem nas telas, nos `rp` e no `thl0220z.p` (o `raw-transfer` depende da ordem). Padrões das telas: texto de `""` a `ZZZ…`.

- `thl0220rp.p` e `thl0221rp.p`: `where` com aplicação, objeto, operação e método (índice `idx-objeto-parametro` cobre aplicação+objeto+operação).
- `thl0222rp.p`: o laço de `thl-objeto` filtra a aplicação; `pi-expurgar` filtra operação e método. A retenção continua por objeto.
- `thl0220z.p` (agendador): grava na `tt-param` a chave exata da mensagem (aplicação, objeto, operação e método) além do código; passou a lançar `ThlError` quando a mensagem não existe (antes dava erro 91 em `thl-mensagem.objeto`). `SchedulingService` e `InboundSchedulingService` não mudam: só passam o código.
- A lista de objetos do combo era restrita aos objetos do usuário (`thl-objeto-usuario`, ativos e do sentido da tela). Com fill-in não há mais essa restrição: quem executa a tela pode informar qualquer objeto. **Decisão (2026-10-21): aceita assim, sem validar permissão.**

## Padrões dos campos no thl0002 e correção do thl0220z (2026-10-15, não compilado)

**Campos com padrão parametrizável.** Além das classes, os campos que têm valor inicial no banco passam a poder ser parametrizados no thl0002, no mesmo parâmetro (`thl.classe`, ambiente `*`), lidos na **inclusão** por `new EnvironmentResource():getEnvironmentVariable( FieldDefaultEnum:... ) no-error`. Variável ausente, sem vínculo do programa ou valor em branco: o campo fica com o valor inicial do banco. O código da variável é o nome do membro do enum em minúsculas com `_` virando `.`.

| Tela | Campo → variável (valor) |
|---|---|
| `thl0021-v01.w` (objeto) | `ind-inativo` → `objeto.ind.inativo` (yes/no); `ind-gera-historico` → `objeto.ind.gera.historico`; `sentido-fluxo` → `objeto.sentido.fluxo` (yes = Saída, no = Entrada); `modelo-integracao` → `objeto.modelo.integracao` (1, 2 ou 3); `retencao-dias-sucesso` → `objeto.retencao.dias.sucesso`; `retencao-dias-erro` → `objeto.retencao.dias.erro`; `programa-consulta` → `objeto.programa.consulta` |
| `thl0022a-v01.w` (Principal) | `metodo` → `operacao.metodo`; `ind-inativo` → `operacao.ind.inativo`; `ind-gera-historico` → `operacao.ind.gera.historico`; `tipo-grava-conteudo` → `operacao.tipo.grava.conteudo`; `forma-execucao` → `operacao.forma.execucao` |
| `thl0022a-v03.w` (Persistência) | `ind-persistente` → `operacao.ind.persistente`; `frequencia-execucao` → `operacao.frequencia.execucao`; `qtd-dias-persist` → `operacao.dias.persist`; `qtd-tentativas-persist` → `operacao.tentativas.persist`; `tipo-log-requisicao` → `operacao.tipo.log.requisicao`; `tipo-log-retorno` → `operacao.tipo.log.retorno` |
| `thl0022a-v05.w` (REST) | `ind-mensagem-simples` → `operacao.ind.mensagem.simples` |

O procedimento comum `pi-padrao-campo` fica no include `thl/include/i01thl002.i`; cada viewer tem o seu `pi-padroes-campos`, chamado no `local-add-record` (depois do `add-record` padrão, com `adm-new-record` = yes; antes ficava no `local-enable-fields`), que em seguida reaplica a regra de habilitar de cada aba (`pi-habilita-*`). Estabelecimento (`thl0022a-v01.w`): `cod-estabel` → `operacao.estabelecimento` (valor sugerido `*`; a tela chama `pi-nome-estab` depois). Na API o estabelecimento continua obrigatório. Aba Conexão (`thl0022a-v02.w`): `cod-param-ambiente` → `operacao.param.ambiente`; `cod-param-ambiente-destino` → `operacao.param.amb.destino` (30 caracteres no máximo no código). Aba Servidor (`thl0022a-v04.w`): `cod-servid-exec` → `operacao.servidor.execucao` (padrão aplicado antes da regra de habilitar e recusar do servidor em Online). Limite conhecido: aba que o usuário não abre durante a inclusão não recebe o padrão (a gravação usa o valor inicial do banco). A API aplica os mesmos padrões na criação (ver `extensions/thl.md`). A carga `carga-thl-classe` tem as 22 variáveis geradas em 15/10 (4 de classe, 6 do objeto, 12 da operação, com os valores iguais aos iniciais do banco, exceto classes) e os sete programas vinculados (`ObjetoService`, `ObjetoParametroService`, `thl0021-v01`, `thl0022a-v01`, `thl0022a-v03`, `thl0022a-v05`, `thl0022a-v06`). **Ainda não geradas no `.d`** (cadastrar no thl0002 ou pedir nova carga): `objeto.programa.consulta`, `operacao.param.ambiente`, `operacao.param.amb.destino`, `operacao.servidor.execucao`, e os programas `thl0022a-v02` e `thl0022a-v04`, que precisam estar vinculados ao parâmetro `thl.classe`.

**`thl0220z.p` (agendador do RPW).** A busca de `thl-objeto-parametro` não usava o `metodo`, que passou a fazer parte da chave: em operação com mais de um método ela podia pegar a linha de outro método. Agora procura a linha da operação da mensagem com o método da mensagem e, sem ela, a linha do objeto (operação em branco) do mesmo método, como os loaders. A mensagem de servidor em branco deixou de repetir a de "parâmetro não encontrado" e orienta a aba Servidor do thl0022a.

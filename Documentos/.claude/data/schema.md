# Schema de dados THL (`thl-*`)

> Nota criada em 2026-09-24 e **reescrita no mesmo dia** a partir do `.df` refeito.
> **Fonte:** `Database\thl.df` (versionado; 84.274 bytes; rótulos e descrições revisados em 2026-09-24 e 2026-09-25; ISO-8859-1, trailer `cpstream=ISO8859-1`, CRLF) — **30 tabelas, 188 campos, 59 índices (30 `pk-`, 13 `fk-`, 16 `idx-`), 1 sequência** (`thl-seq-id-email` voltou ao `.df` gerado em 2026-09-25; não é usada no código). `thl-aplicacao` incluída em 2026-09-25. A cópia antiga em `.sharedavm\thl.df` (2026-06-04, 21 tabelas) está obsoleta.
> Convenção de nomes de índice: `pk-` chave primária, `fk-` chave estrangeira, `idx-` busca ([convencoes.md §6](../convencoes.md); plano de renomeação no §6 abaixo).
> Ao alterar o banco: atualizar `Database\thl.df`, esta nota e o changelog do [INDEX.md](../INDEX.md). Para bancos em uso, gerar o **.df incremental** no Data Dictionary e ativar índices novos (`proutil <db> -C idxactivate` ou `idxbuild`).

## 1. Tabelas por domínio

| Domínio | Tabela | Dump | Campos principais | Tela / uso |
|---|---|---|---|---|
| Ambiente | `thl-ambiente` | thl001 | `cod-ambiente`, `nome-ambiente`, `ip` | thl0001 |
| | `thl-ambiente-param` | thl002 | `cod-param-ambiente`, `descr-param-ambiente` | thl0002 |
| | `thl-ambiente-param-variavel` | thl005 | `cod-ambiente`, `cod-param-ambiente`, `cod-variavel`, `valor-variavel`, `descr-variavel` | thl0002 |
| | `thl-ambiente-param-prog` | thl003 | `cod-param-ambiente`, `cod-prog-dtsul` (resolução pelo call stack) | thl0002 |
| | `thl-ambiente-param-grupo` | thl017 | `cod-grp-usuar`, `descricao` | thl0011 |
| | `thl-ambiente-param-grupo-usuar` | thl014 | `cod-grp-usuar`, `cod-usuario`, `email-alternativo` | thl0011 |
| Objeto de integração | `thl-aplicacao` | thl004 | `aplicacao`, `descricao` — cadastro mestre das aplicações; **ainda sem relação** com o campo `aplicacao` das outras tabelas (texto livre) | thl0020 |
| | `thl-objeto` | thl010 | `aplicacao`, `objeto`, `classe-objeto` (nome completo da classe — `dynamic-new`), `sentido-fluxo`, `modelo-integracao`, `ind-gera-historico`, `ind-inativo`, `programa-consulta` | thl0021 |
| | `thl-objeto-parametro` | thl011 | `cod-estabel`, `aplicacao`, `objeto`, `operacao`, `metodo` (`MethodTypeEnum`), `forma-execucao` (`ExecutionMode`), `ind-mensagem-simples`, `cod-param-ambiente`, `cod-param-ambiente-destino` (**códigos de variável** cujo valor é o `cod-conexao`/`cod-path` — ver [er-diagrama.md](er-diagrama.md)), `frequencia-execucao`, `cod-servid-exec`, `ind-persistente`, `qtd-tentativas-persist`, `qtd-dias-persist`, `tipo-log-requisicao`, `tipo-log-retorno` | thl0022 |
| | `thl-objeto-usuario` | thl012 | `aplicacao`, `objeto`, `cod-usuario` (visibilidade no monitor) | thl0022 |
| | `thl-inbound-rota` | thl021 | `cod-rota`, `rota-publica`, `aplicacao`, `objeto`, `ind-ativo`, `descricao` | thl0040 |
| Conexão REST | `thl-conexao-rest` | thl018 | `cod-conexao`, `des-conexao`, `url-base`, `ind-requisita-autenticacao`, `ind-requisita-header` | thl0030 |
| | `thl-conexao-rest-path` | thl019 | `cod-path`, `des-path`, `path`, `content-type`, `accept`, `timeout`, `parameters`, `headers` | thl0031 |
| | `thl-conexao-rest-autenticacao` | thl020 | `cod-conexao`, `tipo-autenticacao`, `url-token`, `content-type-token`, `accept-token`, `headers-token`, `parameters-token`, `usuario`, `senha`, `token`, `raw-token-data`, `dt-expiracao-token`, `ind-requisita-token`, `classe-parser-token` (classe `ITokenProvider`) | thl0032 |
| | `thl-conexao-rest-header` | thl022 | `cod-conexao`, `classe-parser` (classe `IHeaderProvider`), `parameters` | thl0033 |
| Mensageria | `thl-mensagem` | thl009 | `codigo-mensagem`, `aplicacao`, `objeto`, `operacao`, `metodo`, `modelo-integracao`, `forma-execucao`, `sentido-fluxo`, `sit-requisicao`/`sit-retorno`/`sit-processamento`, `qtd-tentativas`, `dt-criacao`, `dt-integracao`, `destino`, `num-ped-exec`, `cod-status-retorno`, `descr-retorno` | monitor thl0120 |
| | `thl-mensagem-conteudo` | thl016 | `codigo-mensagem`, `tipo-conteudo`, `conteudo` (CLOB) | thl0120 |
| | `thl-mensagem-historico` | thl008 | `codigo-mensagem`, `tentativa`, datas, `destino`, situações, `cod-status-retorno`, `descr-retorno` | thl0120 |
| | `thl-mensagem-item` | thl015 | `codigo-mensagem`, `chave-registro`, `chave-registro-ext` | thl0120 |
| | `thl-mensagem-ped-exec` | thl023 | `codigo-mensagem`, `data-agendamento`, `num-ped-exec` | thl0220z.p |
| E-mail | `thl-email` | thl007 | `id`, `data-envio`, `cod-prog-dtsul`, `remetente`, `destino`, `assunto`, `mensagem`, `arq-anexo`, `log-envio`, `retorno`, `info-envio`, `cod-param-ambiente` | monitor thl0110 |
| | `thl-email-param` | th023 ⚠️ | `cod-email-param`, `cod-grp-usuar`, `remetente`, `copia`, `assunto`, `mensagem`, `importancia`, `log-gerar` | thl0010 |
| Auditoria — configuração | `thl-audit-tabela` | thl026 | `banco`, `tabela`, `pk`, `ind-ativo-create`/`-update`/`-delete`, `ind-audit-tabela`, `nivel-sensibilidade`, `dt-atualizacao`, `cod-usuario` | thl0050 / thl0051 |
| | `thl-audit-tabela-campo` | thl013 | `banco`, `tabela`, `campo`, `nivel-sensibilidade`, `ind-ativo` | thl0051 (b02), thl0051h |
| | `thl-audit-tabela-acesso` | thl028 | `banco`, `tabela`, `cod-usuario`, `nivel-acesso`, `ind-ativo` | thl0051 (b01) |
| | `thl-audit-tabela-notificacao` | thl029 | `banco`, `tabela`, `nivel-sensibilidade`, `grupo-email`, `ind-ativo` | thl0051 (b03) |
| | `thl-audit-tabela-purge` | thl030 | `banco`, `tabela`, `retencao-dias`, `dt-ultima-execucao` (gravado pelo expurgo) | thl0051 (b04); lido pelo expurgo thl0250 |
| Auditoria — registros | `thl-audit-registro` | thl006 | `id-registro` (GUID), `banco` (prefixo `sh`), `tabela`, `data-criacao`, `tipo`, `usuario`, `usuario-so`, `programa-executado`, `referencia`, `campos` | `AuditLogService` (grava), `AuditoriaService`, thl0150 |
| | `thl-audit-registro-detalhe` | thl025 | `id-registro`, `tipo` (snapshot), `valor` (CLOB) | idem |
| | `thl-audit-registro-notificar` | thl031 | `id-registro`, `nivel-sensibilidade`, `situacao`, `dt-notificacao`, `msg-erro` | sem programa no repositório |

Domínios de códigos usados nas telas (includes `Fontes\thl\include\i0Nthl011.i`): situação `1=Pendente, 2=Erro, 3=Sucesso, 4=Não aplicável`; método `1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET, 6=INSERT, 7=UPDATE, 8=SELECT, 99=Não aplicável`; modelo de integração `1=Rest, 2=Soap (grafado "Saop"), 3=Database, 4=File`; forma de execução `1=Online, 2=Agendar, 3=Batch`.

## 2. Índices

Legenda: **P** = primário, **U** = único. "Usado por" lista as consultas conhecidas no repositório (seleção de índice do ABL é por regra na compilação: igualdades iniciais → primeiro intervalo → `BY` → primário → ordem alfabética).

### Mensageria e objeto

| Tabela | Índice | Campos | Usado por / observação |
|---|---|---|---|
| `thl-mensagem` | `idx-objeto-criacao` **P** | aplicacao, objeto, dt-criacao | **Monitor** (`MensageriaService.get`, `thl0120.w`). Criado e tornado primário em 2026-09-24: vence o empate com `idx-objeto-parametro` pela regra do primário |
| | `pk-mensagem` U | codigo-mensagem | Acesso pela chave (`MessageRepository`, `thl0120b.w`, `thl0220z.p`) e RPWs `thl0220rp`/`thl0222rp`/`thl0221rp` (intervalo de código) |
| | `idx-objeto-parametro` | aplicacao, objeto, operacao | Só busca; nenhuma consulta filtra `operacao` por igualdade |
| | `fk-objeto` | aplicacao, objeto | Relação com `thl-objeto` |
| `thl-mensagem-conteudo` | `fk-mensagem` P | codigo-mensagem | Relação com `thl-mensagem` |
| | `pk-mensagem-conteudo` U | codigo-mensagem, tipo-conteudo | |
| `thl-mensagem-historico` | `pk-mensagem-histor` P U | codigo-mensagem, tentativa | |
| | `fk-mensagem` | codigo-mensagem | Relação com `thl-mensagem` |
| `thl-mensagem-item` | `idx-chave-registro` P | chave-registro | Busca da mensagem por registro de negócio |
| | `pk-mensagem-item` U | codigo-mensagem, chave-registro, chave-registro-ext | |
| | `fk-mensagem` | codigo-mensagem | Relação com `thl-mensagem` |
| `thl-mensagem-ped-exec` | `pk-mensagem` P U | codigo-mensagem | |
| | `idx-data-agendamento` | data-agendamento | Busca por data de agendamento (nome corrigido em 2026-09-24; era `idx-data-agentamento`) |
| `thl-aplicacao` | `pk-aplicacao` P U | aplicacao | Cadastro thl0020 (query, zoom, vá para) |
| `thl-objeto` | `pk-objeto` P U | aplicacao, objeto | |
| `thl-objeto-parametro` | `pk-objeto-parametro` P U | cod-estabel, aplicacao, objeto, operacao | |
| | `fk-objeto` | aplicacao, objeto | Relação com `thl-objeto` |
| `thl-objeto-usuario` | `pk-objeto-usuario` P U | aplicacao, objeto, cod-usuario | `can-find` do `thl0120.w` (3 igualdades) |
| | `idx-usuario` | cod-usuario, aplicacao, objeto | **Monitor** (`MensageriaService.get`) — criado em 2026-09-24 |
| `thl-inbound-rota` | `pk-rota` P U | cod-rota | |
| | `idx-rota-publica` U | rota-publica | Resolução da rota inbound |
| | `idx-ativo` | ind-ativo | |
| | `fk-objeto` | aplicacao, objeto | Relação com `thl-objeto` |

### Ambiente, conexão e e-mail

| Tabela | Índice | Campos | Observação |
|---|---|---|---|
| `thl-ambiente` | `pk-ambiente` P U | cod-ambiente | |
| | `idx-ip` U | ip | Garante IP único. A resolução (`EnvironmentRepository`) percorre `ip <> ''` e compara com o PROPATH — lê a tabela toda (pequena) |
| `thl-ambiente-param` | `pk-param` P U | cod-param-ambiente | |
| `thl-ambiente-param-variavel` | `idx-ambiente-param-variavel` P | cod-ambiente, cod-param-ambiente | Prefixo do único |
| | `pk-ambiente-param-variavel` U | cod-ambiente, cod-param-ambiente, cod-variavel | |
| `thl-ambiente-param-prog` | `pk-param-prog` P U | cod-param-ambiente, cod-prog-dtsul | |
| | `fk-param` | cod-param-ambiente | Relação com `thl-ambiente-param` |
| `thl-ambiente-param-grupo` | `pk-cod-grp-usuar` P U | cod-grp-usuar | |
| `thl-ambiente-param-grupo-usuar` | `fk-grupo` P | cod-grp-usuar | Relação com `thl-ambiente-param-grupo` |
| | `pk-grupo-usuar` U | cod-grp-usuar, cod-usuario, email-alternativo | |
| `thl-conexao-rest` | `pk-conexao-rest` P U | cod-conexao | |
| `thl-conexao-rest-path` | `pk-path` P U | cod-path | |
| `thl-conexao-rest-autenticacao` | `pk-conexao-rest` P U | cod-conexao | Chave e relação 1:1 com `thl-conexao-rest` |
| `thl-conexao-rest-header` | `pk-conexao-rest` P U | cod-conexao | Criado em 2026-09-24 (`ConnectorConfig.cls:89`); uma configuração de header por conexão |
| `thl-email` | `idx-data-envio` P | cod-prog-dtsul, data-envio | Monitor thl0110 e **expurgo** `thl0210rp.p` (programa a programa: igualdade em `cod-prog-dtsul` + intervalo em `data-envio`) |
| | `pk-email` U | id | |
| `thl-email-param` | `pk-param-email` P U | cod-email-param | |

### Auditoria

| Tabela | Índice | Campos | Usado por / observação |
|---|---|---|---|
| `thl-audit-registro` | `pk-audit` P U | id-registro | Leitura do registro / detalhe |
| | `idx-tabela-data` | banco, tabela, data-criacao | **Consulta de auditoria** (`AuditoriaService.get`, `thl0150.w`) e **expurgo** por tabela (`thl0250rp.p`: igualdade em banco/tabela + `data-criacao <` limite) — criado em 2026-09-24 |
| | `fk-audit-tabela` | banco, tabela | Relação com `thl-audit-tabela` (banco com prefixo `sh`) |
| | `idx-audit-data` | data-criacao | Sem consulta no repositório |
| `thl-audit-registro-detalhe` | `fk-audit-registro` P | id-registro | Não é único: é a relação com `thl-audit-registro` |
| | `pk-reg-detalhe` U | id-registro, tipo | Leitura do snapshot (2 igualdades, único) |
| `thl-audit-registro-notificar` | `fk-audit-registro` P | id-registro | Relação com `thl-audit-registro` |
| | `pk-notificar` U | id-registro, nivel-sensibilidade | |
| | `idx-notificar-situacao` | situacao, id-registro | Fila de notificações pendentes |
| `thl-audit-tabela` | `pk-tabela` P U | banco, tabela | `AuditLogService` (gravação) |
| `thl-audit-tabela-acesso` | `pk-acesso` P U | banco, tabela, cod-usuario | |
| | `idx-usuario` | cod-usuario, ind-ativo, banco, tabela | **Consulta de auditoria** (loop de acesso do usuário) — refeito em 2026-09-24 |
| | `fk-audit-tabela` | banco, tabela | Relação com `thl-audit-tabela` |
| `thl-audit-tabela-campo` | `pk-campo` P U | banco, tabela, campo | Campos restritos (`isFieldRestricted`, thl0051h) |
| | `idx-ativo` | banco, tabela, ind-ativo, campo | `AuditLogService` (campos ativos) |
| | `idx-campo-tabela` | tabela, banco | Sem consulta no repositório |
| `thl-audit-tabela-notificacao` | `pk-notificacao` P U | banco, tabela, nivel-sensibilidade | |
| | `fk-audit-tabela` | banco, tabela | Relação com `thl-audit-tabela` |
| `thl-audit-tabela-purge` | `pk-purge` P U | banco, tabela | Faixa de seleção do expurgo thl0250 |

**Índices de busca sem consulta no repositório** (candidatos a remover, após confirmar fora do repositório): `thl-mensagem.idx-objeto-parametro`, `thl-audit-registro.idx-audit-data`, `thl-audit-tabela-campo.idx-campo-tabela`, `thl-inbound-rota.idx-ativo`. Os `fk-*` ficam por convenção (documentam a relação), mesmo quando são prefixo de outro índice — custo só de escrita.

## 3. Relações principais

Diagrama dos vínculos entre as tabelas THL (gerado do `.df`, com os vínculos só de código marcados à parte): **[er-diagrama.md](er-diagrama.md)**. A árvore em texto que ficava aqui foi substituída em 2026-09-25 — tinha `thl-conexao-rest-path` como filha da conexão (não é) e não ligava `thl-mensagem` a `thl-objeto` nem o registro de auditoria à configuração.

As relações são por chave de negócio (não há FK física no OpenEdge). Em `thl-audit-registro`, `banco` é gravado com o prefixo `sh` (nome do banco na sessão), enquanto nas tabelas de configuração fica sem o prefixo — as consultas fazem `'sh' + banco`.

## 4. Divergências e pontos de atenção

| Item | Situação |
|---|---|
| `thl-mensagem.pacote` | **Não existe** no `.df` nem na temp-table `tt-thl-mensagem` (`like thl-mensagem`), mas `thl0120.w:459,636` faz `dynamic-new tt-thl-mensagem.pacote + tt-thl-mensagem.objeto` no reenvio — o programa não compila como está. Decidir: criar o campo ou usar `thl-objeto.classe-objeto` |
| `thl-conexao-rest-header` | Resolvido: `pk-conexao-rest` único e primário |
| Credenciais em texto | `thl-conexao-rest-autenticacao.senha` e `.token` são `character` sem criptografia |
| Dump-name `th023` | `thl-email-param` (faltou o "l"); `thl023` é da `thl-mensagem-ped-exec` |
| Nomes corrigidos | O `.df` refeito renomeou 13 índices (`ind-*` → `idx-*`, ex.: `thl-ambiente.idx-ip`). Nenhum `use-index` no repositório usava os nomes antigos |
| Tabelas antes ausentes | `thl-conexao-rest-header` e as 6 tabelas `thl-audit-*` que faltavam (`-registro-detalhe`, `-tabela`, `-tabela-campo`, `-tabela-acesso`, `-tabela-notificacao`, `-tabela-purge`) agora estão no `.df` |

Nomes citados só em comentários (não são tabelas): `thl-historico-mensagem` (código comentado em `thl0120b-v01.w`), `thl-audit-campo-tabela` (nota antiga), `thl-conexao-rest-caberario` (erro de digitação em `HeaderProvider.cls`).

## 6. Renomeação para a convenção `pk-` / `fk-` / `idx-` (aplicada em 2026-09-24)

Convenção decidida em 2026-09-24 ([convencoes.md §6](../convencoes.md)). Aplicada diretamente no `.df` completo (as tabelas serão apagadas e recriadas no ambiente); as seções 2 e 4 já usam os nomes novos. Esta tabela fica como **histórico de nomes** (útil para achar `use-index` antigo fora do repositório). `thl-conexao-rest-header.pk-conexao-rest` recebeu `UNIQUE`. **45 mudanças** (44 renomeações + 1 remoção); os outros 14 índices já seguem o padrão (`idx-*` de busca, incluindo `idx-ip` único como chave alternativa). Nenhum `use-index` do repositório usa os nomes atuais (o único `use-index` do código é `ch-emb`, tabela Datasul); confirmar fora do repositório e recompilar os programas das tabelas.

| Tabela | Índice atual | Novo nome | Motivo |
|---|---|---|---|
| `thl-ambiente` | `ch-ambiente` (P U) | `pk-ambiente` | chave única da tabela |
| `thl-ambiente-param` | `ch-param` (P U) | `pk-param` | chave única da tabela |
| `thl-ambiente-param-grupo` | `ch-cod-grp-usuar` (P U) | `pk-cod-grp-usuar` | chave única da tabela |
| `thl-ambiente-param-grupo-usuar` | `idx-cod-grp-usuar` (P) | `fk-grupo` | relação com `thl-ambiente-param-grupo` |
| `thl-ambiente-param-grupo-usuar` | `ch-grupo-usuar` (U) | `pk-grupo-usuar` | chave única da tabela |
| `thl-ambiente-param-prog` | `ch-param-prog` (P U) | `pk-param-prog` | chave única da tabela |
| `thl-ambiente-param-prog` | `idx-param` | `fk-param` | relação com `thl-ambiente-param` |
| `thl-ambiente-param-variavel` | `ch-ambiente-param-variavel` (U) | `pk-ambiente-param-variavel` | chave única da tabela |
| `thl-audit-registro` | `ch-audit` (P U) | `pk-audit` | chave única da tabela |
| `thl-audit-registro` | `idx-tabela` | `fk-audit-tabela` | relação com `thl-audit-tabela` (banco com prefixo `sh`) |
| `thl-audit-registro-detalhe` | `ch-audit` (P) | `fk-audit-registro` | não é único: é a relação com `thl-audit-registro` |
| `thl-audit-registro-detalhe` | `idx-reg-detalhe` (U) | `pk-reg-detalhe` | é a chave única da tabela |
| `thl-audit-registro-notificar` | `idx-audit` (P) | `fk-audit-registro` | relação com `thl-audit-registro` |
| `thl-audit-registro-notificar` | `ch-notificar` (U) | `pk-notificar` | chave única da tabela |
| `thl-audit-tabela` | `ch-tabela` (P U) | `pk-tabela` | chave única da tabela |
| `thl-audit-tabela-acesso` | `ch-acesso` (P U) | `pk-acesso` | chave única da tabela |
| `thl-audit-tabela-acesso` | `idx-tabela` | `fk-audit-tabela` | relação com `thl-audit-tabela` |
| `thl-audit-tabela-campo` | `ch-campo` (P U) | `pk-campo` | chave única da tabela |
| `thl-audit-tabela-notificacao` | `ch-notificacao` (P U) | `pk-notificacao` | chave única da tabela |
| `thl-audit-tabela-notificacao` | `idx-tabela` | `fk-audit-tabela` | relação com `thl-audit-tabela` |
| `thl-audit-tabela-purge` | `ch-purge` (P U) | `pk-purge` | chave única da tabela |
| `thl-audit-tabela-purge` | `idx-tabela` | **remover** | idêntico à chave (relação 1:1) |
| `thl-conexao-rest` | `ch-conexao-rest` (P U) | `pk-conexao-rest` | chave única da tabela |
| `thl-conexao-rest-autenticacao` | `ch-conexao-rest` (P U) | `pk-conexao-rest` | chave única da tabela |
| `thl-conexao-rest-header` | `ch-conexao-rest` (P) | `pk-conexao-rest` | chave única da tabela — **marcar `UNIQUE`** |
| `thl-conexao-rest-path` | `ch-path` (P U) | `pk-path` | chave única da tabela |
| `thl-email` | `id-mail` (U) | `pk-email` | é a chave única da tabela |
| `thl-email-param` | `ch-param-email` (P U) | `pk-param-email` | chave única da tabela |
| `thl-inbound-rota` | `ch-rota` (P U) | `pk-rota` | chave única da tabela |
| `thl-inbound-rota` | `ch-rota-publica` (U) | `idx-rota-publica` | chave alternativa: `idx-` + `UNIQUE` |
| `thl-inbound-rota` | `idx-objeto` | `fk-objeto` | relação com `thl-objeto` |
| `thl-mensagem` | `ch-mensagem` (U) | `pk-mensagem` | chave única da tabela |
| `thl-mensagem` | `idx-objeto` | `fk-objeto` | relação com `thl-objeto` |
| `thl-mensagem-conteudo` | `idx-mensagem` (P) | `fk-mensagem` | relação com `thl-mensagem` |
| `thl-mensagem-conteudo` | `ch-mensagem-conteudo` (U) | `pk-mensagem-conteudo` | chave única da tabela |
| `thl-mensagem-historico` | `ch-mensagem-histor` (P U) | `pk-mensagem-histor` | chave única da tabela |
| `thl-mensagem-historico` | `idx-mensagem` | `fk-mensagem` | relação com `thl-mensagem` |
| `thl-mensagem-item` | `ch-mensagem-item` (U) | `pk-mensagem-item` | chave única da tabela |
| `thl-mensagem-item` | `idx-mensagem` | `fk-mensagem` | relação com `thl-mensagem` |
| `thl-mensagem-ped-exec` | `ch-mensagem` (P U) | `pk-mensagem` | chave única da tabela |
| `thl-mensagem-ped-exec` | `idx-data-agentamento` | `idx-data-agendamento` | erro de digitação |
| `thl-objeto` | `ch-objeto` (P U) | `pk-objeto` | chave única da tabela |
| `thl-objeto-parametro` | `ch-objeto-parametro` (P U) | `pk-objeto-parametro` | chave única da tabela |
| `thl-objeto-parametro` | `idx-objeto` | `fk-objeto` | relação com `thl-objeto` |
| `thl-objeto-usuario` | `ch-objeto-usuario` (P U) | `pk-objeto-usuario` | chave única da tabela |

## 5. Tabelas de outros schemas usadas pela THL

Datasul padrão (`emitente`, `estabelec`, `item`, `nota-fiscal`, `ped-venda`, `embarque`, `requisicao`, `it-requisicao`, `ordem-compra`, `docum-est`, `ems.ccusto`, `usuar_mestre`…) e **tabelas de cliente** `nit-*` (`nit-lpco`, `nit-frete-prev`, `nit-frete-real`, `nit-loc-entr`, `nit-tipo-oper`, `nit-tipo-oper-natur`, `nit-loog-natur-oper`) + `es_nota_terceiros` — estas só devem aparecer em `thl-extensions`.

Relacionados: [arquitetura.md](../arquitetura.md) · [integration/messaging-core.md](../integration/messaging-core.md) · [logging/logging.md](../logging/logging.md) · [integration/connectors.md](../integration/connectors.md)

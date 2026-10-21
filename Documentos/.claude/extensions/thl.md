---
tipo: modulo
camada: extension
status: vigente
tags: [extensao, thl]
updated: 2026-10-13
---

# Extensão: thl (API REST dos cadastros do próprio THL)

> ⚠️ **2026-10-04 — Message → Processor → Service.** Um **objeto por agregado**, filhos como **operação da URL** (`objeto/usuario`, não mais `objeto-usuario`), 11 Messages retiradas (`.cls.old`) e 6 Processors novos. As seções anteriores que falam em "uma Message por agregado" e em rota própria do filho são histórico; o estado atual está na seção final desta nota.

O THL tratado como sistema externo `thl` (aplicação `THL`): GET/POST/PATCH/DELETE dos cadastros para telas PO UI e automação. Decisões em [adr/api-rest-cadastros-thl.md](../adr/api-rest-cadastros-thl.md); modelo seguido: [automatizador.md](automatizador.md) (`LpcoMessage`/`LpcoService`). Piloto criado em 2026-09-25 — **não compilado** (compilar no PDSOE ou com `Utils\scripts\compilar-thl.p`).

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| AmbienteService | CRUD de `thl-ambiente` (thl0001); `ip` único; não elimina ambiente com variáveis | Service (Template Method via `Service`) | Service, JsonSetter, PaginationHelper, ThlError | AmbienteMessage |
| ParametroAmbienteService | CRUD de `thl-ambiente-param` (thl0002); não elimina parâmetro com variáveis/programas | Service | idem | ParametroAmbienteMessage |
| ParametroVariavelService | CRUD de `thl-ambiente-param-variavel` (thl0002b); pai/ambiente inexistente → 2; valor sensível mascarado | Service | idem | ParametroAmbienteMessage (rota `parametro-variavel`) |
| ParametroProgramaService | Inclui/elimina/lista `thl-ambiente-param-prog` (thl0002c); sem `update()` | Service | Service, PaginationHelper, ThlError | ParametroAmbienteMessage (rota `parametro-programa`) |
| AplicacaoService | CRUD de `thl-aplicacao` (thl0020); não elimina aplicação com objetos (`thl-objeto`) | Service | Service, JsonSetter, PaginationHelper, ThlError | AplicacaoMessage |
| AplicacaoMessage | Contrato inbound de `/resourcen/aplicacao` | Template Method + Factory Method | InboundMessage, AplicacaoService | InboundMessageService (via `thl-objeto.classe-objeto`) |
| AmbienteMessage | Contrato inbound de `/resourcen/ambiente` | Template Method + Factory Method | InboundMessage, AmbienteService | InboundMessageService (via `thl-objeto.classe-objeto`) |
| ParametroAmbienteMessage | Contrato inbound do agregado Parâmetro: `/resourcen/parametro-ambiente`, `/parametro-variavel` e `/parametro-programa`; mascara o conteúdo gravado (`saveContentByType`) | idem | InboundMessage, ParametroAmbienteService, ParametroVariavelService, ParametroProgramaService | idem |

## Uma Message por agregado (2026-10-02)

Decisão do responsável em 2026-10-02 (revisão do [ADR](../adr/api-rest-cadastros-thl.md) §2.4): o cadastro pai e os filhos que não existem sem ele usam **uma Message**; cada tabela continua com o **próprio Service**. `createService()` é o Factory Method e escolhe o Service pela rota pública (`context:routePath`), como a `NotaFiscalMessage` de `thl-lib`. Aplicado nos cinco agregados — **não compilado**.

| Message (objeto) | Rota → Service |
|---|---|
| `ParametroAmbienteMessage` (PARAMETRO) | `parametro-ambiente` → `ParametroAmbienteService` · `parametro-variavel` → `ParametroVariavelService` · `parametro-programa` → `ParametroProgramaService` |
| `ObjetoMessage` (OBJETO) | `objeto` → `ObjetoService` · `objeto-parametro` → `ObjetoParametroService` · `objeto-usuario` → `ObjetoUsuarioService` |
| `ConexaoRestMessage` (CONEXAO-REST) | `conexao-rest` → `ConexaoRestService` · `conexao-rest-autenticacao` → `ConexaoRestAutenticacaoService` · `conexao-rest-header` → `ConexaoRestHeaderService` |
| `AuditoriaTabelaMessage` (AUDIT-TABELA) | `auditoria-tabela` → `AuditoriaTabelaService` · `-acesso`, `-campo`, `-notificacao`, `-expurgo` → o Service de cada filho |
| `GrupoEmailMessage` (GRUPO-EMAIL) | `grupo-email` → `GrupoEmailService` · `grupo-email-usuario` → `GrupoEmailUsuarioService` |

Seguem com Message própria (não são filhos): `AmbienteMessage`, `AplicacaoMessage`, `ConexaoRestPathMessage` (o path não pertence a uma conexão), `EmailParametroMessage`, além das consultas `AuditoriaMessage`, `EmailMessage` e `MensageriaMessage`.

**O que não mudou:** URLs, contrato JSON, filtros do GET, Services, app web e coleção Postman.

**O que mudou:**
- 11 Messages de filhos foram retiradas (cópias em `Documentos\arquivo\2026-10-02-messages-filhas-thl\`): `ParametroVariavel`, `ParametroPrograma`, `ObjetoParametro`, `ObjetoUsuario`, `ConexaoRestAutenticacao`, `ConexaoRestHeader`, `AuditoriaTabelaAcesso`/`Campo`/`Notificacao`/`Expurgo` e `GrupoEmailUsuario`. `thl-extensions` passa de 75 para **64 classes**.
- As rotas dos filhos apontavam para o **objeto do pai** em `thl-inbound-rota`; os objetos próprios dos filhos (`PARAMETRO-VARIAVEL`, `OBJETO-USUARIO`, …) ficavam sem uso. **Superado:** o filho é hoje uma **operação da URL do pai** (`parametro-ambiente/variavel`) e a rota é uma só por objeto, em `thl-objeto-rota` (ver [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §§9 e 13).
- Em cada Message unificada há três `case context:routePath`: `createService()` (rota desconhecida lança `ThlError`), `methodGet()` e `getRequiredFields()`.
- A máscara de segredo (`saveContentByType`) roda em `InboundMessageService:accept`, **antes** de o contexto existir. Por isso não depende da rota: instancia o Service direto (`new ParametroVariavelService()` / `new ConexaoRestAutenticacaoService()`) e age sobre qualquer item que tenha os campos sensíveis.
- Programa do parâmetro, usuário do objeto e usuário do grupo não tinham parâmetro de PATCH; agora o PATCH chega ao Service e cai no `update()` de `Service` ("Acao nao suportada", 17006).
- `thl-objeto-usuario` (visibilidade no monitor) passa a valer para o agregado inteiro; no monitor de mensageria as chamadas dos filhos aparecem no objeto do pai, distinguidas pela rota gravada.

**Por que pela rota e não pela operação (`pai/filho`):** com operação na URL, o `MessageConfigLoader` procura `thl-objeto-parametro` por método **e** operação, mas a chave primária (`cod-estabel`, `aplicacao`, `objeto`, `operacao`) não inclui o método — só caberia **um verbo por filho** (é o caso de `mensageria/conteudo`, só GET). Sem mudar o `.df` nem `thl-lib`, a escolha pela rota é a que aceita os quatro verbos.

**Implantação (ordem):** 1) compilar e publicar as cinco Messages; 2) apontar as rotas dos filhos para o objeto do pai — `Utils\scripts\carga-thl-api-cadastros.p` (ABL) ou `Utils\scripts\cadastrar-thl-api-rotas.ps1` / `.cmd` (pelos próprios endpoints; simulação por padrão, `-Executar` grava, `-EliminarObsoletos` elimina os objetos dos filhos); 3) apagar os `.r` das 11 classes retiradas. ⚠️ Entre o passo 1 e o 2, as rotas dos filhos ficam fora do ar (apontam para classe que não existe mais); `inbound-rota` não é afetada.

**A testar no PASOE (nada foi executado):** cada rota × verbo; rota desconhecida apontada para o objeto devolve erro; `valor` de variável sensível e `senha`/`token` da autenticação saem como `********` no conteúdo gravado da mensagem (entrada e saída); campos obrigatórios por rota; PATCH nas três rotas sem alteração.

⚠️ Achado: `thl-conexao-rest-header.parameters` pode guardar segredo (ex.: HMAC do `gestaoepi`) e **não** é mascarado no conteúdo gravado — já era assim antes da unificação.

### Demais cadastros (gerados em 2026-10-01, não compilados)

Um `<Recurso>Service` por tabela; a Message é a do agregado (seção anterior) — a coluna "Rota · objeto" mostra o objeto do pai nos filhos. Gerados por tabela a partir do `Pi-validate` (criação/alteração) e do `local-delete-record` (exclusão) da tela. Nos nomes JSON o prefixo `cod-` foi retirado (`conexao`, `usuario`, `rota`); os demais campos são o nome do banco em camelCase.

| Recurso (classes) | Tabela / tela | Rota · objeto | Chave JSON | Demais campos | Regras |
|---|---|---|---|---|---|
| `AuditoriaTabela` | `thl-audit-tabela` / thl0050 | `auditoria-tabela` · AUDIT-TABELA | `banco`, `tabela` | `pk`, `indAtivoCreate`, `indAtivoUpdate`, `indAtivoDelete`, `nivelSensibilidade`, `indAuditTabela`; só leitura: `dtAtualizacao`, `usuario` (gravados pelo Service: `now` e `ContextService:getErpUser()`) | banco/tabela obrigatórios; não elimina com campo, acesso, notificação ou expurgo |
| `AuditoriaTabelaAcesso` | `thl-audit-tabela-acesso` / thl0051b | `auditoria-tabela-acesso` · AUDIT-TABELA | `banco`, `tabela`, `usuario` | `nivelAcesso`, `indAtivo` | tabela auditada existe (2); usuário obrigatório e existente em `usuar_mestre` (2) |
| `AuditoriaTabelaCampo` | `thl-audit-tabela-campo` / thl0051c | `auditoria-tabela-campo` · AUDIT-TABELA | `banco`, `tabela`, `campo` | `nivelSensibilidade`, `indAtivo` | tabela auditada existe (2); campo obrigatório |
| `AuditoriaTabelaNotificacao` | `thl-audit-tabela-notificacao` / thl0051d | `auditoria-tabela-notificacao` · AUDIT-TABELA | `banco`, `tabela`, `nivelSensibilidade` (inteiro) | `grupoEmail`, `indAtivo` | tabela auditada existe (2); grupo obrigatório e existente em `thl-ambiente-param-grupo` (2) |
| `AuditoriaTabelaExpurgo` | `thl-audit-tabela-purge` / thl0051e | `auditoria-tabela-expurgo` · AUDIT-TABELA | `banco`, `tabela` | `retencaoDias`; só leitura: `dtUltimaExecucao` | tabela auditada existe (2); retenção ≥ 0 |
| `ConexaoRest` | `thl-conexao-rest` / thl0030 | `conexao-rest` · CONEXAO-REST | `conexao` | `descricao`, `urlBase`, `indRequisitaAutenticacao`, `indRequisitaHeader` | URL base obrigatória; não elimina com autenticação ou cabeçalho |
| `ConexaoRestAutenticacao` | `thl-conexao-rest-autenticacao` / thl0032 | `conexao-rest-autenticacao` · CONEXAO-REST | `conexao` | `urlToken`, `contentTypeToken`, `acceptToken`, `tipoAutenticacao`, `indRequisitaToken`, `usuario`, `classeParserToken`; mascarados: `headersToken`, `parametersToken`, `senha`; mascarados e só leitura: `token`, `rawTokenData`; só leitura: `dtExpiracaoToken` | conexão existe (2); uma configuração por conexão |
| `ConexaoRestHeader` | `thl-conexao-rest-header` / thl0033 | `conexao-rest-header` · CONEXAO-REST | `conexao` | `classeParser`, `parameters` | conexão existe (2); classe obrigatória |
| `ConexaoRestPath` | `thl-conexao-rest-path` / thl0031 | `conexao-rest-path` · CONEXAO-REST-PATH | `endpoint` (`cod-path`; `path` é o campo do caminho) | `descricao`, `path`, `contentType`, `accept`, `timeout`, `parameters`, `headers` | código obrigatório |
| `Objeto` | `thl-objeto` / thl0021 | `objeto` · OBJETO | `aplicacao`, `objeto` | `classeObjeto`, `modeloIntegracao`, `sentidoFluxo`, `indInativo`, `indGeraHistorico`, `programaConsulta` | aplicação existe (2); classe obrigatória; exclusão elimina operações, usuários e rota (cascata) |
| `ObjetoParametro` | `thl-objeto-parametro` / thl0022a | `objeto-parametro` · OBJETO | `estabelecimento`, `aplicacao`, `objeto`, `operacao` | `metodo`, `formaExecucao`, `indInativo`, `indGeraHistorico`, `indMensagemSimples`, `paramAmbiente`, `paramAmbienteDestino`, `indPersistente`, `frequenciaExecucao`, `servidorExecucao`, `qtdTentativasPersist`, `qtdDiasPersist`, `tipoLogRequisicao`, `tipoLogRetorno` | estabelecimento `*` ou existente em `estabelec` (2); objeto existe (2) |
| `ObjetoUsuario` | `thl-objeto-usuario` / thl0022b | `objeto-usuario` · OBJETO | `aplicacao`, `objeto`, `usuario` | — (sem PATCH) | usuário obrigatório e existente em `usuar_mestre` (2); objeto existe (2) |
| `ObjetoRota` | `thl-objeto-rota` / thl0040 | `objeto/rota` (operação `rota` do objeto `Objeto`) | `aplicacao`, `objeto`, `rotaPublica` | `indAtivo`, `inicioOperacao` | aplicação e objeto existem (2); rota pública obrigatória e única no banco todo; o objeto pode ter várias rotas (chave tripla desde 2026-10-13; antes uma por objeto, `inbound-rota` e objeto `InboundRota`) |
| `EmailParametro` | `thl-email-param` / thl0010 | `email-parametro` · EMAIL-PARAMETRO | `emailParam` | `assunto`, `grupoEmail`, `remetente`, `copia`, `mensagem`, `importancia`, `logGerar` | grupo obrigatório e existente (2) |
| `GrupoEmail` | `thl-ambiente-param-grupo` / thl0011 | `grupo-email` · GRUPO-EMAIL | `grupoEmail` | `descricao` | não elimina com parâmetros de e-mail (17006) ou notificações de auditoria (17006) vinculadas |
| `GrupoEmailUsuario` | `thl-ambiente-param-grupo-usuar` / thl0011b | `grupo-email-usuario` · GRUPO-EMAIL | `grupoEmail`, `usuario`, `emailAlternativo` | — (sem PATCH) | usuário obrigatório e existente em `usuar_mestre` (2); grupo existe (2); sem duplicata (17006) |

- Filtros do GET: `<chave>Ini`/`<chave>Fin` — `bancoIni/Fin` + `tabelaIni/Fin` (auditoria), `conexaoIni/Fin`, `endpointIni/Fin`, `aplicacaoIni/Fin` + `objetoIni/Fin` (objeto, parâmetro e usuário), `rotaIni/Fin`, `emailParamIni/Fin`, `grupoEmailIni/Fin` (grupo e usuário do grupo).
- `referenceCode` de chave composta: partes unidas por `#`, na ordem da tabela acima.
- Regras que valem na criação e na alteração ficam no método privado `validateRecord()` do Service (lê o buffer depois do `mapFields`, antes do commit).
- Campos sensíveis da autenticação: `********` no GET quando há valor (vazio continua vazio); PATCH com `********` mantém o valor; `ConexaoRestMessage` mascara o conteúdo gravado (`saveContentByType`) pela lista `SensitiveFields` do Service.
- `AuditoriaTabelaAcessoService`, `ObjetoUsuarioService`, `GrupoEmailUsuarioService` (`usuar_mestre`) e `ObjetoParametroService` (`estabelec`) precisam dos bancos Datasul conectados para compilar e rodar.
- `objeto`, `objeto/parametro` e `objeto/rota` (antes `inbound-rota`) alteram a configuração da própria API (aplicação `THL`): erro nesses registros derruba a API; a recuperação é pela tela `.w`.
- `cod-rota` da carga = `THL-` + objeto (por isso os objetos de auditoria usam `AUDIT-`, para caber em 30 caracteres). As rotas dos filhos mantêm o código da carga anterior (`THL-` + objeto antigo do filho, ex.: `THL-OBJETO-USUARIO`), mesmo apontando para o objeto do pai.

## Caminhos e pacotes

```text
Fontes\thl-extensions\erp\thl\service\<Recurso>Service.cls                 thl-extensions.erp.thl.service.<Recurso>Service
Fontes\thl-extensions\integration\thl\messaging\inbound\message\<Recurso>Message.cls
                                                                            thl-extensions.integration.thl.messaging.inbound.message.<Recurso>Message
```

## Rotas e cadastros

Carga: `Utils\scripts\carga-thl-api-cadastros.p` (simulação por padrão; idempotente; desde 2026-10-02 repõe para o objeto do pai a rota de filho criada por carga anterior e avisa dos objetos sem uso). Pelos endpoints, com a API já no ar: `Utils\scripts\cadastrar-thl-api-rotas.ps1` (ou `.cmd`) — `-BaseUrl`, simulação por padrão, `-Executar`, `-EliminarObsoletos`; usuário e senha pedidos na hora, nada gravado no arquivo. O roteador (`InboundRouteResolver`) não foi alterado: 1 segmento = rota; um 2º segmento seria a operação.

| URL (`…/api/thl/integration/v1/resourcen/…`) | `thl-objeto-rota` (`rota-publica`) | Objeto (aplicação `THL`) | `thl-objeto-parametro` (cod-estabel `*`) |
|---|---|---|---|
| `ambiente` | `ambiente` | Ambiente | operações GET, POST, PATCH, DELETE (métodos 5, 1, 3, 4) |
| `parametro-ambiente` | `parametro-ambiente` | ParametroAmbiente | GET, POST, PATCH, DELETE |
| `parametro-ambiente/variavel` | (a do pai) | ParametroAmbiente | operação `variavel` do pai |
| `parametro-ambiente/programa` | (a do pai) | ParametroAmbiente | operação `programa` do pai (PATCH → "Acao nao suportada") |
| `aplicacao` | `aplicacao` | Aplicacao | GET, POST, PATCH, DELETE |

Sem operação na URL, o `MessageConfigLoader` acha o `thl-objeto-parametro` pelo **método**; como a chave primária inclui a operação, cada método usa o próprio nome como operação. Mover/renomear uma Message exige atualizar `thl-objeto.classe-objeto`.

## Teste (Postman)

Coleção **Nitro** no Postman do responsável (nuvem, workspace pessoal — não há mais cópia em `Utils\postman`, removida em 2026-10-01): `TOTVS > Projeto > THL-Library > THL` (a pasta `Biblioteca` foi renomeada para `THL-Library` em 2026-10-01), uma subpasta por cadastro — as URLs não mudaram com a unificação das Messages de 2026-10-02, então a coleção segue válida (Ambiente, Parametro, Parametro Variavel, Parametro Programa, Aplicação e, desde 2026-10-01, Auditoria Tabela, Auditoria Tabela Acesso/Campo/Notificacao/Expurgo, Conexao REST, Conexao REST Autenticacao/Header/Path, Objeto, Objeto Parametro, Objeto Usuario, Inbound Rota, Email Parametro — estas 14 com examples de sucesso: lista, lista vazia, criado, alteração parcial, eliminado). Desde 2026-10-01 cada subpasta tem as requests `GET Lista`, `POST`, `PATCH` e `DELETE` (sem `GET Por Chave`: a leitura por chave é o `GET Lista` com a mesma chave em `Ini`/`Fin`), com descrição, teste leve (status 200 + `items`/`hasNext` ou `success`) e os cenários salvos como **examples** (`<Pasta> - <Cenário>`: filtro pela chave, lista vazia, alteração parcial, senha mascarada, `********` mantém valor). Os examples foram derivados do código, ainda não capturados de execução real; os de erro entram depois do primeiro teste contra o PASOE. Autenticação herdada da pasta `Projeto`; URL sempre `{{URI-BASE-PROJETO-INTERNO}}`. Host e credenciais ficam só nas variáveis da coleção, nunca no repositório. Dados de teste: ambiente `TSA`, parâmetro `TSTAPI`.

## Contrato JSON

| Recurso | Campos (chave em **negrito**) | Filtros do GET (query string) |
|---|---|---|
| Ambiente | **`codAmbiente`**, `nomeAmbiente`, `ip` | `ambienteIni`, `ambienteFin` |
| Parâmetro | **`codParametro`**, `descricao` | `parametroIni`, `parametroFin` |
| Variável | **`codAmbiente`** (`*` = todos), **`codParametro`**, **`codVariavel`**, `descricao`, `valor` | `ambienteIni/Fin`, `parametroIni/Fin` |
| Programa | **`codParametro`**, **`codPrograma`** | `parametroIni`, `parametroFin` |
| Aplicação | **`aplicacao`**, `descricao` | `aplicacaoIni`, `aplicacaoFin` |

Os filtros do GET são sempre faixas (`Ini`/`Fin`) sobre campos da chave primária (`pk-*`); para ler um registro, informar a mesma chave nos dois.

Todos os GET aceitam `page` e `pageSize` (padrão 100); o Service devolve um array com `referenceCode` por item e o `resourcen.p` o entrega ao cliente como `{ "items": [...], "hasNext": false }` (`JsonAPIResponseBuilder:ok( JsonArray, false )` — `hasNext` é sempre `false`). POST/PATCH/DELETE levam a chave no corpo JSON (o DELETE também exige payload) e devolvem `ServiceResponse:success`. `getRequiredFields()` = campos da chave; `getExternalReferenceField()` = `''`.

## Regras (paridade com as telas)

- Erros com os códigos das telas: `ThlError` de 3 parâmetros → **17006**; pai/relacionado inexistente → `ThlError(…, 2)`.
- A chave só é gravada na criação; `mapFields()` grava só os demais campos presentes no payload (`JsonSetter`).
- Exclusão em cascata (desde 2026-10-08, telas e API): ambiente (variáveis), parâmetro de ambiente (variáveis e programas), grupo de e-mail (usuários), objeto (operações, extensão REST, usuários e rota), conexão (autenticação e cabeçalhos) e tabela auditada (campo, acesso, notificação e expurgo) eliminam os filhos na mesma transação. Continua bloqueado o grupo de e-mail usado por parâmetro de e-mail ou notificação de auditoria (referência de outra tabela).
- Aplicação: exclusão bloqueada se houver `thl-objeto` da aplicação (igual ao `local-delete-record` do thl0020).
- Programa: PATCH cai no `update()` de `Service` → "Acao nao suportada" (17006).

## Valores sensíveis

- `isSensitive( codVariavel )` (método de instância do `ParametroVariavelService`): nome contém `SENHA`, `PASSWORD`, `SECRET`, `TOKEN`, `KEY` ou `CHAVE` (piloto; definitivo seria `ind-sensivel` no `.df`).
- GET devolve `"********"` (propriedade `MaskedValue` do Service) no `valor` dessas variáveis; PATCH com `"********"` mantém o valor gravado.
- O THL sempre grava o conteúdo das mensagens: `ParametroAmbienteMessage` sobrescreve `saveContentByType( typeContent, content )` e mascara o `valor` sensível (objeto ou array JSON) antes do `super`, usando uma instância direta do Service (`new ParametroVariavelService()` — o `createService()` depende da rota, que ainda não existe quando a entrada é gravada); conteúdo que não é JSON é gravado como veio.

## Observações

- Todas as chamadas (inclusive GET) geram `thl-mensagem`: incluir a aplicação `THL` no expurgo de mensagens (thl0222).
- Sem autorização por usuário (fora do escopo); vale a autenticação do PASOE/Datasul.
- PATCH sem controle de concorrência ("último grava vence").
- Exemplos e testes sem IP, host ou senha reais.

## Correção de pacotes — 01/10/2026

As definições de MensageriaMessage, AuditoriaService, MensageriaService e MensageriaConteudoService foram alinhadas aos caminhos atuais em thl-extensions. Os USING de AuditoriaMessage e MensageriaMessage apontam para thl-extensions.erp.thl.service. A alteração foi validada estaticamente, sem compilação OpenEdge.

Se thl-objeto.classe-objeto ainda contiver thl-lib.integration.messaging.inbound.message.MensageriaMessage, atualizar para thl-extensions.integration.thl.messaging.inbound.message.MensageriaMessage. Conferir também referências históricas em thl-mensagem.pacote utilizadas no reprocessamento. Nenhum cadastro do banco foi alterado pelo agente.

## Rotas de métricas (2026-10-03, não compilado)

> **Formato vigente de `mensageria/metricas`** (definido pelo responsável em 2026-10-03): array → objeto (`aplicacao`, `objeto`, `interna`) → array `mensagens` → objeto (`dispositivo`, `sitRequisicao`, `sitProcessamento`, `sitRetorno`, `dtCriacao`). As situações vão como **texto** (`Pendente`, `Erro`, `Sucesso`, `N/A`) e a situação geral **não** vai — o front deriva das três fases (alteração do responsável em 2026-10-03).
>
> ```json
> { "items": [ { "aplicacao": "NINAHUB", "objeto": "CHAMADO", "interna": false,
>   "mensagens": [ { "dispositivo": "Saida", "sitRequisicao": "Sucesso", "sitProcessamento": "N/A",
>                    "sitRetorno": "Sucesso", "dtCriacao": "2026-10-03T14:30:00.000" } ] } ],
>   "hasNext": false }
> ```
>
> - **`interna`** = `thl-aplicacao.ind-interna`, no objeto. Todas as aplicações entram (laço `thl-aplicacao` → `thl-objeto` → `thl-mensagem`, índice `idx-objeto-criacao`); o front decide se mostra ou separa o tráfego interno.
> - **Sem validação de usuário:** a rota não consulta `thl-objeto-usuario`; qualquer usuário autenticado vê as situações de todos os objetos.
> - Mensagem de aplicação ou objeto fora do cadastro não aparece; objeto sem mensagem no período também não.
> - Trechos mais abaixo que citam `interna` na linha ou uma linha por mensagem ficaram como histórico desta sessão.
> - `email/metricas` e `auditoria/metricas` seguem o mesmo desenho desde 2026-10-03 (decisão do responsável: **nenhuma rota de métricas valida acesso de usuário**):
>   - e-mail: array → objeto (`programa`, `paramAmbiente`) → `emails[]` → (`situacao` em texto: `Pendente`, `Sucesso`, `Erro`; `destino`; `dtEnvio`). `destino` é a lista de endereços como gravada em `thl-email.destino` (normalmente separada por vírgula; há origem que usa ponto e vírgula) — ⚠️ endereço de e-mail em rota sem validação de usuário, decisão do responsável. Agrupado pela própria leitura (`break by`), porque não há cadastro de programas.
>   - auditoria: array → objeto (`banco`, `tabela`, `nivelSensibilidade`) → `registros[]` → (`tipo` em texto: `Criacao`, `Atualizacao`, `Delecao`; `usuario`; `dtCriacao`). Percorre `thl-audit-tabela`; **não** consulta `thl-audit-tabela-acesso`. Tabela sem evento no período não aparece.

Decisões em [adr/metricas-conteudo-expurgo-mensagens.md](../adr/metricas-conteudo-expurgo-mensagens.md). Operação `metricas` (só GET) nas Messages de consulta; cada Service ganhou `getMetrics( dtIni as datetime, dtFin as datetime ): JsonArray`, ao lado do `get`, sem paginação e sem limite. O `get` das consultas não mudou.

| URL (`…/resourcen/…`) | Query string | Uma linha por | Atributos |
|---|---|---|---|
| `mensageria/metricas` | `dtCriacaoIni`, `dtCriacaoFin` | aplicação + objeto, com `mensagens[]` | `aplicacao`, `objeto`, `interna`, `mensagens[]` → `dispositivo` (`Entrada`/`Saida`), `sitRequisicao`, `sitProcessamento`, `sitRetorno` (texto), `dtCriacao` |
| `email/metricas` | `dtEnvioIni`, `dtEnvioFin` | programa + parâmetro de ambiente, com `emails[]` | `programa`, `paramAmbiente`, `emails[]` → `situacao` (texto), `destino`, `dtEnvio` |
| `auditoria/metricas` | `dtCriacaoIni`, `dtCriacaoFin` | banco + tabela, com `registros[]` | `banco`, `tabela`, `nivelSensibilidade`, `registros[]` → `tipo` (texto), `usuario`, `dtCriacao` |

Contrato para o front:

- **Data e hora:** somente `yyyy-MM-ddTHH:mm` (hora local, sem segundos e sem fuso), lido por `StringUtil:parseDateTime`; outro formato devolve erro (17006). Sem os parâmetros, vale as últimas 24 horas. Só estas rotas aceitam hora — as listagens continuam com `parseDate` (só data).
- **Resposta:** `{ "items": [...], "hasNext": false }`, como as demais; `total` não existe no backend.
- **Situações da mensageria:** `sitRequisicao`/`sitProcessamento`/`sitRetorno` em texto — `Pendente`, `Erro`, `Sucesso`, `N/A` (rótulos de `getStatusLabel`, os mesmos da listagem). `situacao` do e-mail e `tipo` da auditoria também vão em texto (`getLogEnvioLabel` e `getOperationLabel`, os mesmos rótulos das listagens).
- **Datas** na resposta em ISO com hora (`iso-date`).
- **`banco`** da auditoria vem como no cadastro (`thl-audit-tabela`), **sem** o prefixo `sh` — diferente da listagem, que devolve o valor do registro.
- **Acesso:** mensageria **sem validação de usuário** (todos os objetos cadastrados); auditoria também **sem validação de acesso** (todas as tabelas de `thl-audit-tabela`; qualquer usuário autenticado vê tabela, tipo de operação, usuário e data dos eventos — nunca o conteúdo). O filtro de sensibilidade por campo não se aplica (não há snapshot).
- **Período máximo** recomendado nas telas: 21 dias (retenção das mensagens com sucesso).
- **Fora das linhas:** `metodo` (um objeto tem vários), parâmetro de e-mail e grupo (o `thl-email` não guarda).
- A situação geral não é enviada nas métricas (retirada pelo responsável); o indicador `interna` vai no objeto.

Carga: `Utils\scripts\carga-thl-api-metricas.p` cria o `thl-objeto-parametro` da operação `metricas` (método GET) no objeto de cada rota, resolvido como no roteador (pela `thl-objeto-rota` ativa; sem cadastro, aplicação `TOTVS` e objeto = rota). Simulação por padrão.

As seis classes tocadas (`MensageriaService`, `EmailService`, `AuditoriaService` e as três Messages) estavam em UTF-8 com LF e um travessão no cabeçalho; foram regravadas em ISO-8859-1 com CRLF (travessão trocado por hífen).

### Situação geral na mensageria (fase 4, 2026-10-03, não compilado)

- `mensageria/metricas`: chegou a levar `sitMensagem`; retirado pelo responsável em 2026-10-03 (ver o formato vigente no início da seção de métricas).
- Listagem `mensageria`: cada item ganhou `statusMensagem` (texto, como os demais status).
- Depende do campo `thl-mensagem.sit-mensagem` do delta; mensagens antigas ficam como 1 até rodar `Utils\scripts\acerto-thl-sit-mensagem.p`.

### Gravação de conteúdo no cadastro de parâmetros do objeto (fase 5, 2026-10-03, não compilado)

- `objeto-parametro`: novo campo `tipoGravaConteudo` (1 Sempre, 2 Somente em erro, 3 Nunca) na listagem, no POST e no PATCH; fora do domínio → 17006 (`ObjetoParametroService.validateRecord`).
- `carga-thl-api-metricas.p` cria a operação `metricas` com `tipo-grava-conteudo` = 2: a resposta aberta das métricas não é gravada em `thl-mensagem-conteudo`. Onde a carga já rodou antes desta mudança, ajustar o campo pela tela ou pela API.
- O cabeçalho de `ParametroAmbienteMessage` e `ConexaoRestMessage` ainda diz "o THL sempre grava o conteúdo das mensagens"; passa a depender da opção da operação. A máscara continua valendo para o que for gravado.

### Aplicação interna e retenção (fases 6 e 7, 2026-10-03, não compilado)

- `aplicacao`: novo campo `indInterna` (lógico) na listagem, no POST e no PATCH.
- `objeto`: novos campos `retencaoDiasSucesso` e `retencaoDiasErro` (inteiros; 0 = não expurga; negativo → 17006).
- `mensageria/metricas`: cada linha ganhou `interna` (lógico) — verdadeiro quando a aplicação está em `thl-aplicacao` com `ind-interna`; aplicação fora do cadastro conta como externa. Formato substituído no mesmo dia — ver o formato vigente no início da seção de métricas.
- `carga-thl-api-cadastros.p`: cria a aplicação `THL` já como interna e marca a existente (contada como alterada no log).
- Todos dependem dos campos do delta `Database\delta-thl-2026-10-03.df`.

## Chave validada só no Service (2026-10-03, não compilado)

Decisão do responsável: a Message só **pega** as referências; quem monta a chave valida a chave.

- As 10 Messages de cadastro do THL (5 de agregado e `Ambiente`, `Aplicacao`, `ConexaoRestPath`, `InboundRota`, `EmailParametro`) **não sobrescrevem mais** `getRequiredFields()`. Ficou o padrão de `InboundMessage` (lista vazia).
- Os 21 Services de cadastro conferem a presença dos campos da chave em `initialize()`, antes de posicionar o registro: `JsonUtil:requireProperties( inContext, '<campos da chave>', <classe> )`. Campo ausente → `ThlError` 17006 "Campo obrigatorio nao informado: …", com todos os ausentes de uma vez. As listas são as mesmas que as Messages exigiam.
- A validação de conteúdo (campo vazio, registro relacionado, duplicidade) já era do Service e não mudou.
- O GET não passa por `initialize()` (a Message chama `get` direto), então não exige chave — como antes.
- Trechos anteriores desta nota que dizem "`getRequiredFields()` = campos da chave" ou citam o `case` de `getRequiredFields` nas Messages de agregado ficaram como histórico: nas Messages de agregado restam dois `case` por rota (`createService` e `methodGet`).

## GET pelo `execute` do Service (2026-10-03, não compilado)

Decisão em [adr/get-no-execute-do-service.md](../adr/get-no-execute-do-service.md).

- Os 24 Services com consulta implementam `consult()`: leem os filtros de `queryParameters` (mesmos nomes e padrões de antes) e chamam o `get`/`getMetrics` que já existia.
- `MensageriaService:consult()` desvia pela operação: `conteudo` → `MensageriaConteudoService:get`, `metricas` → `getMetrics`, sem operação → listagem. `EmailService` e `AuditoriaService`: `metricas` ou listagem.
- As 13 Messages não têm mais `methodGet` nem `appendItems`. Nas de agregado ficou só o `createService()` por rota; `MensageriaMessage`, `EmailMessage` e `AuditoriaMessage` agora devolvem o Service em `createService()`.
- A lista sai do Service como `{ items, hasNext: false }`.
- Trechos anteriores desta nota que descrevem `methodGet`, `appendItems`, `getQueryParamDateTime` nas Messages ou o `case` de `methodGet` ficaram como histórico.

## Classes do objeto no cadastro (2026-10-04, não compilado)

- Rota `objeto`: novos campos `classeProcessor` e `classeService` na listagem, no POST e no PATCH.
- `ObjetoService.validateRecord`: `classeProcessor` obrigatória; `classeService` obrigatória em objeto de entrada (`sentidoFluxo` = false). Erro 17006. A mesma regra está no `Pi-validate` do `thl0021-v01.w`.
- Depende do delta `Database\delta-thl-2026-10-04.df`. Lidos em execução pelo `InboundConfigLoader` (ver a seção seguinte).

## Message → Processor → Service (2026-10-04, não compilado)

Estado atual do sistema `thl` — 33 classes (inventário em disco): 25 Services, 6 Processors e 2 Messages.

**Processors** — `Fontes\thl-extensions\integration\thl\messaging\inbound\process\`, pacote `thl-extensions.integration.thl.messaging.inbound.process`. Cada um só sobrescreve `resolveService( operation )`: sem operação → Service do cadastro; operação conhecida → Service do filho; outra → `ThlError` "Operacao nao reconhecida".

| Objeto (aplicação `THL`) | Message | Processor | URL → Service |
|---|---|---|---|
| `AMBIENTE` | padrão | padrão | `ambiente` → `AmbienteService` |
| `PARAMETRO` | `ParametroAmbienteMessage` (máscara) | `ParametroProcessor` | `parametro-ambiente` → `ParametroAmbienteService` · `parametro-ambiente/variavel` → `ParametroVariavelService` · `parametro-ambiente/programa` → `ParametroProgramaService` |
| `APLICACAO` | padrão | padrão | `aplicacao` → `AplicacaoService` |
| `AUDIT-TABELA` | padrão | `AuditoriaTabelaProcessor` | `auditoria-tabela` → `AuditoriaTabelaService` · `/acesso` · `/campo` · `/notificacao` · `/expurgo` → o Service de cada filho |
| `CONEXAO-REST` | `ConexaoRestMessage` (máscara) | `ConexaoRestProcessor` | `conexao-rest` → `ConexaoRestService` · `/autenticacao` → `ConexaoRestAutenticacaoService` · `/header` → `ConexaoRestHeaderService` |
| `CONEXAO-REST-PATH` | padrão | padrão | `conexao-rest-path` → `ConexaoRestPathService` |
| `OBJETO` | padrão | `ObjetoProcessor` | `objeto` → `ObjetoService` · `objeto/parametro` → `ObjetoParametroService` · `objeto/usuario` → `ObjetoUsuarioService` |
| `EMAIL-PARAMETRO` | padrão | padrão | `email-parametro` → `EmailParametroService` |
| `GRUPO-EMAIL` | padrão | `GrupoEmailProcessor` | `grupo-email` → `GrupoEmailService` · `grupo-email/usuario` → `GrupoEmailUsuarioService` |
| mensageria | padrão | `MensageriaProcessor` | `mensageria` e `mensageria/metricas` → `MensageriaService` · `mensageria/conteudo` → `MensageriaConteudoService` |
| e-mail | padrão | padrão | `email` e `email/metricas` → `EmailService` |
| auditoria | padrão | padrão | `auditoria` e `auditoria/metricas` → `AuditoriaService` |

"padrão" = `thl-lib.integration.messaging.inbound.core.InboundMessage` / `thl-lib.integration.messaging.inbound.core.Processor`.

**Contrato para o front (mudou):** as URLs dos filhos passaram de `pai-filho` para `pai/filho`. Corpo, filtros do GET e respostas são os mesmos.

| Antes | Agora |
|---|---|
| `parametro-variavel` · `parametro-programa` | `parametro-ambiente/variavel` · `parametro-ambiente/programa` |
| `objeto-parametro` · `objeto-usuario` | `objeto/parametro` · `objeto/usuario` |
| `conexao-rest-autenticacao` · `conexao-rest-header` | `conexao-rest/autenticacao` · `conexao-rest/header` |
| `auditoria-tabela-acesso` · `-campo` · `-notificacao` · `-expurgo` | `auditoria-tabela/acesso` · `/campo` · `/notificacao` · `/expurgo` |
| `grupo-email-usuario` | `grupo-email/usuario` |

**Messages:** ficaram `ParametroAmbienteMessage` e `ConexaoRestMessage` (só a máscara de `saveContentByType`, sem `createService()`). As outras 11 estão em `…\messaging\inbound\message\` como `.cls.old`: Ambiente, Aplicacao, ConexaoRestPath, InboundRota, EmailParametro, Auditoria, Email, Mensageria, AuditoriaTabela, Objeto e GrupoEmail.

**Services:** `MensageriaConteudoService` ganhou `consult()`; `MensageriaService:consult()` não trata mais `conteudo`. Verbos públicos em todos.

**Cadastros e scripts** (`Utils\scripts\`, todos em simulação por padrão):

| Script | O que faz |
|---|---|
| `acerto-thl-objeto-classes.p` | Objetos de **entrada** já cadastrados (qualquer aplicação): preenche processor e service a partir do nome curto da classe de message atual; Message retirada vira a padrão. Lista "sem regra" e "sem uso". **Rodar primeiro.** |
| `carga-thl-api-cadastros.p` | Aplicação THL (interna), os 10 objetos com as três classes, quatro parâmetros por método, rotas; **desativa** as rotas próprias dos filhos; avisa dos objetos de filhos sem uso |
| `cadastrar-thl-api-rotas.ps1` / `.cmd` | O mesmo pelos endpoints (`objeto`, `objeto/parametro`, `objeto/rota`); `-Executar` grava; `-EliminarObsoletos` elimina os objetos próprios dos filhos |
| `carga-thl-api-metricas.p` | Sem mudança: linha própria da operação `metricas` |

Rota de filho que ficasse ativa apontando para o objeto do pai seria lida como rota **sem operação** e atendida pelo Service do pai — por isso a carga desativa em vez de reapontar.

Decisão e ordem de implantação: [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

**Postman (coleção Nitro, `TOTVS > Projeto > THL-Library > THL`) — atualizado em 2026-10-04 pelo conector:** as 41 requisições dos filhos passaram para a URL `pai/filho` (as subpastas mantêm os nomes); o POST de `objeto` ganhou `classeProcessor`, `classeService` e as retenções; o POST de `aplicacao`, `indInterna`; o POST de `objeto/parametro`, `tipoGravaConteudo`; subpasta nova **Metricas** com `GET Mensageria`, `GET Email` e `GET Auditoria`. Nada foi apagado. Não há subpasta de `grupo-email` nem de `grupo-email/usuario` na coleção. Os exemplos de resposta salvos nas requisições ainda mostram a URL antiga.

## Operação: ação, classes e extensão REST na API (2026-10-05, não compilado)

Rota `objeto/parametro` (`ObjetoParametroService`), depende do delta `delta-thl-2026-10-05.df`:

| Propriedade | Regra |
|---|---|
| `acao` | 1 criar, 2 alterar, 3 eliminar, 4 consultar. Parte da chave. **Opcional no JSON:** no POST, sem ela, vem do `metodo`; no PATCH e no DELETE, sem ela, vale a única linha da operação — havendo mais de uma ação, erro pedindo a ação |
| `classeObjeto`, `classeProcessor`, `classeService` | Sobreposição por operação; em branco vale a do objeto |
| `metodo` | Lido da extensão REST (ou da operação, se não houver); gravado nos dois |
| `camposObrigatorios` | Array de texto. Na resposta, sempre array (vazio se não houver) |
| `chaveExterna` | Array de texto; `[]` desliga; `null` = padrão da mensagem (`externalID`) |
| `referenceCode` | Passou a ter cinco partes: estabelecimento#aplicação#objeto#operação#ação |

Operação e extensão REST são gravadas na mesma transação; a extensão é criada quando o objeto é REST e eliminada com a operação. As cargas `.p` gravam a ação; a extensão das linhas existentes é criada pelo `acerto-thl-objeto-classes.p`.

**Front:** o formulário de operação precisa do campo ação (ou enviar o método, que resolve) e pode exibir os campos novos; a lista usa o `referenceCode` novo. Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md).

**Postman (2026-10-05):** em `Objeto Parametro`, o POST, o PATCH e o DELETE passaram a enviar `acao` (exemplo com operação em branco e ação 4); o POST ganhou as classes por operação, `camposObrigatorios` e `chaveExterna`.

## Rota: início da operação (2026-10-06, não compilado)

Rota do objeto (então `inbound-rota`, hoje `objeto/rota`): propriedade `inicioOperacao` (inteiro, padrão 0) na listagem, no POST e no PATCH; validação 0 ou entre 2 e o número de segmentos de `rotaPublica`. Postman: POST de `Inbound Rota` com o campo.

## Rota do objeto na API (2026-10-06, não compilado)

Rota do objeto (na época URL `inbound-rota` e `InboundRotaService`; **hoje `objeto/rota` e `ObjetoRotaService`**, ADR §13), tabela `thl-objeto-rota`: chave `aplicacao` + `objeto` (era `rota`); propriedades `rotaPublica`, `indAtivo`, `inicioOperacao`; saíram `rota` e `descricao`. GET com `aplicacaoIni/Fin` e `objetoIni/Fin`. Uma rota por objeto: POST em objeto que já tem rota devolve erro (**substituído em 2026-10-13**: ver a seção seguinte). Objetos da aplicação `THL` no padrão NomeNomeNome (`Ambiente`, `ParametroAmbiente`, `AuditoriaTabela`, `ConexaoRest`, `ConexaoRestPath`, `Objeto`, `EmailParametro`, `GrupoEmail`, `Aplicacao`); as rotas públicas não mudaram. Cargas em `Database\carga\thl\` (`thl010.d`, `thl011.d`, `thl032.d`, `thl021.d`).

## Operação do objeto na API: só `metodo` (2026-10-08, não compilado)

`ObjetoParametroService`: a chave é estabelecimento, aplicação, objeto, operação e **`metodo`**; saiu a propriedade `acao` do JSON de entrada e de saída. Sem `metodo` na alteração/exclusão vale a única linha da operação; com mais de uma, erro pedindo o método. `Utils\scripts\cadastrar-thl-api-rotas.ps1` elimina pelo `metodo`.

## Métricas fora do `consult()` (2026-10-08, não compilado)

`MensageriaService`, `AuditoriaService` e `EmailService` implementam `IMetricsService`: `consult()` é a listagem e `consultMetrics()` as métricas (padrão: últimas 24 horas). `MensageriaProcessor` herda de `MetricsProcessor`. Objetos `Auditoria` e `Email` passam a usar o `MetricsProcessor` no cadastro.

## Processors de agregado retirados (2026-10-08, não compilado)

`MensageriaProcessor`, `ParametroProcessor`, `ObjetoProcessor`, `ConexaoRestProcessor`, `AuditoriaTabelaProcessor` e `GrupoEmailProcessor` viraram `.cls.old`. O Service de cada filho (`variavel`, `programa`, `parametro`, `usuario`, `autenticacao`, `header`, `acesso`, `campo`, `notificacao`, `expurgo`, `conteudo`) fica na linha da operação (`thl-objeto-parametro.classe-service`); os objetos usam o Processor padrão (Mensageria: `MetricsProcessor`). Base existente: `Utils\scripts\acerto-thl-operacao-service.p`. Ver [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

## Rota: `objeto/rota` (2026-10-08, não compilado)

`InboundRotaService` virou `ObjetoRotaService` e a API passou de `inbound-rota` para **`objeto/rota`** (operação `rota` do objeto `Objeto`, linha própria em `thl-objeto-parametro` com o Service em `classe-service`). O objeto `InboundRota` sai do cadastro. Propriedades iguais às de 2026-10-06. Ver [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §13.

## Classes só na linha da operação (2026-10-08, não compilado)

`ObjetoParametroService` copia do objeto as classes que vierem em branco (criação e alteração); `ObjetoService`, ao alterar as classes do objeto, leva a mudança às linhas que ainda têm a antiga. Postman (`Objeto > Objeto Parametro`): operação em branco no example e classes copiadas. Ver [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §14.

## Rota do objeto: chave tripla (2026-10-13, não compilado)

`thl-objeto-rota` passou a ter chave **`aplicacao` + `objeto` + `rotaPublica`**: o objeto pode ter várias rotas. `idx-rota-publica` continua único no banco todo (a URL só traz a rota). Na API `objeto/rota`: `rotaPublica` é chave (obrigatória em POST, PATCH e DELETE; PATCH só altera `indAtivo` e `inicioOperacao`; trocar o caminho = eliminar e criar), o GET ganhou os filtros `rotaPublicaIni` e `rotaPublicaFin` e o `referenceCode` virou `aplicacao#objeto#rotaPublica`. Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §16.

## Data e hora nos filtros das listagens de mensageria, e-mail e auditoria (2026-10-13, não compilado)

As listagens `mensageria` (`dtCriacaoIni/Fin` e `dtIntegracaoIni/Fin`), `email` (`dtEnvioIni/Fin`) e `auditoria` (`dtCriacaoIni/Fin`) leem as datas com `queryParameters:getDateTime`, no mesmo formato das métricas: **`yyyy-MM-ddTHH:mm`** (16 caracteres, sem segundos nem fuso; hora local do servidor). Padrão das três: **agora − 24 horas até agora** (`DateTimeUtil:addHours( now, -24 )` e `DateTimeUtil:currentDateTime()`); antes era hoje − 3 dias (mensageria) e hoje − 30 dias (e-mail e auditoria), sempre até amanhã. Exemplo: `…/mensageria?aplicacaoIni=TOTVS&aplicacaoFin=TOTVS&objetoIni=Documento&objetoFin=Documento&dtCriacaoIni=2026-10-12T00:00&dtCriacaoFin=2026-10-13T00:00`. Só os três Services mudaram (`consult()`); `StringUtil` e `QueryParameters` não.

⚠️ **A data simples (`yyyy-MM-dd`) deixa de valer nas três listagens** e dá erro 17006 ("Informe no formato yyyy-MM-ddTHH:mm"). O monitor web (mensageria, e-mail e auditoria: filtro avançado e atalhos dos cartões de métricas) ainda envia só a data e precisa passar a enviar data e hora. Quem não envia filtro de data passa a ver só as últimas 24 horas (e-mail e auditoria viam 30 dias).

## Classes por sentido do fluxo (objeto e operação) (2026-10-15, não compilado)

`ObjetoService:validateRecord`: `classeObjeto` sempre obrigatória; `classeProcessor` e `classeService` só em objeto de **entrada** (`sentido-fluxo = no`), onde também são obrigatórias (antes o processor era exigido em qualquer sentido). `ObjetoParametroService:validateRecord`, depois de copiar do objeto as classes em branco: `classeObjeto` obrigatória; processor e service obrigatórios quando o objeto não é de saída. Mesma regra das telas (ver [thl/camada-datasul.md](../thl/camada-datasul.md)). Os padrões são lidos por `new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:<membro> )`, com o enum `thl-extensions.erp.thl.enum.ClassVariableEnum` (`MENSAGEM_ENTRADA`, `MENSAGEM_SAIDA`, `PROCESSOR_ENTRADA`, `SERVICE_ENTRADA`; o código da variável é o nome do membro em minúsculas com `_` virando `.`). O parâmetro (`thl.classe`) não aparece nas chamadas: o `EnvironmentResource` o acha pelo **programa** que chama, vinculado na aba Programa do thl0002 (`ObjetoService`, `ObjetoParametroService`, `thl0021-v01`, `thl0022a-v01`, `thl0022a-v06`); ambiente atual e, se não achar, `*`. Sem vínculo ou sem a variável, a chamada (com `no-error`) deixa a classe em branco. A tela thl0021 (`pi-padroes-classes`) usa o mesmo caminho. Na **criação** do objeto, `ObjetoService:fillDefaultClasses` preenche a classe em branco com o padrão do thl0002 (parâmetro `thl.classe`, ambiente `*`: `mensagem.entrada` ou `mensagem.saida`, e, na entrada, `processor.entrada` e `service.entrada`), como a tela thl0021; sem o parâmetro a classe segue em branco e a validação recusa. A operação (`objeto/parametro`, `ObjetoParametroService:fillClassesFromObject`) copia do objeto o que vier em branco e, se ainda sobrar branco (objeto sem a classe), aplica o mesmo padrão do thl0002 (mensagem pelo sentido do objeto; processor e service só na entrada).

**Contrato do payload só em objeto de entrada (2026-10-15, não compilado).** `ObjetoParametroService:saveRestExtension` segue a aba REST do thl0022 (`thl0022a-v05.w`): `camposObrigatorios` e `chaveExterna` só são lidos na entrada (`InboundConfigLoader:setContract`). Em objeto de **saída** a extensão REST nasce sem contrato; lista **preenchida** é recusada com erro 17006, e lista vazia (`[]`) ou nula é aceita e ignorada. Vale em POST e PATCH. Valores já gravados não são apagados.

**Persistência só em operação de saída (2026-10-15, não compilado).** `ObjetoParametroService:validateRecord` segue a aba Persistência do thl0022 (`thl0022a-v03.w`): em objeto de **entrada**, `indPersistente`, `frequenciaExecucao`, `qtdDiasPersist` e `qtdTentativasPersist` com valor diferente de falso ou zero são recusados com erro 17006 (`hasPersistenceInput`, que lê o JSON com `JsonSetter`); `false`, `0`, nulo e ausente são aceitos. Valem POST e PATCH (a validação desfaz a gravação). Os campos de log e `tipoGravaConteudo` valem nos dois sentidos. Nota: esses campos de persistência ainda não são lidos por nenhum código de execução.

**Servidor só em operação Batch ou Agendar (2026-10-15, não compilado).** `ObjetoParametroService:validateRecord` segue a aba Servidor do thl0022 (`thl0022a-v04.w`): com `formaExecucao` 1 (Online), `servidorExecucao` preenchido é recusado (erro 17006); em branco é aceito. Vale na criação e na alteração, sobre o valor final do registro.

**Padrões dos campos na criação pela API (2026-10-15, não compilado).** `ObjetoService:fillDefaultFields` e `ObjetoParametroService:fillDefaultFields`, no `create()`, preenchem o registro novo com os padrões do thl0002 (`FieldDefaultEnum`, mesmo parâmetro e mesmos programas vinculados das telas) **antes** do `mapFields`, então o que vier no JSON sempre prevalece. Objeto: `ind-inativo`, `ind-gera-historico`, `sentido-fluxo`, `modelo-integracao`, `retencao-dias-sucesso`, `retencao-dias-erro` e `programa-consulta`. Operação: `ind-inativo`, `ind-gera-historico`, `tipo-grava-conteudo`, `forma-execucao`, `ind-persistente`, `frequencia-execucao`, `qtd-dias-persist`, `qtd-tentativas-persist`, `tipo-log-requisicao`, `tipo-log-retorno`, `ind-mensagem-simples`, `cod-param-ambiente`, `cod-param-ambiente-destino` e `cod-servid-exec` (o `metodo` é chave e não tem padrão na API). Sem o vínculo do programa a leitura é ignorada; variável ausente ou em branco mantém o valor inicial do banco; valor que não converte (`yes`/`no` ou inteiro) lança erro 17006 com o nome da variável. Para isso o `EnvironmentResource` ganhou as leituras tipadas `getEnvironmentVariable( enum, defaultValue as logical )` `( enum, defaultValue as integer )` e `( enum, defaultValue as character )`. Servidor padrão com forma Online é recusado pela regra do servidor. PATCH não aplica padrão.

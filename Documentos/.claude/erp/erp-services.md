---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, erp, service]
updated: 2026-10-13
---

# Pacote: erp (core · enum · service)

> ⚠️ **2026-10-04 — Message → Processor → Service.** O `execute` saiu do `Service` e foi para `thl-lib.integration.messaging.inbound.core.Processor`; os verbos do Service ficaram públicos. Assinaturas vigentes na seção final desta nota; decisão em [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

> **Reescrito em 2026-09-24 a partir do código** (`Fontes\thl-lib\erp\**`, 27 classes). Substitui a versão de 2026-08-24, que descrevia uma interface `IService` inexistente, `ServiceResponse:failure()`, `EmitenteService:buscarEmitente/buscarLocalEntrega` e classes de nomes antigos (`FreteService`, `BusinessObjectService`, `ApplicationProgramInterfaceService`, `NinaNotaFiscal*`).
> `LpcoService` e `FretePrevistoService`/`SituacaoFreteEnum` saíram deste pacote em 2026-09-24 → ver `extensions/automatizador.md` e `extensions/dvv.md`.

## Visão geral

> Novos Services: fontes ABL (`.cls`, `.p`, `.w`, `.i`) sempre em **ISO-8859-1** — nunca UTF-8 nem com BOM (ver `convencoes.md`).

Contrato Message ↔ Service: cada `InboundMessage` devolve um `Service` em `createService()` (Factory Method), e o fluxo padrão chama `Service:execute( action, operation, context, output referenceCode )`. **Não existe interface** — o contrato é a classe abstrata `Service`.

```text
Service (abstract — Template Method)
├── BusinessObject (abstract)              ← BOFs TOTVS (RowErrors)
│   ├── DocumentoService · RequisicaoService · ItemRequisicaoService · UsuarioService
│   └── NotaFiscalBaseService (abstract)   ← XML NF-e, SEFAZ, impressão
│       ├── NotaFiscalService              (NF direta)
│       └── NotaFiscalPorEmbarqueService   (NF por embarque)
├── ApplicationProgrammingInterface (abstract) ← APIs .p TOTVS (tt-erro)
│   └── EmbarqueService
└── (herança direta — serviços de consulta)
    CentroCustoService · EmitenteService · ItemService · TransporteService
    LocalEntregaService · SaldoService
    Consultas THL em thl-extensions.erp.thl.service:
    AuditoriaService · EmailService · MensageriaService · MensageriaConteudoService
```

| Classe | Pacote | Tipo | Responsabilidade | Usado por (Message) |
|---|---|---|---|---|
| Service | `erp.core` | abstract | Dispatcher `execute()` + defaults que lançam "Acao nao suportada" | todas as Messages inbound |
| BusinessObject | `erp.core` | abstract | Base para BOFs (`RowErrors`, `throwRowErrorsIfAny`) | Services de BOF |
| ApplicationProgrammingInterface | `erp.core` | abstract | Base para APIs `.p` (`tt-erro`, `throwApiErrorsIfAny`) | EmbarqueService |
| ServiceResponse | `erp.core` | utilitária estática | Monta `{success, action, code, referenceCode, message}` | Service:buildResponse |
| ActionEnum | `erp.enum` | enum | `Criado=1`, `Atualizado=2`, `Deletado=3` | Service, InboundMessage |
| SituacaoEmbarqueEnum | `erp.enum` | enum | `ATIVA=1` | EmbarqueService |
| SituacaoNfeEnum | `erp.enum` | enum | `AUTORIZADA=3`, `DENEGADA=4`, `REJEITADA=5`, `CANCELADA=6`, `INUTILIZADA=7` | Services de NF |
| DocumentoService | `erp.service` | BOF | Documento de estoque (`docum-est`) via boin090/176/092/366 | DocumentoMessage (+ LoogAiDocumentoService) |
| RequisicaoService | `erp.service` | BOF | Requisição + itens via boin385/boin168 | RequisicaoMessage |
| ItemRequisicaoService | `erp.service` | BOF | Exclusão de itens de requisição via boin168 | RequisicaoMessage |
| UsuarioService | `erp.service` | BOF | Usuário Datasul completo (mestre, extensão, grupos, empresas, universo) | UsuarioMessage |
| NotaFiscalBaseService | `erp.service` | abstract (BOF) | Núcleo comum de NF: XML (ft0910rp), SEFAZ com retry (ft0915a/bodi135na), impressão (esft1932i) | — |
| NotaFiscalService | `erp.service` | BOF | NF direta: geração item a item (bodi317*), XML, SEFAZ, impressão, notificação, processamento encadeado | NotaFiscalMessage (rota `notafiscal`), NinahubNotaFiscalService |
| NotaFiscalPorEmbarqueService | `erp.service` | BOF | NF por embarque (bodi317/ft4001a) + XML, SEFAZ, impressão, notificação | NotaFiscalMessage (rota `notafiscal/embarque`) **Diretório dos arquivos (2026-10-22, não compilado):** a variável `diretorio.nota.fiscal` do thl0002 é guardada em `inContext:diretorio` no `initialize` (o valor do cliente é descartado); `getDirectory()` (hook `protected` da `NotaFiscalBaseService`, padrão `session:temp-directory`) devolve esse diretório, e `exportNfeXml` e `printInvoiceDocument` o usam. O `esft1932rp.p` (RPW, fora do repositório) lê a mesma variável para achar o `.doc`. Só a NF por embarque usa por enquanto. |
| EmbarqueService | `erp.service` | API | Criação, alteração de transporte (PATCH) e exclusão de embarque via eqapi300 | EmbarqueMessage (+ LoogAiEmbarqueService) |
| AuditoriaService | `thl-extensions.erp.thl.service` | consulta | Registros de auditoria com snapshots filtrados por acesso | AuditoriaMessage |
| CentroCustoService | `erp.service` | consulta | Centro de custo (`ems.ccusto`) | CentroCustoMessage |
| EmailService | `thl-extensions.erp.thl.service` | consulta | Registros `thl-email` | EmailMessage |
| EmitenteService | `erp.service` | consulta | Emitente | EmitenteMessage |
| LocalEntregaService | `erp.service` | consulta | Local de entrega (`loc-entr`) | EmitenteMessage |
| ItemService | `erp.service` | consulta | Item | ItemMessage |
| SaldoService | `erp.service` | consulta | Saldo disponível por estabelecimento + item | ItemMessage |
| TransporteService | `erp.service` | consulta | Transportador (`transporte`) | TransporteMessage |
| MensageriaService | `thl-extensions.erp.thl.service` | consulta | Mensagens `thl-mensagem` (filtros do monitor thl0120) | MensageriaMessage |
| MensageriaConteudoService | `thl-extensions.erp.thl.service` | consulta | Conteúdo (`thl-mensagem-conteudo`) de uma mensagem | MensageriaMessage |

---

## erp.core

### Service (abstract)

**Caminho:** `thl-lib\erp\core\Service.cls` · **Namespace:** `thl-lib.erp.core.Service`

**Propriedades:** `inContext` (JsonObject, public get / protected set), `outContext` (JsonObject, public get / protected set), `operation` (character, protected).

| Assinatura | Descrição |
|---|---|
| `method public JsonObject execute( input action as ActionEnum, input operation as character, input context as JsonObject, output referenceCode as character )` | Atribui `inContext`/`operation`; chama `initialize()`; despacha `case action` → `create()`/`update()`/`delete()` (outra ação → `ThlError`); `referenceCode = loadReferenceCode()`; devolve `buildResponse( action, referenceCode )`. |
| `method protected void initialize()` | Hook vazio (posicionar registro, ler contexto). |
| `method protected void create()` / `update()` / `delete()` | Defaults lançam `ThlError` "Acao nao suportada" — a subclasse sobrescreve só os verbos que suporta. |
| `method protected JsonObject buildResponse( action as ActionEnum, referenceCode as character )` | `ServiceResponse:success( getEntityName(), action, referenceCode )`. |
| `method protected abstract character loadReferenceCode()` | Código de referência gravado na mensagem. |
| `method protected abstract character getEntityName()` | Nome da entidade usado na resposta. |

### BusinessObject (abstract, inherits Service)

`define protected temp-table RowErrors`; propriedade `error` (`ErrorHandler`). Métodos `throwRowErrorsIfAny( methodName )` e sobrecarga com mais parâmetros: traduzem os erros devolvidos pelas BOFs (`devolveErros*`) em `ThlError`.

### ApplicationProgrammingInterface (abstract, inherits Service)

`define protected temp-table tt-erro`; propriedade `error` (`ErrorHandler`). `throwApiErrorsIfAny( methodName )` (+ sobrecarga): traduz o `tt-erro` de `pi-devolve-tt-erro` em `ThlError`.

### ServiceResponse

| Assinatura | Descrição |
|---|---|
| `method public static JsonObject success( messageText as character, actionName as ActionEnum, referenceCode as character )` | Converte a ação em texto e delega. |
| `method public static JsonObject success( messageText as character, actionName as character, referenceCode as character )` | `{ success: true, action, code: 200, referenceCode, message }`. |

Não existe `failure()` — erros são exceções (`ThlError`) tratadas pela camada de mensageria.

---

## erp.service — serviços transacionais

### DocumentoService (BusinessObject)
`create()` → `prepareDocumentData( inContext )` (hook protected, especializado por `LoogAiDocumentoService`) + `executeBOFs()` (boin090/176/092/366). Itens enviados à boin176 **um a um** (`tt-item-doc-est-aux`: `setRecord` → `recalculateItemTaxes( h-boin176 )` → `createRecord`); o hook protected `recalculateItemTaxes` chama `recalculateImpostoICMS` (ICMS/IPI/ISS, mesma chamada do RE1001) a partir dos campos do item. Temp-tables protected `tt-docum-est`, `tt-item-doc-est`, `tt-rat-docum`, `tt-dupli-apagar` (com `serialize-name`). `loadReferenceCode()` a partir de `b-docum-est`.

### RequisicaoService (BusinessObject)
`create()` → `prepareRequisicaoData( context )` + `executeBOFs()` (boin385 cabeçalho, boin168 itens; campos do cabeçalho propagados aos itens). `delete()` suportado. Temp-tables `tt-requisicao`, `tt-it-requisicao`.

### ItemRequisicaoService (BusinessObject)
Só `delete()`: recebe `nr-requisicao` + lista de itens (sequência + `it-codigo`) e exclui cada item via boin168 (`repositionRecord` pelo rowid).

### UsuarioService (BusinessObject)
`create()` monta e grava, via BOFs, `usuar_mestre`, `usuar_mestre_ext`, `usuar_grp_usuar`, `segur_empres_usuar` e `fnd_usuar_univ`. Hooks protected: `mapUserMaster`, `mapUserExtension`, `mapUserGroup`, `mapUserCompany`, `mapUserUniverse` (todos com `JsonSetter`).

### EmbarqueService (ApplicationProgrammingInterface)
`create()`, `update()` e `delete()` via `eqapi300` (propriedade `eqapi300` handle). `update()` (PATCH, `ind-oper = OPER_ALTER_EMBARQ`) copia o `embarque` atual para `tt-embarque` e sobrepõe só os campos presentes no payload: `nomeTransportadora` → `nome-transp`, `motorista`, `placa`, `ufPlaca` → `uf-placa` (exige `codigoEmbarque` e ao menos um campo de `TRANSPORT_FIELDS` — hook `validateTransportContext`); a API só é chamada se vier algum campo de `TRANSPORT_FIELDS`, o que permite a extensões sobrescrever `update()` com `super` e aceitar PATCH só com campos próprios (ex.: `LoogAiEmbarqueService` grava `ext-embarque`). A checagem de campos presentes usa `JsonUtil:hasAnyProperty( inContext, lista )` ([util.md](../util/util.md)). Demais hooks protected para extensões: `resolveEstablishment`, `prepareShipmentData`, `resolveIntegrationUser`, `resolveShipmentDate`, `resolveSequence`, `resolveDeliveryDate`, `prepareWarehouseData` (vazio na base — a regra de depósito por `param-dep-exc` está no `LoogAiEmbarqueService`), `prepareDeliveryData`, `validateShipmentContext`. Especializado por `LoogAiEmbarqueService`.

### NotaFiscalBaseService (abstract, BusinessObject)
Propriedades protected `inPayload` (JsonObject) e `outPayload` (JsonArray), preparadas em `initialize()`. Métodos protected: `exportNfeXml(...)`, `runSefazAuthorization(...)` (retry), `printInvoiceDocument()`, `addInvoicePayload(...)`, `getStatusMessageKey()`, `getValidFileKey()`, `getSefazMaxAttempts()`, `getSefazPauseSeconds()`, `getEnvironmentIntegerCapped( variableCode, … )` (limites lidos de variáveis de ambiente).

### NotaFiscalService (NF direta)
`create()` despacha por `operation`: `geracao` → `createInvoice()`; `geracao-xml`; `autorizacao-sefaz`; `impressao` → `printInvoiceWorker()`; `notificacao`; `processamento` → `processSteps()` (tudo em sequência numa transação, com `pause` da variável `intervalo.processamento` antes da SEFAZ — espera síncrona por restrição de plataforma). **Hooks protected** (sobrescritos por `NinahubNotaFiscalService`): `createInvoice`, `resolveNature`, `resolveNatureItem( item )`, `resolveTransport`, `resolveSalesChannel`, `resolverObservation`, `getPrice( item )`, `printInvoiceWorker`.

### NotaFiscalPorEmbarqueService
`create()` por `operation`: `geracao` (`createByShipment()` + XML), `geracao-xml`, `autorizacao-sefaz`, `impressao`, `notificacao`. Workers são **private** (não há hooks de extensão).

---

## erp.service — serviços de consulta

Herdam `Service` direto, não usam `execute()` para leitura: a Message chama o `get(...)` público.

| Classe | Assinatura | Tabelas |
|---|---|---|
| AuditoriaService | `get( pager as PaginationHelper, bancoIni, bancoFin, tabelaIni, tabelaFin as character, dtCriacaoIni, dtCriacaoFin as datetime, usuarioIni, usuarioFin as character ): JsonArray` | `thl-audit-registro`, `-detalhe`, `thl-audit-tabela`, `-acesso`, `-campo` |
| CentroCustoService | `get( cod_empresa, cod_plano_ccusto, cod_ccusto as character ): JsonObject` | `ems.ccusto` |
| EmailService | `get( pager, dtEnvioIni, dtEnvioFin as datetime, idIni, idFin, codProgDtsulIni, codProgDtsulFin as character ): JsonArray` | `thl-email` |
| EmitenteService | `get( cod-emitente as integer, nome-abrev as character ): JsonObject` | `emitente` |
| LocalEntregaService | `get( cod-emitente as integer, nome-abrev, cod-entrega as character ): JsonObject` | `emitente`, `loc-entr` |
| ItemService | `get( it-codigo as character ): JsonObject` | `item` |
| SaldoService | `get( cod-estabel, it-codigo as character ): JsonObject` | `item-estab` (+ `saldo-estoq`) |
| TransporteService | `get( cod-transp as integer, nome-abrev as character ): JsonObject` — código (> 0) pelo índice `codigo`, senão `nome-abrev` pelo índice `nome`; ambos vazios → `ThlError` | `transporte` |
| MensageriaService | `get( pager, codigoIni, codigoFin, objetoIni, objetoFin, operacaoIni, operacaoFin, aplicacaoIni, aplicacaoFin as character, dtCriacaoIni, dtCriacaoFin, dtIntegracaoIni, dtIntegracaoFin as datetime ): JsonArray` · `hasDetails(): JsonObject` | `thl-mensagem` |
| MensageriaConteudoService | `get( messageCode as character, messageType as integer ): JsonObject` | `thl-mensagem-conteudo` |

**AuditoriaService:** monta cada registro com snapshots antes/depois (`AuditSnapshotEnum`) filtrados por `thl-audit-tabela-acesso`/`-campo` (campos restritos são omitidos) e rótulo da operação (`AuditOperationEnum`). Obtém o usuário logado via `ContextService:getErpUser()` para filtrar as tabelas liberadas em `thl-audit-tabela-acesso` (índice `idx-usuario`); os eventos são lidos por `idx-tabela-data` (banco + tabela + período). O filtro `usuarioIni/Fin` compara com `thl-audit-registro.usuario` (usuário Datasul desde a correção do `AuditLogService` em 2026-09-24).
**MensageriaService:** usa `ContextService:getErpUser()`; rótulos de status, método, tipo de conector e direção.

---

## Observações

- ⚠️ **Pacote (conferido em disco em 2026-10-02):** `AuditoriaService`, `EmailService` (consulta), `MensageriaService` e `MensageriaConteudoService` estão em `Fontes\thl-extensions\erp\thl\service\` (`thl-extensions.erp.thl.service`), não mais em `thl-lib.erp.service`. Em `thl-lib\erp\service` as consultas com herança direta de `Service` são `CentroCustoService`, `EmitenteService`, `ItemService`, `LocalEntregaService`, `SaldoService` e `TransporteService`. As quatro consultas são extensões do sistema THL e usam a mesma base genérica `Service`.
- `AuditoriaService`: uma leitura de detalhe + parse de CLOB por snapshot e um `can-find` por campo de cada registro (`isFieldRestricted`) — custo da consulta, fora do caminho da trigger. Usa `id` como abreviação de `id-registro`. Visão do módulo em [../logging/auditoria.md](../logging/auditoria.md).
- ⚠️ `AuditoriaService` declara o buffer `b-tabela` (`thl-audit-tabela`) mas não o usa: a API **não aplica** o filtro de sensibilidade por tabela (`thl-audit-tabela.nivel-sensibilidade <= nivel-acesso`) que a tela `thl0150.w` aplica — só oculta campos restritos. NÃO CONFIRMADO se é intencional.
- Cabeçalhos copiados: `CentroCustoService` ("consulta de item"), `LocalEntregaService` (texto de `EmitenteService`), `MensageriaConteudoService` (texto de `MensageriaService`); `ActionEnum` e `Service` ainda citam "IService"/"ThlAppError" nos comentários.
- Os serviços de consulta não usam o dispatcher: `create/update/delete` continuam com o default "Acao nao suportada".

## Consulta pelo `execute` — ação Consultado (2026-10-03, não compilado)

Decisão em [adr/get-no-execute-do-service.md](../adr/get-no-execute-do-service.md).

| Peça | O que é |
|---|---|
| `ActionEnum:Consultado` (4) | Ação do GET |
| `Service:execute` | Com `Consultado`: `context` = parâmetros da query; não chama `initialize()`; devolve `buildQueryResponse( consult() )`; `referenceCode` sai vazio |
| `method protected JsonConstruct consult()` | Gancho da consulta; padrão "Acao nao suportada". O desvio por operação (`this-object:operation`) fica dentro dele |
| `define protected property queryParameters as QueryParameters` | Leitura tipada dos filtros durante o `consult()` |
| `method protected JsonObject buildQueryResponse( result as JsonConstruct )` | `JsonArray` → `{ items, hasNext: false }`; `JsonObject` segue como veio |
| `thl-lib.erp.core.QueryParameters` (novo) | `has`, `getText`, `getInteger`, `getDate`, `getDateTime`, `getPager`; aceita o formato do `resourcen.p` (array de valores) e valor simples |

Os Services de consulta de `thl-lib` listados nesta nota **ainda não** têm `consult()`: seguem atendidos pelo `methodGet` da própria Message.

## Processor e Service sem `execute` (2026-10-04, não compilado)

Novo pacote `thl-lib.integration.messaging.inbound.process` (1 classe). `thl-lib.erp` passa a ter 23 classes.

### Processor (concreta)

**Caminho:** `thl-lib\integration\messaging\inbound\core\Processor.cls` · **Namespace:** `thl-lib.integration.messaging.inbound.core.Processor`

| Assinatura | Descrição |
|---|---|
| `constructor public Processor()` | Sem parâmetros — instanciado por `dynamic-new` a partir de `thl-objeto.classe-processor`. |
| `method public void setServiceClass( input serviceClass as character )` | Nome completo do Service do cadastro (`thl-objeto.classe-service`). |
| `method public void setService( input domainService as Service )` | Instância pronta (Message antiga com `createService()`, `.p`, teste). Tem prioridade sobre o nome. |
| `method public JsonObject execute( input action as ActionEnum, input operation as character, input context as JsonObject, output referenceCode as character )` | `resolveService( operation )`; `Consultado` → `prepareQuery` + `buildQueryResponse( consult() )`; demais → `prepare` → `initialize` → verbo → `loadReferenceCode` → `buildResponse`. Ação desconhecida ou Service não resolvido → `ThlError`. |
| `method protected Service resolveService( input operation as character )` | Padrão: a instância entregue ou o Service do cadastro. **Ponto de extensão** do agregado. |
| `method protected Service createService( input className as character )` | `dynamic-new` + conferência de tipo; nome em branco → `ThlError`. |

Filhas em `thl-extensions.integration.thl.messaging.inbound.process`: `ParametroProcessor`, `ObjetoProcessor`, `ConexaoRestProcessor`, `AuditoriaTabelaProcessor`, `GrupoEmailProcessor`, `MensageriaProcessor` — ver [extensions/thl.md](../extensions/thl.md).

### Service — assinaturas vigentes

`execute` foi removido. Públicos: `prepare( operation, context )`, `prepareQuery( operation, context )`, `initialize()`, `create()`, `update()`, `delete()`, `consult()`, `buildQueryResponse( result )`, `buildResponse( action, referenceCode )`, `loadReferenceCode()` (abstrato), `getEntityName()` (abstrato). Detalhe em [arquitetura/Service.md](../arquitetura/Service.md).

- 211 declarações `method protected override` → `method public override` em 43 Services de `thl-lib.erp` e `thl-extensions.erp` (só a visibilidade).
- `LoogAiDocumentoService`: a sobrescrita de `execute` virou `create()` (`super:create()` + frete real).
- Uso fora da mensageria (`.p`, RPW): `new Processor()` → `setServiceClass( '<classe>' )` ou `setService( new XService() )` → `execute( … )`.

## Segunda rodada do GET (2026-10-04, não compilado)

- `consult()` em `ItemService`, `SaldoService`, `CentroCustoService`, `EmitenteService`, `LocalEntregaService` e `TransporteService`: lê os filtros de `queryParameters` e chama o `get(...)` público, que continua existindo. A frase "não usam `execute()` para leitura: a Message chama o `get(...)`" acima deixou de valer para esses seis.
- Processors novos em `thl-lib.integration.messaging.inbound.process`: `ItemProcessor` (`Saldo`), `EmitenteProcessor` (`localentrega`), `RequisicaoProcessor` (`item`). Em `thl-extensions.integration.dvv.messaging.inbound.process`: `FreteProcessor` (`previsto`/`realizado`).
- `thl-lib.erp` passa a ter 26 classes. Detalhe em [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md) §7.

## `NotaFiscalProcessor` (2026-10-06, não compilado)

`thl-lib.integration.messaging.inbound.process.NotaFiscalProcessor`: um objeto de nota fiscal, vários Services. Recebe a operação (`geracao`, `embarque/geracao`, `ninahub/geracao`…) e repassa só a **última parte** como etapa; o Service vem da **linha da operação no thl0022** (`classe-service`), e não há mais `new NotaFiscalPorEmbarqueService()` no Processor (desde 2026-10-13). É o único Processor que sobrescreve `execute` (os demais só `resolveService`). `processamento` é recusado quando o Service da linha é o `NotaFiscalPorEmbarqueService`. `thl-lib.erp` tem 27 classes.

## Pacote dos Processors (2026-10-06)

Os Processors são orquestração da **entrada** e ficam junto dela: `thl-lib.integration.messaging.inbound.process` (`Fontes	hl-lib\integration\messaging\inbound\process\`) e, nas extensões, `thl-extensions.integration.<sistema>.messaging.inbound.process`. Os Services continuam em `erp.service`. As contagens de `thl-lib.erp` citadas acima (26, 27) passam a ser 22: os cinco Processors de `thl-lib` contam agora em `thl-lib.integration` (45).

## Nota fiscal: etapas públicas, sem despacho no `create()` (2026-10-08, não compilado)

`NotaFiscalBaseService` declara `generateInvoice`, `generateNfeXml`, `authorizeSefaz`, `printInvoice`, `notifyInvoice` (abstratos) e `waitSefazProcessing`. `NotaFiscalService` e `NotaFiscalPorEmbarqueService` não escolhem mais a etapa pela operação: `create()` é a geração e quem chama cada etapa é o `NotaFiscalProcessor`. `processSteps` saiu do `NotaFiscalService`. Ver [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

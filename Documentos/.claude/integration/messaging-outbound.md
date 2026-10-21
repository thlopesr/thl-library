---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, mensageria, outbound]
updated: 2026-10-13
---

# Pacote: integration/messaging — Outbound

> ⚠️ **2026-10-04 — Message → Processor → Service.** `OutboundMessageService` usa `OutboundConfigLoader` (mesma busca e mesmas mensagens de erro do `MessageConfigLoader:load` por estabelecimento). Nenhuma outra mudança na saída.

> **Sincronizado em 2026-09-24:** removidos `OutboundObjectContext:hasRecordId()/hasReferenceCode()` (não existem mais — removidos pelo prompt de correção de 2026-08-13); documentados os métodos protected de `OutboundMessageService`.

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| OutboundMessage | Classe abstrata base para mensagens de saída; gerencia path parameters e `applyBusinessProcess` | Template Method | Message, OutboundObjectContext, ConnectorResponse, JsonArray, ThlError | MessageFactory, OutboundMessageService, MessageExecutionService |
| OutboundObjectContext | DTO de contexto de um objeto outbound: recid, referenceCode, additionalData | — | StringUtil, ThlError | OutboundMessage, OutboundMessageService |
| MessageStructureStrategy | Classe abstrata que define o contrato de construção da estrutura de mensagem | Strategy | OutboundMessage, OutboundObjectContext | MessageFactory |
| SingleMessageStructure | Estratégia para mensagens com um registro por envio | Strategy | MessageStructureStrategy, OutboundMessage, OutboundObjectContext | MessageFactory |
| MultipleMessageStructure | Estratégia para mensagens com múltiplos registros no mesmo envio | Strategy | MessageStructureStrategy, OutboundMessage, OutboundObjectContext | MessageFactory |
| MessageExecutionService | Executa a mensagem outbound online (monta request, chama ConnectorService, persiste resultado) | Service | Message, MessageConfig, ConnectorRequest, ConnectorConfig, ConnectorService, ConnectorResponse, EnvironmentResource, LogUtil, ThlError | OutboundMessageService |
| OutboundMessageService | Orquestra o ciclo completo outbound: carrega config, builda payload, processa (ONLINE/SCHEDULE/BATCH) | Service | MessageFactory, MessageConfigLoader, MessageStructureStrategy, MessageExecutionService, SchedulingService, ExecutionMode, ConnectorResponse, LogUtil, ThlError | Chamado pelos programas de integração |
| SchedulingService | Agenda mensagem via RPW (`thl0220z.p`) e retorna ConnectorResponse com número do pedido | Service | Message, MessageConfig, ConnectorResponse, StringUtil, ThlError, LogUtil | OutboundMessageService |

---

## OutboundMessage

**Caminho:** `thl-lib\integration\messaging\outbound\core\OutboundMessage.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.core.OutboundMessage`

**Responsabilidade:** Classe abstrata que estende `Message` para o fluxo de saída. Adiciona gerenciamento de path parameters (`setPathParameter`, `getPathParameters`) e o hook `parseBusinessProcess` para que subclasses possam validar a resposta recebida da API e determinar `successProcess`.

**Padrão de projeto:** Template Method — `applyBusinessProcess` chama `parseBusinessProcess` (hook para subclasses).

**INHERITS / IMPLEMENTS:** `inherits Message` — declarado `abstract`.

**Dependências diretas THL:** `Message`, `OutboundObjectContext`, `ConnectorResponse`, `StringUtil`, `ThlError`.

**Propriedades protected:**

| Nome | Tipo |
|---|---|
| `pathParameters` | `JsonArray` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void loadData( objectContext as OutboundObjectContext )` | Chama `onLoadData(objectContext:recordId)` e armazena `referenceCode` no repository. Lança `ThlError` se context inválido. |
| `method public void appendPayloadObject()` | Default lança `ThlError` — subclasses devem sobrescrever. |
| `method public void appendPayloadObject( objectContext as OutboundObjectContext )` | Default lança `ThlError` — subclasses devem sobrescrever. |
| `method public JsonArray getPathParameters()` | Retorna `pathParameters` (inicializa como `JsonArray` vazio se necessário). |
| `method public override void saveResponse( connectorResponse as ConnectorResponse, isIncremental as logical )` | Antes de salvar, chama `applyBusinessProcess` quando `successResponse = true`. |
| `method public logical applyBusinessProcess( input response as longchar )` | Delega para `parseBusinessProcess`. |

**Métodos protected:**

| Assinatura | Descrição |
|---|---|
| `method protected void setPathParameter( input parameterName as character, input parameterValue as character )` | Adiciona `{ name, value }` ao `JsonArray` de path parameters. |
| `method protected logical parseBusinessProcess( input response as longchar )` | Hook: retorna `?` por padrão. Subclasses sobrescrevem para validar a resposta da API. |

**Pontos de extensão:**
- `appendPayloadObject()` / `appendPayloadObject(objectContext)` — obrigatório sobrescrever
- `onLoadData(recid)` — herdado de `Message`, obrigatório
- `parseBusinessProcess(longchar)` — opcional, para validação de resposta de negócio

---

## OutboundObjectContext

**Caminho:** `thl-lib\integration\messaging\outbound\core\OutboundObjectContext.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.core.OutboundObjectContext`

**Responsabilidade:** DTO que transporta o contexto de um objeto a ser serializado: `recid` do registro, código de referência textual e dados adicionais (`JsonObject`). Quatro construtores cobrem diferentes combinações.

**Dependências diretas THL:** `StringUtil`, `ThlError`.

**Propriedades públicas:**

| Nome | Tipo | Acesso set |
|---|---|---|
| `recordId` | `recid` | `private set` |
| `referenceCode` | `character` | `set` |
| `additionalData` | `JsonObject` | `set` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public OutboundObjectContext( input recordId as recid )` | Inicializa com recid. |
| `constructor public OutboundObjectContext( input referenceCode as character )` | Inicializa com referência textual. |
| `constructor public OutboundObjectContext( input additionalData as JsonObject )` | Inicializa com dados adicionais. |
| `constructor public OutboundObjectContext( input recordId as recid, input referenceCode as character, input additionalData as JsonObject )` | Inicializa com todos os campos. |
| `constructor public OutboundObjectContext( input recordId as recid, input referenceCode as character, input additionalDataContent as character )` | Inicializa com content como string (armazenada em `additionalData['content']`). |
| `method public logical hasAdditionalData()` | `true` se `additionalData` é objeto válido. |
| `method public character getAdditionalDataContent()` | Retorna `additionalData['content']`; lança `ThlError` se chave ausente. |
| `method public void addAdditionalData( input fieldName as character, input fieldValue as character )` | Adiciona campo ao `JsonObject` de dados adicionais. |

---

## MessageStructureStrategy

**Caminho:** `thl-lib\integration\messaging\outbound\strategy\MessageStructureStrategy.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.strategy.MessageStructureStrategy`

**Responsabilidade:** Classe abstrata que define o contrato de construção de payload outbound: iniciar, adicionar objetos e finalizar. Recebe `OutboundMessage` no construtor.

**Padrão de projeto:** Strategy (abstrata).

**INHERITS / IMPLEMENTS:** Declarado `abstract`.

**Métodos abstratos:**

| Assinatura |
|---|
| `method public abstract void buildMessage()` |
| `method public abstract void addObject( objectContext as OutboundObjectContext )` |
| `method public abstract void finishMessage()` |

---

## SingleMessageStructure

**Caminho:** `thl-lib\integration\messaging\outbound\strategy\SingleMessageStructure.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.strategy.SingleMessageStructure`

**Responsabilidade:** Estratégia para envio de um registro por mensagem. `buildMessage` é no-op (estrutura criada em `addObject`). `finishMessage` persiste o conteúdo se não houver conteúdo OUTBOUND reutilizável.

**Padrão de projeto:** Strategy (concreto).

**INHERITS / IMPLEMENTS:** `inherits MessageStructureStrategy`

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void buildMessage()` | No-op — a mensagem é criada em `addObject`. |
| `method public override void addObject( objectContext as OutboundObjectContext )` | Carrega dados, cria mensagem, constrói payload (`appendPayloadObject`), registra item. |
| `method public override void finishMessage()` | Persiste conteúdo se não reutilizável. |

---

## MultipleMessageStructure

**Caminho:** `thl-lib\integration\messaging\outbound\strategy\MultipleMessageStructure.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.strategy.MultipleMessageStructure`

**Responsabilidade:** Estratégia para envio de múltiplos registros em uma única mensagem. `buildMessage` cria a mensagem uma vez; cada `addObject` carrega dados e adiciona ao payload; `finishMessage` persiste o conteúdo consolidado.

**Padrão de projeto:** Strategy (concreto).

**INHERITS / IMPLEMENTS:** `inherits MessageStructureStrategy`

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void buildMessage()` | Cria a mensagem (`outboundMessage:createMessage()`). |
| `method public override void addObject( objectContext as OutboundObjectContext )` | Carrega dados, constrói payload para o objeto, registra item. |
| `method public override void finishMessage()` | Persiste o conteúdo consolidado. |

---

## MessageExecutionService

**Caminho:** `thl-lib\integration\messaging\outbound\service\MessageExecutionService.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.service.MessageExecutionService`

**Responsabilidade:** Executa uma mensagem outbound no modo ONLINE: monta `ConnectorRequest` com `ConnectorConfig` resolvido por `EnvironmentResource`, chama `ConnectorService`, persiste o resultado em `thl-mensagem`. Em caso de exceção loga via `LogUtil`, persiste um `ConnectorResponse` de erro e relança.

**Padrão de projeto:** Service.

**Dependências diretas THL:** `Message`, `MessageConfig`, `OutboundMessage`, `ConnectorRequest`, `ConnectorConfig`, `ConnectorService`, `ConnectorResponse`, `EnvironmentResource`, `LogUtil`, `ThlError`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public ConnectorResponse executeOnline( message_ as Message, configuration as MessageConfig )` | Monta request, executa via `ConnectorService`, salva resposta. Lança `ThlError` se `message_` não for `OutboundMessage`. CATCH persiste erro e relança. |

**Observações:** `ConnectorConfig` é instanciado com `applicationName + '.' + objectName` como `programName` para resolução de variáveis de ambiente. CATCH usa `throw error` (sem `undo`) para evitar ROLLBACK TO SAVEPOINT do Oracle em transações que contenham LOB (`thl-mensagem-conteudo.conteudo`), que causaria erro 11599.

---

## OutboundMessageService

**Caminho:** `thl-lib\integration\messaging\outbound\service\OutboundMessageService.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.service.OutboundMessageService`

**Responsabilidade:** Orquestra o ciclo completo de uma mensagem outbound: carrega configuração, instancia factory e estratégia, aceita objetos (`addObject`), finaliza o build (`finishBuild`) e processa (ONLINE, SCHEDULE ou BATCH). Suporta reprocessamento de mensagens existentes via `loadForReprocess` / `reprocess`.

**Padrão de projeto:** Service.

**Dependências diretas THL:** `MessageFactory`, `MessageConfigLoader`, `MessageStructureStrategy`, `OutboundMessage`, `OutboundObjectContext`, `MessageExecutionService`, `SchedulingService`, `ExecutionMode`, `ConnectorResponse`, `LogUtil`, `ThlError`.

**Propriedades públicas/protected:**

| Nome | Tipo | Acesso |
|---|---|---|
| `configuration` | `MessageConfig` | `public get. set.` |
| `messageFactory` | `MessageFactory` | `protected get. protected set.` |
| `structureStrategy` | `MessageStructureStrategy` | `protected get. protected set.` |
| `connectorResponse` | `ConnectorResponse` | `protected get. protected set.` |
| `buildStarted` | `logical` | `protected get. protected set.` |
| `messageFinalized` | `logical` | `protected get. protected set.` |
| `restoredForRetry` | `logical` | `protected get. protected set.` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public OutboundMessageService( applicationName as character, objectName as character, integrationOperation as character )` | Carrega config (`'*'` como establishmentCode), inicializa factory. |
| `method public void beginBuild()` | Cria a estratégia e inicia o build. |
| `method public void addObject( register as recid )` | Adiciona objeto por recid. |
| `method public void addObject( objectContext as OutboundObjectContext )` | Adiciona objeto por contexto. Exige `beginBuild` anterior. |
| `method public void finishBuild()` | Finaliza o build (chama `finishMessage` na estratégia). |
| `method public void loadForReprocess( messageCode as character )` | Restaura mensagem existente para reprocessamento. |
| `method public logical reprocess( messageCode as character )` | Carrega e processa no modo ONLINE. Lança `ThlError` se mensagem estiver em modo SCHEDULE. |
| `method public logical process()` | Processa no modo configurado. |
| `method public logical process( executionModeValue as ExecutionMode )` | Processa no modo explícito (ONLINE chama `MessageExecutionService`, SCHEDULE chama `SchedulingService`, BATCH retorna `true` sem ação). |
| `method public ConnectorResponse getLastConnectorResponse()` | Retorna o último `ConnectorResponse`. Lança se inválido. |

**Métodos protected:** `processOnline()` e `scheduleProcessing()` (devolvem `ConnectorResponse`; delegam a `MessageExecutionService` e `SchedulingService`), `ensureBuildStarted()` (erro "Build da mensagem nao foi iniciado." se `beginBuild` não foi chamado) e `ensureReadyForProcessing()` (exige `finishBuild` ou mensagem restaurada para retry, e `MessageFactory` válida).

**Tratamento de erro:** CATCH em `process` persiste `ConnectorResponse` de erro se `connectorResponse` ainda for nulo, loga e relança com `throw e` (sem `undo`) para evitar rollback de sub-transação que causaria erro 11599 do Oracle ao desfazer LOBs.

---

## SchedulingService

**Caminho:** `thl-lib\integration\messaging\outbound\service\SchedulingService.cls`

**Namespace ABL:** `thl-lib.integration.messaging.outbound.service.SchedulingService`

**Responsabilidade:** Agenda a execução da mensagem via RPW chamando `thl/thl0220z.p`, que agenda o runner de reprocessamento `thl0220rp.p` (até 2026-09-25 o agendador apontava por engano para o runner de expurgo). Retorna `ConnectorResponse` com `successProcess = ?` (RPW ainda não executou) e `statusCode = numPedidoExecucao` para rastreabilidade. Persiste resultado na mensagem independentemente de sucesso/falha.

**Padrão de projeto:** Service.

**Dependências diretas THL:** `Message`, `MessageConfig`, `ConnectorResponse`, `StringUtil`, `ThlError`, `LogUtil`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public ConnectorResponse schedule( message_ as Message, configuration as MessageConfig )` | Chama `thl0220z.p`. Trata `return-value = 'NOK'` e `numPedidoExecucao = 0/?` como falha. Sucesso: `successRequest = true, successResponse = true, successProcess = ?`. |

**Observações:**
- `destination = 'RPW'` no `ConnectorResponse` para identificar que é agendamento.
- CATCH loga e persiste erro; o throw acontece com `undo, throw` apenas nos branches de falha, mas o CATCH pode não relançar em todos os cenários — verificar se exceções do `run thl0220z.p` são corretamente propagadas (ausência de `undo, throw e` no CATCH é um ponto de atenção).

## Situação das fases no outbound — ajustes de 2026-10-03 (não compilado)

Decisão em [adr/metricas-conteudo-expurgo-mensagens.md](../adr/metricas-conteudo-expurgo-mensagens.md) §2.3.

- `OutboundMessage.saveResponse`: quando o envio falha (`successResponse` falso), `successProcess` passa a `?` e o processamento é gravado como **Não aplicável** (antes ficava Erro, mesmo em objeto sem regra de processamento). Vale para qualquer objeto, inclusive os que sobrescrevem `parseBusinessProcess`: com o envio em falha, o processamento de negócio não chega a ocorrer. A situação geral continua Erro, pelo retorno.
- `SchedulingService.schedule`: no agendamento aceito, depois do `saveResponse`, chama `message_:markPending()`. As fases ficam 3, 3, 4 como antes, mas `sit-mensagem` fica 1 (Pendente) até o RPW executar e gravar o resultado.
- Inbound agendado não muda: o `InboundSchedulingService` não grava resultado na aceitação, então a mensagem segue com as três fases e a situação geral em pendente.

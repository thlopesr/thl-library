# Pacote: integration/messaging — Core

> **Sincronizado em 2026-09-24:** incluídos 3 métodos protected de `Message` e 6 de `MessageRepository` que não estavam documentados. As descrições de `prepareResponseHistory` e `ensureMessageCode` foram conferidas no corpo; as demais foram inferidas da assinatura.

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| Message | Classe abstrata base de toda mensagem de integração (inbound e outbound) | Template Method | MessageRepository, ConnectorResponse, DirectionEnum, ErrorHandler | InboundMessage, OutboundMessage |
| MessageConfig | DTO imutável com a configuração de um objeto de integração (lida do banco via `MessageConfigLoader`) | — | ExecutionMode | MessageFactory, OutboundMessageService, InboundMessageService |
| DirectionEnum | Enum de direção do fluxo: INBOUND=2, OUTBOUND=1 | — | — | Message, InboundMessage |
| ExecutionMode | Enum de modo de execução: ONLINE=1, SCHEDULE=2, BATCH=3 | — | — | MessageConfig, OutboundMessageService |
| MessageStatusEnum | Enum de status de mensagem: PENDING, ERROR, SUCCESS, NOT_APPLICABLE | — | — | MessageRepository |
| MessageFactory | Instancia dinamicamente a classe de mensagem configurada; cria a estratégia de estrutura outbound | Factory | MessageConfig, MessageStructureStrategy, SingleMessageStructure, MultipleMessageStructure, OutboundMessage, ThlError | OutboundMessageService, InboundMessageService |
| MessageConfigLoader | Carrega configuração de mensagem das tabelas `thl-objeto` e `thl-objeto-parametro` | Repository | MessageConfig, StringUtil, ThlError | OutboundMessageService, InboundMessageService |
| MessageRepository | Acesso às tabelas `thl-mensagem*` (CRUD de mensagens, itens, conteúdo, histórico) | Repository | StringUtil, ThlError, LogUtil, MessageStatusEnum | Message |

---

## Message

**Caminho:** `thl-lib\integration\messaging\core\Message.cls`

**Namespace ABL:** `thl-lib.integration.messaging.core.Message`

**Responsabilidade:** Classe abstrata que define o ciclo de vida de uma mensagem de integração: criação no banco (`createMessage`), carregamento de payload persistido (`reuseMessage`), salvamento de conteúdo e resultado de execução (`saveContent`, `saveResponse`). Toda lógica de banco é delegada ao `MessageRepository`.

**Padrão de projeto:** Template Method — define os passos do ciclo de vida; subclasses implementam `onLoadData` e constroem o payload.

**INHERITS / IMPLEMENTS:** Declarado `abstract`.

**Dependências diretas THL:** `MessageRepository`, `ConnectorResponse`, `DirectionEnum`, `ErrorHandler`.

**Propriedades protected/public:**

| Nome | Tipo | Acesso |
|---|---|---|
| `payload` | `JsonConstruct` | `protected get. set.` |
| `repository` | `MessageRepository` | `protected get. private set.` |
| `objectName` | `character` | `public get. private set.` |
| `applicationName` | `character` | `public get. private set.` |
| `integrationOperation` | `character` | `protected get. private set.` |
| `methodType` | `integer` | `protected get. private set.` |
| `connectorType` | `integer` | `protected get. private set.` |
| `integrationDirection` | `logical` | `protected get. private set.` |
| `executionMode` | `integer` | `public get. private set.` |
| `referenceCode` | `character` | `protected get. protected set.` |
| `ExternalReferenceCode` | `character` | `protected get. protected set.` |
| `errorHandler` | `ErrorHandler` | `protected get. private set.` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void appendItem()` | Adiciona um item à mensagem no banco (`thl-mensagem-item`). |
| `method public void createMessage()` | Gera UUID de mensagem e cria registro em `thl-mensagem`. |
| `method public logical hasReusableContentRequestMessage()` | Verifica se existe conteúdo OUTBOUND persistido para este objeto. |
| `method public logical hasReusableMessage()` | Verifica se existe item de mensagem para a referência atual. |
| `method public void loadByMessageCode( messageCode as character )` | Carrega mensagem existente pelo código. |
| `method public void loadByMessageItem()` | Carrega código de mensagem a partir do item e restaura estado. |
| `method public longchar loadContent()` | Retorna o conteúdo persistido da mensagem. |
| `method public void reuseMessage()` | Carrega estado e payload persistidos (combina `loadPersistedState` + `loadPersistedPayload`). |
| `method public void saveContent()` | Persiste o payload atual como conteúdo OUTBOUND. |
| `method public void saveContentByType( input typeContent as int64, input content as longchar )` | Cria e salva conteúdo de tipo explícito (INBOUND=2, OUTBOUND=1). |
| `method public void saveResponse( connectorResponse as ConnectorResponse, isIncremental as logical )` | Persiste resultado de execução + cria histórico se `isIncremental`. |
| `method public JsonConstruct getPayloadContent()` | Retorna o payload atual (ou `?` se não inicializado). |
| `method public longchar getPayloadContentText()` | Serializa payload para longchar UTF-8. |
| `method public void setSuccessPayload( statusCode as integer, statusMessage as character )` | Monta payload de sucesso `{ success: true, code: N, message: '...' }`. |
| `method public character getMessageCode()` | Retorna o código UUID da mensagem. |

**Métodos protected relevantes:**

| Assinatura | Descrição |
|---|---|
| `method protected void initializeArrayPayload()` | Cria `JsonArray` no `payload`. |
| `method protected void initializeObjectPayload()` | Cria `JsonObject` no `payload`. |
| `method protected void prepareResponseHistory( isIncremental as logical )` | Se `isIncremental`, grava um histórico (`repository:createHistoryMessage()`) antes de salvar o novo retorno. |
| `method protected void saveResponseContent( responseContent as longchar )` | Persiste o conteúdo da resposta do conector. |
| `method protected void saveResponseExecutionResult( connectorResponse as ConnectorResponse )` | Grava o resultado da execução (status/situações) a partir do `ConnectorResponse`. |

**Observações:**
- `repository` e `errorHandler` são criados no construtor e permanecem válidos durante todo o ciclo de vida da mensagem (invariante documentada em comentário no código).
- `appendItem()` lê `this-object:referenceCode` e `this-object:ExternalReferenceCode` diretamente e persiste via `repository:createItemMessage()` — a subclasse é responsável por setar essas propriedades antes de chamar `appendItem()`.
- ⚠️ **Refatoração 2026-07-25:** `onLoadData(recid)` abstract, `appendMessageItemByReference(recid)` e `appendMessageItemByExternalReference(character)` foram **removidos** de `Message.cls`. Esses métodos permanecem em `OutboundMessage.cls` para o lado outbound. O novo padrão inbound é: subclasse seta `referenceCode` (retorno do Service) + `ExternalReferenceCode` (via `loadExternalReference`), depois chama `appendItem()`.

---

## MessageConfig

**Caminho:** `thl-lib\integration\messaging\core\MessageConfig.cls`

**Namespace ABL:** `thl-lib.integration.messaging.core.MessageConfig`

**Responsabilidade:** DTO imutável (setters `protected`) que armazena a configuração de um objeto de integração carregada do banco. Passado para `MessageFactory`, `OutboundMessageService`, `InboundMessageService` e `MessageExecutionService`.

**Propriedades públicas (get público, set protected):**

| Nome | Tipo |
|---|---|
| `objectName` | `character` |
| `applicationName` | `character` |
| `methodType` | `integer` |
| `messageClass` | `character` (nome qualificado da classe de mensagem) |
| `queryProgram` | `character` |
| `connectorType` | `integer` |
| `historyEnabled` | `logical` |
| `integrationDirection` | `logical` |
| `executionModeValue` | `ExecutionMode` |
| `isSingle` | `logical` (true = SingleMessageStructure, false = MultipleMessageStructure) |
| `parameterCode` | `character` (parâmetro de ambiente para conexão) |
| `routeParameterCode` | `character` (parâmetro de ambiente para o path) |
| `integrationOperation` | `character` |

---

## DirectionEnum

**Caminho:** `thl-lib\integration\messaging\enum\DirectionEnum.cls`

**Namespace ABL:** `thl-lib.integration.messaging.enum.DirectionEnum`

**Valores:** `OUTBOUND = 1`, `INBOUND = 2`

---

## ExecutionMode

**Caminho:** `thl-lib\integration\messaging\enum\ExecutionMode.cls`

**Namespace ABL:** `thl-lib.integration.messaging.enum.ExecutionMode`

**Valores:** `ONLINE = 1`, `SCHEDULE = 2`, `BATCH = 3`

---

## MessageStatusEnum

**Caminho:** `thl-lib\integration\messaging\enum\MessageStatusEnum.cls`

**Namespace ABL:** `thl-lib.integration.messaging.enum.MessageStatusEnum`

**Responsabilidade:** Espelha os valores dos campos `sit-requisicao`, `sit-processamento` e `sit-retorno` da tabela `thl-mensagem`.

**Valores:** `PENDING = 1`, `ERROR = 2`, `SUCCESS = 3`, `NOT_APPLICABLE = 4`

---

## MessageFactory

**Caminho:** `thl-lib\integration\messaging\factory\MessageFactory.cls`

**Namespace ABL:** `thl-lib.integration.messaging.factory.MessageFactory`

**Responsabilidade:** Instancia dinamicamente a classe de mensagem configurada em `MessageConfig:messageClass` via `dynamic-new`. Para mensagens outbound, cria a estratégia de estrutura adequada (`SingleMessageStructure` ou `MultipleMessageStructure`).

**Padrão de projeto:** Factory.

**Dependências diretas THL:** `MessageConfig`, `Message`, `OutboundMessage`, `MessageStructureStrategy`, `SingleMessageStructure`, `MultipleMessageStructure`, `ThlError`.

**Propriedades protected:**

| Nome | Tipo |
|---|---|
| `message_` | `Message` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public MessageFactory( configuration as MessageConfig )` | Instancia `dynamic-new messageClass(...)` com os 7 parâmetros do construtor padrão. Lança `ThlError` se falhar. |
| `method public MessageStructureStrategy createStructureStrategy()` | Retorna `SingleMessageStructure` ou `MultipleMessageStructure` conforme `isSingle`. Exige que a mensagem seja `OutboundMessage`. |
| `method public Message getMessage()` | Retorna a instância da mensagem criada. |
| `method public void restoreMessage( messageCode as character )` | Carrega mensagem existente pelo código UUID. |

---

## MessageConfigLoader

**Caminho:** `thl-lib\integration\messaging\repository\MessageConfigLoader.cls`

**Namespace ABL:** `thl-lib.integration.messaging.repository.MessageConfigLoader`

**Responsabilidade:** Carrega configuração de objetos de integração das tabelas `thl-objeto` e `thl-objeto-parametro`. Possui dois overloads: um para fluxo outbound (por estabelecimento + operação) e outro para fluxo inbound (por methodType). Retorna erro se objeto/parâmetro não encontrado ou se `ind-inativo = true`.

**Padrão de projeto:** Repository.

**Dependências diretas THL:** `MessageConfig`, `StringUtil`, `ThlError`.

**Tabelas acessadas:** `thl-objeto`, `thl-objeto-parametro`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public MessageConfig load( establishmentCode as character, applicationName as character, objectName as character, integrationOperation as character )` | Carrega config por estabelecimento (tenta o código específico antes de `'*'`). |
| `method public MessageConfig load( applicationName as character, objectName as character, methodType as integer, operation as character )` | Carrega config por methodType e operação (para fluxo inbound). |
| `method public MessageConfig setMessageConfig()` | Monta e retorna o `MessageConfig` a partir dos buffers carregados. |

**Observações:** A coluna `thl-objeto-parametro.cod-param-ambiente` mapeia para `parameterCode` e `cod-param-ambiente-destino` para `routeParameterCode`.

---

## MessageRepository

**Caminho:** `thl-lib\integration\messaging\repository\MessageRepository.cls`

**Namespace ABL:** `thl-lib.integration.messaging.repository.MessageRepository`

**Responsabilidade:** Todas as operações de banco sobre as tabelas de mensagem (`thl-mensagem`, `thl-mensagem-historico`, `thl-mensagem-item`, `thl-mensagem-conteudo`). Expõe propriedades públicas `messageCode`, `referenceCode`, `objectName`, `applicationName` e `externalReferenceCode` para coordenação com `Message`.

**Padrão de projeto:** Repository.

**Dependências diretas THL:** `StringUtil`, `ThlError`, `LogUtil`, `MessageStatusEnum`.

**Tabelas acessadas (exclusive-lock onde relevante):** `thl-mensagem`, `thl-mensagem-historico`, `thl-mensagem-item`, `thl-mensagem-conteudo`.

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `messageCode` | `character` |
| `referenceCode` | `character` |
| `objectName` | `character` |
| `applicationName` | `character` |
| `externalReferenceCode` | `character` |

**Métodos públicos (seleção):**

| Assinatura | Descrição |
|---|---|
| `method public void generateMessageCode()` | Gera UUID via `guid(generate-uuid)`. |
| `method public void createMessage(...)` | Cria registro em `thl-mensagem` com status PENDING para os 3 campos de situação. |
| `method public void loadMessage()` | Carrega `thl-mensagem` com exclusive-lock por `messageCode`. Lança `ThlError` se não encontrado ou bloqueado. |
| `method public void saveResultMessage(...)` | Atualiza `thl-mensagem` com destino, contadores, situações e status HTTP. |
| `method public void createHistoryMessage()` | `buffer-copy` de `thl-mensagem` para `thl-mensagem-historico`. |
| `method public void createItemMessage()` | Cria registro em `thl-mensagem-item`. |
| `method public void loadMessageItemByReference(...)` | Busca item por `referenceCode` filtrando mensagem por objeto/aplicação (exclusive-lock). |
| `method public void createMessageContent( typeContent as int64 )` | Cria registro em `thl-mensagem-conteudo`. |
| `method public void loadMessageContent( typeContent as int64 )` | Carrega conteúdo (exclusive-lock) por `messageCode` e tipo. |
| `method public longchar loadContentMessage()` | Lê o `conteudo` do registro de conteúdo carregado. |
| `method public void loadMessageCodeFromItem()` | Resolve `messageCode` a partir do item (`thl-mensagem-item`) posicionado. |
| `method public logical hasExistingMessageItemForReference()` | Indica se já existe item de mensagem para a referência atual. |
| `method public logical hasExistingMessageContentForObject()` | Indica se já existe conteúdo persistido para o objeto atual. |
| `method protected void ensureMessageCode()` / `ensureReferenceCode()` | Guardas: lançam erro se `messageCode`/`referenceCode` não estiverem definidos. |
| `method public void saveContentMessage( content as longchar )` | Salva `conteudo` no registro carregado. |

**Observações:** Erros de criação de registros são logados via `LogUtil` antes de relançar — necessita que `log-manager:logfile-name` esteja configurado para produzir output.

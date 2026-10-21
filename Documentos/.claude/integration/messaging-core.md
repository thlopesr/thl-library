---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, mensageria, core]
updated: 2026-10-13
---

# Pacote: integration/messaging — Core

> ⚠️ **2026-10-04 — Message → Processor → Service.** `MessageConfigLoader` virou classe-pai abstrata; a carga é feita por `InboundConfigLoader` e `OutboundConfigLoader`. Ver a seção final desta nota.

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

## Situação geral da mensagem — `sit-mensagem` (2026-10-03, não compilado)

Decisão em [adr/metricas-conteudo-expurgo-mensagens.md](../adr/metricas-conteudo-expurgo-mensagens.md) §2.3. O campo vem do delta `Database\delta-thl-2026-10-03.df`; **estas classes só compilam com o delta carregado**.

- `MessageRepository.createMessage` grava `sit-mensagem` = 1 (Pendente).
- `MessageRepository.saveResultMessage` grava as três fases e, em seguida, a situação geral pelo método privado `resolveOverallStatus()`: alguma fase em erro → 2; senão, alguma pendente → 1; todas em sucesso ou não aplicável → 3. A assinatura não mudou.
- Corrigido no mesmo método: a situação da requisição testava `successResponse = ?` para decidir "não aplicável"; agora testa `successRequest = ?`. Nenhum chamador passa esses valores como indefinidos, então o comportamento atual não muda.
- `MessageRepository.markMessagePending()` e `Message.markPending()` (novos, públicos): voltam a situação geral para pendente. Usados pelo agendamento outbound aceito.
- Códigos: os de `MessageStatusEnum` (1 Pendente, 2 Erro, 3 Sucesso); o 4 (Não aplicável) só existe nas fases.
- Mensagens anteriores ao campo: `Utils\scripts\acerto-thl-sit-mensagem.p` (simulação por padrão; uma transação por mensagem; pula mensagem bloqueada).

## Gravação de conteúdo por operação (2026-10-03, não compilado)

Decisão em [adr/metricas-conteudo-expurgo-mensagens.md](../adr/metricas-conteudo-expurgo-mensagens.md) §2.4. Campo `thl-objeto-parametro.tipo-grava-conteudo` (delta `Database\delta-thl-2026-10-03.df`); **estas classes só compilam com o delta carregado**.

| Classe | Mudança |
|---|---|
| `ContentStorageEnum` (novo, `thl-lib.integration.messaging.enum`) | `ALWAYS` = 1, `ERROR_ONLY` = 2, `NEVER` = 3; alinhado com `thl\include\i05thl011.i` |
| `MessageConfig` | propriedade `contentStorage` e 13º parâmetro no construtor (único chamador: `MessageConfigLoader`) |
| `MessageConfigLoader` | passa `tipo-grava-conteudo`; sem operação na URL, a escolha da linha ficou determinística (abaixo) |
| `MessageFactory` | depois do `dynamic-new`, chama `message_:setContentStorage( configuration:contentStorage )` — o construtor de 7 parâmetros das Messages não muda |
| `Message` | `setContentStorage`, `markFailed` (públicos), `shouldStoreContent` (protegido); `saveContentByType`, `saveResponse` e `saveResponseContent` passam a respeitar a opção |
| `InboundMessage` | `saveInboundError` chama `markFailed()` antes de gravar |

**Regra em `Message.shouldStoreContent`:**

- Requisição do **outbound** e do **inbound fora do online** (agendado): gravada sempre — o reenvio e o RPW leem esse conteúdo.
- `NEVER`: nada mais é gravado; fica só a `thl-mensagem` (o texto do erro continua em `descr-retorno`).
- `ERROR_ONLY`: grava quando a mensagem falha. A requisição do inbound online fica **em memória** no objeto da mensagem (`saveContentByType` não grava na entrada) e só vai para o banco em `markFailed()`.
- `ALWAYS` (padrão, e qualquer valor fora do domínio): comportamento anterior.

**Quem marca a falha:** `InboundMessage.saveInboundError` (inbound) e `Message.saveResponse` quando `successRequest`, `successResponse` ou `successProcess` é falso (outbound).

**Retorno do outbound sem gravar:** `saveResponseContent` limpa o conteúdo de retorno de uma tentativa anterior, para não ficar o erro antigo junto de um resultado novo.

**Máscara de segredo:** as Messages que sobrescrevem `saveContentByType` chamam o `super` com o conteúdo já mascarado; o que fica em memória também é o mascarado.

**Escolha da linha de `thl-objeto-parametro` sem operação na URL** (`MessageConfigLoader.load( aplicacao, objeto, metodo, operacao )`): antes era o primeiro registro do método; agora, nesta ordem: operação em branco → operação com o nome do método (`GET`, `POST`…, padrão das cargas) → primeiro registro do método (como antes). Evita que uma consulta sem operação pegue a configuração da linha `metricas` ou `conteudo`. Com operação na URL nada mudou.

## Carregadores de configuração (2026-10-04, não compilado)

| Classe | Pacote | Papel |
|---|---|---|
| `MessageConfigLoader` (abstrata) | `…messaging.repository` | Buffers protegidos `b-thl-objeto` e `b-thl-objeto-parametro`; `findObject( applicationName, objectName )`; `buildConfig()` |
| `OutboundConfigLoader` | `…messaging.outbound.repository` | `load( establishmentCode, applicationName, objectName, integrationOperation )` → `MessageConfig`. Mesma busca e mesmas mensagens do carregador antigo |
| `InboundConfigLoader` | `…messaging.inbound.repository` | `load( applicationName, objectName, methodType, operation )` → `InboundMessageConfig`. Valida as três classes do objeto |
| `InboundMessageConfig` | `…messaging.inbound.core` | `MessageConfig` + `processorClass` e `serviceClass` |

**Linha de `thl-objeto-parametro` na entrada** (`InboundConfigLoader:findParameter`), nesta ordem: (1) operação da URL + método; (2) método com operação em branco; (3) método com operação = nome do método (`GET`/`POST`/`PATCH`/`DELETE`); (4) primeira linha do método. A operação da URL, quando informada, é a que vai para a configuração e para a mensagem. Substitui a regra descrita em "Escolha da linha … sem operação na URL" acima.

`thl-lib.integration` passa a ter 49 classes. Decisão em [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

## Ação, classes por operação e extensão REST (2026-10-05, não compilado)

`MessageConfigLoader` (base) ganhou o buffer `b-thl-objeto-parametro-rest` e os métodos protegidos:

| Método | O que faz |
|---|---|
| `findRestExtension()` | Posiciona a extensão REST da operação já posicionada; pode não existir |
| `actionOf( methodType )` | Verbo → ação neutra (`ActionEnum`); 0 = sem ação |
| `resolveMethod()` | Verbo da extensão; sem ela (ou zero), o da operação |
| `resolveMessageClass()` / `resolveProcessorClass()` / `resolveServiceClass()` | Classe da operação, se informada; senão a do objeto |
| `buildConfig()` | Usa `findRestExtension`, `resolveMethod` e `resolveMessageClass` |

`OutboundConfigLoader` não mudou: procura a operação por estabelecimento/aplicação/objeto/operação com `find first` (uma operação de saída tem uma ação) e herda o novo `buildConfig`.

`InboundMessageConfig`: propriedades `requiredFields` e `externalReferenceFields` e `setContract( requiredFields, externalReferenceFields )`.

Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md).

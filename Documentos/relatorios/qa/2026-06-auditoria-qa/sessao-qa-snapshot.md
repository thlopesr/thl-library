# THL-QA — Snapshot de Sessão
Gerado em: 2026-06-11

---

## Contexto do Projeto

**Framework:** THL-Library — TOTVS Datasul 12 / OpenEdge 12 / PASOE (modo STATEFREE confirmado)
**Linguagem:** OpenEdge ABL / OOABL
**Total de classes:** 60 (thl-lib: 52 | thl-extensions: 8)
**Passagens QA executadas:** P1 → P7 concluídas | P8 em andamento

---

## Estado da Passagem 8

### Lotes concluídos

| Lote | Tipo | Tema | Itens | Status | Arquivo |
|------|------|------|-------|--------|---------|
| 1 | QA-Sugestões | Infraestrutura de Conexão | 5 | Sugestões geradas — **implementação pendente** | p8-lote1-resultado.md |
| 2 | Dev-Implementação | Autenticação e Configuração | 2 | **Aplicado ao código** | p8-lote2-aplicado.md |
| 3 | QA-Sugestões | Serviço de Auditoria e Ambiente | 3 | Sugestões geradas — **implementação pendente** | p8-lote3-resultado.md |
| 4 | QA-Sugestões | Factories | 4 | Sugestões geradas — **implementação pendente** | p8-lote4-resultado.md |
| 5 | QA-Sugestões | Repository e Repositório de Ambiente | 3 | Sugestões geradas — **implementação pendente** | p8-lote5-resultado.md |
| 6 | QA-Sugestões | OutboundMessageService + Message.constructor | 4 | Sugestões geradas — **implementação pendente** | p8-lote6-resultado.md |
| 7 | QA-Sugestões | InboundMessage + InboundMessageService | 5 | Sugestões geradas — **implementação pendente** | p8-lote7-resultado.md |
| 8 | QA-Sugestões | MessageExecutionService + ConnectorService | 4 | Sugestões geradas — **implementação pendente** | p8-lote8-resultado.md |
| 9 | QA-Sugestões | SchedulingService | 3 | Sugestões geradas — **implementação pendente** | p8-lote9-resultado.md |
| 10 | QA-Sugestões | Mensagens de Negócio (NF, Lpco, Embarque) | 5 | Sugestões geradas — **implementação pendente** | p8-lote10-resultado.md |
| 11 | QA-Sugestões | Email e Transversais (P3 sweep) | 15 | Sugestões geradas — **implementação pendente** | p8-lote11-resultado.md |

> ⚠️ **Lote 1 NÃO foi implementado.** O arquivo `p8-lote1-resultado.md` contém apenas sugestões
> de QA. Um arquivo `p8-lote1-aplicado.md` ainda não existe. A sessão Dev de Lote 1 está pendente.

### Itens do Lote 1 — aguardando implementação

| # | Classe.Método | SEV | Cat | Tipo | Resumo da Sugestão |
|---|---------------|-----|-----|------|--------------------|
| 1 | ConnectorFactory.createConnector | ALTA | D4 | CIRURGICA | Substituir CASE por registry TEMP-TABLE + DYNAMIC-NEW + block-level |
| 2 | RestConnector.execute | ALTA | B3 | CIRURGICA | VALID-OBJECT em validateExecutionInput + resolveAuthorizationKey |
| 3 | ConnectorConfig.constructor | MÉDIA | B1 | CIRURGICA | Guard connectionCode vazio + erro 17006 + initialize() private |
| 4 | ConnectorConfig.constructor | MÉDIA | D2 | CIRURGICA | Mover new AuthConfig para construtores; initialize() setter puro privado |
| 5 | RestConnector.(classe) | MÉDIA | D3 | CIRURGICA | resolveAuthorizationKey recebe ConnectorConfig em vez de AuthConfig |

> **Ordem de aplicação recomendada (p8-lote1-resultado.md):**
> 1º ConnectorConfig (itens 3+4 em edição coordenada única)
> 2º RestConnector (itens 2+5 em edição coordenada única)
> 3º ConnectorFactory (item 1)

### Itens do Lote 2 — aplicados

| # | Classe.Método | SEV | Cat | O que foi feito |
|---|---------------|-----|-----|-----------------|
| 1 | AuthenticationConfig.(classe) | ALTA | D2 | block-level adicionado; initialize() tornado private; saveToken() sem persistência DB; import EnvironmentResource removido (não utilizado); noop connectionCode= removido de initialize() |
| 2 | AuthenticationConfig.constructor | MÉDIA | B1 | Guard connectionCode vazio + código 17006 substituindo 0 |

### Lotes pendentes (estimativa)

| Lote | Tipo | Tema sugerido | Itens estimados |
|------|------|---------------|-----------------|
| 1-Dev | Dev-Implementação | Infraestrutura de Conexão (implementar sugestões do Lote1-QA) | 5 |
| 3-Dev | Dev-Implementação | Serviço de Auditoria e Ambiente (implementar sugestões do Lote3-QA) | 3 |
| 4-Dev | Dev-Implementação | Factories (implementar sugestões do Lote4-QA) | 4 |
| 5-Dev | Dev-Implementação | Repository (implementar sugestões do Lote5-QA) | 3 |
| 6 | QA+Dev | Mensageria Core e Fluxos Outbound | ~8 |
| 4 | QA+Dev | Design OO: Email e Mensagens Inbound | 6 |
| 5 | QA+Dev | Contexto, Ambiente e Repositórios | 3 |
| 6 | QA+Dev | Fluxo Outbound (OMSS/MEXS/CSVC + F1/F2/F3) | 9 |
| 7 | QA+Dev | Fluxo Inbound e Scheduling | 7 |
| 8 | QA+Dev | Padronização, Estratégias e ACEITO-PARC | 6 |

**Total de itens P8 restantes (de 40):** 0 itens pendentes — todos 40 cobertos nos Lotes 1-11

> ✅ **Passagem 8 QA encerrada.** Todos os lotes de sugestões foram gerados (Lotes 1, 3–11).
> Lote 2 foi sessão Dev-Implementação (2 itens aplicados). **Próxima etapa:** Sessão Dev — aplicação das correções por lote.

---

## Contagem de P8 por decisão P7

| Decisão | ALTA | MÉDIA | Total | Cobertos | Restantes |
|---------|------|-------|-------|----------|-----------|
| REJEITADO | 20 | 15 | 35 | 35 | **0** |
| ACEITO-PARC | 2 | 3 | 5 | 5 | **0** |
| **Total P8** | **22** | **18** | **40** | **40** | **0** |

---

## Pendência crítica do Lote 2

**Arquivo:** `Fontes\thl-lib\integration\connectors\types\RestConnector.cls`
**Método:** `executeTokenRequest()`
**O que fazer:** Após a linha `TokenProviderFactory:getProvider(...):parsingToken(authentication, response)`,
adicionar a chamada de persistência que foi removida de `saveToken()`:

```abl
new AuthenticationRepository():persistToken( authentication:connectionCode,
                                             authentication:token          ,
                                             authentication:tokenExpiration ).
```

**Motivo:** `AuthenticationConfig.saveToken()` agora só atualiza memória (D2 fix).
Sem esta linha em RestConnector, tokens renovados não são persistidos em
`thl-conexao-rest-autenticacao` e há re-autenticação a cada request STATEFREE.

---

## Decisões tomadas nesta sessão

- **STATEFREE confirmado:** PASOE opera em modo STATEFREE — objetos liberados ao fim de cada request. Achados B2 (DESTRUCTOR ausente) foram ACEITOS em P7 para todas as classes (Message, InboundObjectContext, OutboundMessageService, MessageFactory, MessageStructureStrategy).
- **Combinação de itens B1+D2 no mesmo arquivo:** Lote 1 sugeriu aplicar ConnectorConfig B1 e D2 em edição única coordenada. Mesma abordagem adotada no Lote 2 para AuthenticationConfig.
- **p8-lote2-resultado.md não foi gerado:** Lote 2 foi uma sessão Dev que trabalhou diretamente do P7. Não há arquivo de sugestões separado para Lote 2 — apenas o `p8-lote2-aplicado.md`.
- **Divergência B1 AuthenticationConfig:** O achado P3 descrevia "FIND-sem-AVAILABLE-check" mas o código real JÁ tinha o padrão correto (no-error + if not available). A correção real foi: guarda de connectionCode vazio + código de erro 17006.
- **Divergência B1 ConnectorConfig (Lote 1):** Mesma situação — FINDs já tinham AVAILABLE check. A P8-Lote1 corrigiu para: guarda de connectionCode vazio, código 17006, initialize() private.
- **initialize() público em VO/Config:** Padrão estabelecido nestes lotes — `initialize()` deve ser **private** em todas as classes de configuração (ConnectorConfig, AuthenticationConfig). Aplicar mesmo critério em classes similares nos próximos lotes.
- **Erro code 0 → 17006:** Código de erro `0` encontrado nos AppError de ConnectorConfig e AuthenticationConfig foi corrigido para `17006` (padrão DDK TOTVS do framework). Aplicar consistentemente nos próximos lotes.

---

## Padrões confirmados nesta sessão

- **`block-level on error undo, throw`** é obrigatório em todas as classes — ConnectorConfig já tinha; AuthenticationConfig não tinha (corrigido no Lote 2).
- **PASOE STATEFREE:** toda instância de objeto tem vida curta (por request). DESTRUCTOR é código morto neste modo.
- **`initialize()` deve ser `private`** em classes de configuração — evita bypass das validações do construtor.
- **Código de erro padrão THL = 17006** (código DDK TOTVS de customização) — usar em todos os `AppError` do framework.
- **Guard de valor vazio antes de FIND:** padrão adotado em ConnectorConfig e AuthenticationConfig — `if trim(code) = '' then undo, throw new AppError(...)` antes do `find first ... no-error`.
- **`saveToken()` em VO:** VO (Value Object) não deve persistir a si mesmo. Persistência deve ser responsabilidade do coordenador (RestConnector → AuthenticationRepository).
- **DYNAMIC-NEW com registro:** factory pattern esperado usa TEMP-TABLE com tipo→classe e `DYNAMIC-NEW`. Ver sugestão Lote 1 item 1 (ConnectorFactory).
- **substitute() para mensagens de erro:** usar `substitute('...&1...', valor)` em vez de concatenação com `+` nas mensagens de AppError.

---

## Anomalias encontradas

- **Divergência B1 em ConnectorConfig e AuthenticationConfig:** Ambas as classes já tinham o padrão `FIND + no-error + if not available + undo throw` correto. O achado P3 "FIND-sem-AVAILABLE-check" foi baseado no inventário comprimido P1 (que mostrou apenas "FIND"), não no código real. A verificação real do código revelou que o pattern estava correto; o que faltava eram: guarda de vazio, código 17006 e initialize() private.
- **import EnvironmentResource não utilizado em AuthenticationConfig:** `using thl-lib.core.environment.EnvironmentResource.` estava declarado mas nunca usado no corpo da classe. Removido no Lote 2.
- **Noop em initialize() de AuthenticationConfig linha 123:** `this-object:connectionCode = connectionCode` onde `connectionCode` não era parâmetro do método — resolvia para `this-object:connectionCode = this-object:connectionCode` (auto-atribuição inerte). Removido no Lote 2.
- **Cabeçalho errado em ConnectorFactory.cls:** O comentário de cabeçalho diz `File: ConnectorService` mas o arquivo é `ConnectorFactory`. Mesmo erro presente em ConnectorConfig.cls e AuthenticationConfig.cls. Cosmético — não afeta compilação.
- **p8-lote1-aplicado.md inexistente:** Lote 1 foi sessão QA (sugestões), não Dev (implementação). O arquivo de aplicação não existe pois as correções do Lote 1 ainda não foram implementadas.

---

## Itens P8 restantes por categoria

### ALTA — REJEITADO (17 restantes)
| Classe.Método | Cat | Tema |
|---------------|-----|------|
| EmailMessageFactory.(classe) | D2 | Design Email |
| ~~NotaFiscalPorEmbarqueMessage.methodPost~~ | ~~D2~~ | ~~Design Mensagem~~ → Lote 10 QA (ESTRUTURAL) |
| ~~OutboundMessageService.constructor~~ | ~~D3~~ | ~~Design Outbound~~ → Lote 6 QA (B*) |
| ~~InboundMessage.getRequiredFields~~ | ~~D5~~ | ~~Design Inbound~~ → Lote 7 QA (B* reclassificado) |
| ~~NotaFiscalPorEmbarqueMessage.methodPost~~ | ~~B1~~ | ~~Bug Mensagem~~ → Lote 10 QA |
| ~~MessageRepository.createMessage~~ | ~~B4~~ → Lote 5 QA |
| ~~AuditLogService.createRecord~~ | ~~B4~~ | ~~Bug Auditoria~~ → Lote 3 QA |
| ~~AuditLogService.b-audit-registro~~ | ~~B5~~ | ~~Bug Static~~ → Lote 3 QA |
| ~~EnvironmentContext.environmentParameter~~ | ~~B5~~ | ~~Bug Static~~ → Lote 3 QA |
| ~~EmailMessageFactory.(classe)~~ | ~~D2~~ | ~~Design Email~~ → Lote 4 QA (ESTRUTURAL) |
| ~~OutboundMessageService.(classe)~~ | ~~P2~~ | ~~Padrão Log~~ → Lote 6 QA |
| ~~MessageExecutionService.(classe)~~ | ~~P2~~ | ~~Padrão Log~~ → Lote 8 QA |
| ~~ConnectorService.(classe)~~ | ~~P2~~ | ~~Padrão Log~~ → Lote 8 QA |
| ~~ConnectorService.execute~~ | ~~F1~~ | ~~Fluxo Outbound~~ → Lote 8 QA |
| ~~InboundMessageService.receive~~ | ~~F1~~ | ~~Fluxo Inbound~~ → Lote 7 QA |
| ~~MessageExecutionService.executeOnline~~ | ~~F2~~ | ~~Fluxo Outbound~~ → Lote 8 QA |
| ~~OutboundMessageService.process/reprocess~~ | ~~F3~~ | ~~Fluxo Retry~~ → Lote 6 QA |
| ~~SchedulingService.schedule~~ | ~~F3~~ | ~~Fluxo RPW~~ → Lote 9 QA |

### ALTA — ACEITO-PARC (2 restantes)
| Classe.Método | Cat | Escopo reduzido |
|---------------|-----|-----------------|
| ~~Message.constructor~~ | ~~D3~~ | ~~Documentar contrato invariância; avaliar substituição em dev/homologação~~ → Lote 6 QA |
| ~~LpcoMessage.methodPost~~ | ~~B4~~ | ~~Verificar contexto transacional; adicionar DO TRANSACTION explícito~~ → Lote 10 QA |

### MÉDIA — REJEITADO (11 restantes)
| Classe.Método | Cat |
|---------------|-----|
| ~~InboundMessageService.constructor~~ | ~~D3~~ → Lote 7 QA |
| ~~OutboundMessageService.process~~ | ~~D4~~ → Lote 4 QA |
| ~~OutboundMessage.appendPayloadObject~~ | ~~D4~~ → Lote 4 QA |
| ~~InboundMessage.methodPost~~ | ~~D5~~ → Lote 7 QA |
| ~~SchedulingService.schedule~~ | ~~B1~~ | → Lote 9 QA |
| ~~MessageFactory.createStructureStrategy~~ | ~~B3~~ → Lote 4 QA |
| ~~EnvironmentRepository.findEnvironmentCodeByPropath~~ | ~~B4~~ → Lote 5 QA |
| ~~EmailMessageFactory.loadRecipients~~ | ~~B4~~ → Lote 4 QA (parte do D*) |
| ~~LpcoMessage.methodPost~~ | ~~P2~~ | → Lote 10 QA |
| ~~MessageRepository.(classe)~~ | ~~P3~~ → Lote 5 QA |
| ~~SchedulingService.schedule~~ | ~~F1~~ | → Lote 9 QA |
| ~~InboundMessageService.receive~~ | ~~F2~~ → Lote 7 QA |
| RestConnector.execute | F3 |

### MÉDIA — ACEITO-PARC (0 restantes)
| Classe.Método | Cat | Escopo reduzido |
|---------------|-----|-----------------|
| ~~EmailService.sender~~ | ~~B1~~ | ~~Verificar captura ERROR-STATUS antes de EmailLogger.save()~~ → Lote 11 QA |
| ~~EmbarqueMessage.methodPost~~ | ~~B4~~ | ~~Verificar atomicidade CREATE + appendMessageItem~~ → Lote 10 QA |
| ~~(multiplas-classes)~~ | ~~P3~~ | ~~Adicionar prefixo de programa às mensagens erro 17006~~ → Lote 11 QA |

---

## Decisões e anomalias — Lote 3

- **AuditLogService.b-audit-registro (B5):** Classificado como ESTRUTURAL. Remover `static` do buffer exige remover `static` de todos os métodos (updateRecord, insertRecord, deleteRecord, createRecord, isDuplicate). Impacto em todos os chamadores (API muda de `AuditLogService:X()` para `new AuditLogService():X()`). Mitigation cirúrgica temporária: `release b-audit-registro no-error` no início de `createRecord`.
- **AuditLogService.createRecord (B4):** Três correções cirúrgicas independentes: (a) envolver CREATE em `DO TRANSACTION`, (b) remover `no-error` do `release`, (c) adicionar CATCH que loga antes de relançar. Requer `using thl-lib.logging.LogUtil`.
- **EnvironmentContext.setEnvirommentParameter (B5):** Correção simples — adicionar `assign environmentParameter='' programName=''` antes do loop + trocar `routine-level` por `block-level`. Não muda interface. Dependente: EnvironmentResource (lê a propriedade estática).
- **ANOMALIA FORA DE ESCOPO — EnvironmentRepository.findVariableValue:** Condição INVERTIDA nas linhas 54 e 62 — `if not available` acessa campo de registro não posicionado. Bug de lógica (condição deveria ser `if available`). Sinalizado como spawn-task separado.

## Decisões e anomalias — Lote 5

- **MessageRepository.createMessage B4 (CIRURGICA):** `CREATE` sem `DO TRANSACTION` comita ao retornar o método — `createItemMessage()` é chamado depois em transação separada, gerando risco de `thl-mensagem` órfão. Fix: envolver CREATE+ASSIGN em `DO TRANSACTION` + CATCH com LogUtil. Chamador (Message.cls) deve envolver a sequência `createMessage()+createItemMessage()` em DO TRANSACTION externo. Mesma ausência existe em `createItemMessage`, `createHistoryMessage`, `createMessageContent` — aplicar na mesma sessão Dev.
- **MessageRepository.(classe) P3 (CIRURGICA):** 3 AppError sem prefixo de classe — `loadMessage`, `ensureMessageCode`, `ensureReferenceCode`. Prefixo proposto: `'MessageRepository: '`. Aproveitar para uniformizar idioma (inglês→português nos dois `ensureXxx`).
- **EnvironmentRepository.findEnvironmentCodeByPropath B4 (CIRURGICA):** `routine-level` → `block-level`; guard para propathValue vazio; fallback pós-loop trocado de "último registro visitado no FOR EACH" para `find first thl-ambiente no-lock` (determinístico). Bug `findVariableValue` (condição invertida) JÁ tem spawn-task — não corrigir aqui. Trocar `block-level` afeta todos os métodos do arquivo — verificar `findParameterCodeByProgram` e `findVariableValue` antes de aplicar.

## Decisões e anomalias — Lote 4

- **EmailMessageFactory D* (ESTRUTURAL):** Classe acumula Factory + Repository (4 tabelas: `thl-email-param`, `param_email`, `thl-ambiente-param-grupo-usuar`, `usuar_mestre`) + VO + lógica de resolução de destinatários. Requer criação de `EmailParamRepository`. Único chamador: `EmailService`. Também: CAN-FIND redundante antes de FOR EACH em `loadRecipients()`; dependência implícita no buffer `thl-email-param` posicionado desde o constructor.
- **MessageFactory.createStructureStrategy B3 (CIRURGICA):** `cast(message_, OutboundMessage)` sem TYPE-OF guard pode lançar SysError genérico se classe configurada no banco não herda de OutboundMessage. Fix: `if not type-of(message_, OutboundMessage) then undo, throw AppError(17006)`. Caller `OutboundMessageService.beginBuild()` também recebe guard `valid-object` — edição coordenada nos dois arquivos.
- **OutboundMessage.appendPayloadObject D4 (CIRURGICA):** `routeAppendPayloadObject` na classe abstrata contém IF de seleção de overload que pertence à camada strategy. Remover o método da base; IF migra para `MultipleMessageStructure` e `SingleMessageStructure`. Pesquisar todas as ocorrências antes de remover.
- **OutboundMessageService.process D4 (CIRURGICA):** Ramos ONLINE e SCHEDULE duplicam `valid-object(response) + successResponse`. Extrair para `evaluateResponse(response as ConnectorResponse)`. CASE em si é legítimo para ENUM de 3 valores; D4 residual classificado como backlog estrutural.

## Decisões e anomalias — Lote 6

- **OutboundMessageService.constructor B* (CIRURGICA BAIXO):** construtor usa compound ASSIGN sem valid-object entre as duas criações. Se `MessageConfigLoader():load()` retorna `?` silenciosamente, `new MessageFactory(?)` lança SysError genérico sem contexto. Fix: separar ASSIGN em dois blocos com valid-object + AppError(17006) com prefixo 'OutboundMessageService:' entre eles. Referência: InboundMessageService.constructor tem valid-object + type-of após criação. Aproveitar a edição para adicionar prefixo 'OutboundMessageService:' em todas as mensagens AppError da classe.
- **OutboundMessageService.(classe) P2 (CIRURGICA MEDIO):** `process()` sem CATCH — se `executeOnline()` lança antes de `message_:saveResponse()` (ex: conector recusa conexão), `thl-mensagem.sit-processamento` permanece 1 (pendente). Fix: CATCH em `process()` que constrói ConnectorResponse de falha e chama `saveResponse()` SE `connectorResponse = ?` (sinaliza que saveResponse ainda não foi chamado neste fluxo). Acrescenta `LogUtil:error()` para observabilidade PASOE. Requer `using thl-lib.logging.LogUtil`.
- **OutboundMessageService.reprocess F3 (CIRURGICA MEDIO):** `reprocess()` hardcoda `ExecutionMode:ONLINE` ignorando `configuration:executionModeValue`. Para configs SCHEDULE: SchedulingService já chamou `saveResponse()` (qtd-tentativas=1) e criou job RPW via `thl1989z.p`. Reprocessar ONLINE incrementa qtd-tentativas de novo (=2) e, se RPW ainda não foi cancelado, a mensagem é enviada duas vezes. Fix: guard no início de `reprocess()` — se `configuration:executionModeValue = SCHEDULE` then undo,throw AppError(17006) pedindo cancelamento prévio do RPW. Callers usam `loadForReprocess() + process(ONLINE)` diretamente após cancelar o job. `Message.executionMode` é `protected` — OutboundMessageService usa `configuration:executionModeValue` como proxy.
- **Message.constructor D3 ACEITO-PARC (documentação + avaliação):** `new MessageRepository()` e `new ErrorHandler()` são dependências concretas hardcoded. Invariância pós-construção: 7 propriedades de valor + repository + errorHandler devem ser válidos — subclasses herdam a garantia sem verificação adicional. Avaliação DI: Opção B (Template Method — `createRepository()` e `createErrorHandler()` como métodos protegidos virtuais) preferida sobre Opção A (overload de constructor) por não alterar a assinatura do constructor nem os callers existentes. Ambas as opções são exclusivas de dev/homologação.

## Decisões e anomalias — Lote 7

- **InboundMessage.validateRequiredFields B* (CIRURGICA BAIXO — reclassificado de D5):** `throwError()` no loop chama `clearErrors()` antes de adicionar — apenas o primeiro campo faltante gera AppError (bug de usabilidade, não segurança). Fix: usar `addError()` no loop + `throwIfHasErrors()` ao final para reportar todos os campos em um único AppError com múltiplas mensagens. Guard adicional: `if requiredFields = ?` → AppError imediato, distingue bug de subclasse de "sem campos obrigatórios". Aproveitar para prefixar mensagem com `'InboundMessage: '`.
- **InboundMessage.methodPost D5 (CIRURGICA MEDIO):** Método `protected void` não-abstract com corpo "throw not implemented" — ausência de override em subclasse concreta só descoberta em runtime. Fix: declarar `protected abstract void methodPost()`. Dependente: verificar DocumentoMessage, EmbarqueMessage, NotaFiscalPorEmbarqueMessage antes de aplicar — se não tiverem override, adicionar stubs explícitos. LpcoMessage e UsuarioMessage: já têm override correto. Recompilação completa do módulo inbound após aplicar.
- **InboundMessageService.constructor D3 (CIRURGICA BAIXO):** `new MessageConfigLoader()` + `new MessageFactory()` hardcoded — sem possibilidade de injeção. Fix: overload de constructor `(MessageConfig, InboundMessage)` com mesmas validações valid-object + type-of. Constructor de 4 params permanece inalterado. Nota: InboundRouteResolver NÃO é usado em InboundMessageService — a expectativa do P7 não se concretizou; a resolução de rota ocorre no chamador (resourcen.p).
- **InboundMessageService.receive F1 (CIRURGICA ALTO — BUG CRÍTICO):** Se `registerMessage()` (Etapa 1) falha, thl-mensagem não é criado. O CATCH chama `saveInboundError()` → `loadMessage()` lança `'Mensagem não encontrada'` → segunda exceção SUBSTITUI o erro original. Chamador recebe erro enganoso. Fix: `messageCreated` flag + CATCH aninhado no DO de `saveInboundError()` para não mascarar `errorObject`. Segundo problema: `undo, throw errorObject` reverte as gravações do `saveInboundError()` — mudar para `throw errorObject` (sem undo) para preservar as gravações na transação corrente. Limitação PASOE STATEFREE: se o framework reverter a sessão, as gravações DB são perdidas — `LogUtil:error()` é a única garantia de rastreabilidade.
- **InboundMessageService.receive F2 (CIRURGICA BAIXO):** Nenhuma chamada a `LogUtil` em `receive()`. Fix incorporado em F1: `LogUtil:error()` no início do CATCH, antes de `saveInboundError()`. F1 e F2 devem ser aplicados na mesma edição de `receive()`.
- **ANOMALIA: InboundRouteResolver não é dependência de InboundMessageService.** O P7 flagou D3 esperando que InboundRouteResolver seria injetado no serviço. Código real mostra que a resolução de rota está no chamador externo. O D3 real é sobre MessageConfigLoader + MessageFactory hardcoded.

## Decisões e anomalias — Lote 8

- **MessageExecutionService.(classe) P2 (CIRURGICA BAIXO):** Sem LogUtil e CAST sem TYPE-OF guard. `cast(message_, OutboundMessage)` é chamado no parâmetro `pathParameters` sem verificação prévia; o parâmetro formal é `message_ as Message` (base abstrata). Se caller futuro passar InboundMessage, lança SysError genérico. Fix aditivo: `using thl-lib.logging.LogUtil` + `if not type-of(message_, OutboundMessage) then undo, throw AppError('MessageExecutionService: mensagem para objeto &1 nao e OutboundMessage.', 17006)` antes do CAST. Inserir junto com F2 na mesma edição. AuditLogService: não aplicável nesta camada técnica sem operação de negócio rastreável. `EnvironmentResource:resolveParameterCode()` já é o padrão correto (sem acesso direto ao banco).
- **MessageExecutionService.executeOnline F2 (CIRURGICA MEDIO):** Compound ASSIGN inclui `new ConnectorService():execute()` numa única instrução. Se qualquer etapa lança (ConnectorConfig inválido, CAST falso, etc.), `connectorResponse = ?`, `saveResponse()` nunca chamado, `sit-processamento` fica em 1 indefinidamente. **Contexto crítico:** RestConnector.execute() TEM CATCH INTERNO que converte TODA exceção em ConnectorResponse de falha — RestConnector NUNCA lança. Portanto o CATCH em `executeOnline()` só se ativa para falhas no *building* do request. Fix: (1) separar compound ASSIGN em 2 instruções (`build request` separado de `execute`); (2) CATCH com `LogUtil:error` + se `connectorResponse = ?` → montar ConnectorResponse de falha + `message_:saveResponse(errResponse, false)` + `undo, throw e`; (3) `LogUtil:info` na entrada e no sucesso.
- **ConnectorService.(classe) P2 (CIRURGICA BAIXO):** Sem LogUtil. AppError sem prefixo de classe: `'ConnectorRequest was not informed.'` e `'Unable to resolve integration connector.'`. Fix aditivo: `using thl-lib.logging.LogUtil` + prefixar mensagens com `'ConnectorService: '`. Segundo AppError: adicionar `substitute()` com `request:connectorType` para identificar o tipo inválido. **Atenção:** renomear texto AppError é BREAKING se chamadores comparam literal — verificar antes de aplicar.
- **ConnectorService.execute F1 (CIRURGICA MEDIO):** Três lacunas independentes: (1) **resposta nula** — `connector:execute()` poderia retornar `?` para conector não-RestConnector mal implementado; fix: `if not valid-object(response)` → throw AppError. (2) **HTTP failures silenciosas** — `successResponse=false` (HTTP 4xx/5xx absorvido no CATCH interno do RestConnector) passa pelo ConnectorService sem nenhuma linha no log PASOE; fix: `LogUtil:warn` quando `not response:successResponse`. (3) **sem CATCH para exceções de factory** — `ConnectorFactory:createConnector()` pode lançar AppError para tipo desconhecido; ConnectorService propaga sem log; fix: CATCH com `LogUtil:error` + `undo, throw e`. Separar `assign response = connector:execute(request)` em instrução própria (não embutido no `return`) para que CATCH possa referenciar `request:connectorType` sem NPE.
- **ANOMALIA detectada durante leitura:** `RestConnector.cls` usa `routine-level on error undo, throw` (linha 28) em vez de `block-level`. Este achado já foi sinalizado como B* no Lote 1. Não tratar no Lote 8.

## Decisões e anomalias — Lote 9

- **SchedulingService.schedule — PATCH UNIFICADO (B1 + F3 + F1):** Três categorias resolvidas em um único patch por estarem no mesmo método sem conflito entre as correções.
- **B1 + F1 combinados (CIRURGICA MEDIO):** `block-level on error undo, throw` JÁ existe na linha 17 — B1 não é sobre sua ausência. O problema real: se `run thl\thl1989z.p` lança Progress.Lang.Error (procedure não encontrada, DB, timeout), nenhum CATCH intercepta antes de `saveResponse()`, e `thl-mensagem` fica com `sit-processamento = 1` indefinidamente. Fix: CATCH ao nível do método com `LogUtil:error` + se `response = ?` → montar ConnectorResponse de falha + `message_:saveResponse(errorResponse, false)` + `throw e` (sem `undo`). Os caminhos `return-value = 'NOK'` e `numPedidoExecucao = 0/null` já têm `saveResponse` explícito — o CATCH só ativa para falhas inesperadas do `run`.
- **F3 BUG DOCUMENTADO (CIRURGICA MEDIO):** Discrepância crítica entre o comentário do método (linha 25: "successProcess = ? indica que o processamento ainda nao ocorreu") e o código (linha 76: `response:successProcess = true`). Impacto confirmado via `MessageRepository.saveResultMessage()` linha 101: `successProcess = true` → `sit-processamento = 3` (processado com sucesso), quando o RPW ainda não executou. Mesmo bug em `statusCode = 200` — o comentário diz que deveria ser `numPedidoExecucao`. Fixes: (1) `successProcess = ?` → `sit-processamento = 4` (desconhecido/pendente RPW); (2) `statusCode = numPedidoExecucao` para rastreabilidade do job RPW. Quando o RPW executar, `saveResponse()` sobrescreve ambos com o resultado HTTP real.
- **Atenção antes de aplicar F3:** Verificar se ferramentas de monitoramento/retry filtram mensagens por `sit-processamento`. Se algum processo busca `sit-processamento = 1` (pendente) para retry automático, a mudança não quebra nada (o RPW job já tem o código da mensagem diretamente). Se busca `sit-processamento = 3` para confirmar execução, o processo verá `4` (desconhecido) até o RPW completar — correto semanticamente.
- **ANOMALIA FORA DE ESCOPO — MessageRepository.saveResultMessage() linha 102:** `b-thl-mensagem.sit-requisicao = if successResponse = ? then 4 else if successRequest then 3 else 2`. Verifica `successResponse = ?` (campo errado) para o teste de unknown; depois usa `successRequest` (campo correto para sit-requisicao) para o ramo positivo. Aparente inconsistência: deveria ser `if successRequest = ? then 4 else if successRequest then 3 else 2`. Sinalizado como spawn-task separado.

## Decisões e anomalias — Lote 11

- **EmailParamRepository.loadRecipients B4 (CIRURGICA BAIXO):** Método nomeado originalmente como "EmailMessageFactory.loadRecipients" (antes da refatoração D*). No código atual está em `EmailParamRepository`. Problema: sem guard para `groupCode` vazio — FOR EACH com `where cod-grp-usuar = ''` retorna destinatários não intencionados. Fix: `if not StringUtil:hasValue(groupCode) then return ''.` antes do FOR EACH. NO-LOCK já correto em todos os acessos.
- **EmailService.sender B1 (CIRURGICA BAIXO — ACEITO-PARC):** `saveReturn()` usa `not tt-erros:has-records` para sucesso mas não verifica `error-status:error`. Fix mínimo: incluir `not error-status:error and` na expressão do parâmetro de `emailLogger:save()`. `routine-level on error` já garante que exceções propagam — o gap é apenas para falhas de retorno suave (ERROR-STATUS sem throw).
- **(múltiplas-classes) P3 (CIRURGICA BAIXO — ACEITO-PARC) — 12 classes:** Sweep final de prefixo `'ClassName: '` em AppError. Classes cobertas: EmailParamRepository (3), RestConnector (6), MessageFactory (2), MessageConfigLoader (4), ConnectorFactory (1), ConnectorConfig (4), AuthenticationConfig (2), OutboundMessage (3), OutboundObjectContext (2), InboundMessage (8), TokenProvider (5), JsonWriter (1). Classes já cobertas em lotes anteriores: ConnectorService (L8), MessageExecutionService (L8), SchedulingService (L9), LpcoMessage (L10), NotaFiscalPorEmbarqueMessage (L10), OutboundMessageService (código já tem prefix), MessageRepository (código já tem prefix). Prefixo aplicado é `'ClassName: '` (sem `'THL-'`), conforme padrão estabelecido no projeto.
- **RestConnector.execute F3 (CIRURGICA MÉDIO):** Sem validação de esquema de URL. `ConnectorConfig.baseUrl` pode ser `http://` sem erro. `ServicePointManager:SecurityProtocol = TLS12` não previne HTTP. Fix: separar compound ASSIGN em `execute()` para adicionar `if not (requestUrl begins 'https://')` após `buildRequestUrl()` → `undo, throw AppError 17006`. **BREAKING CHANGE:** verificar ambientes com HTTP antes de aplicar. Comportamento de CATCH e contrato ConnectorResponse mantidos.
- **ANOMALIA LOTE 11:** `routine-level on error undo, throw` em RestConnector (linha 28) ainda pendente como B3 do Lote 1 — não tratar no contexto F3. Também: `emailLogger:save()` em `EmailLogger.save()` faz CREATE sem DO TRANSACTION explícito — potencial B4, documentado para sessão futura.

## Decisões e anomalias — Lote 10

- **NotaFiscalPorEmbarqueMessage.methodPost D2 (ESTRUTURAL — backlog):** `methodPost` despacha 4 operações de negócio completamente distintas via `context:operation` ('', 'impressao', 'autorizacao-sefaz', 'notificacao'). Violação de SRP. Fix estrutural: criar `NotaFiscalPorEmbarqueService` com `execute(b-embarque, operation, payload_, outPayload)`. Desafio: métodos privados usam temp-tables de classe (`tt-res-cli`, `tt-nota-gerada`, `tt-nota-fiscal`) e `this-object:throwRowErrorsIfAny()` / `this-object:addInvoiceSefazPayload()`. Dependências precisam ser parametrizadas ou replicadas no Service. Tratado como **BACKLOG** — sessão separada com análise de acoplamento dedicada.
- **NotaFiscalPorEmbarqueMessage.methodPost B1 (CIRURGICA BAIXO):** Dois achados: (1) `AppError(..., 0)` no `otherwise` do CASE — código `0` deve ser `17006`; adicionar prefixo `'NotaFiscalPorEmbarqueMessage: '`. (2) `run setPreFaturFree in h-bodi162` na linha 180 está **FORA** do `DO TRANSACTION` (que termina na linha 178) e **FORA** do bloco `finally` (linhas 194-203). Se `throwRowErrorsIfAny()` lança dentro do transaction, a execução vai direto para FINALLY — `setPreFaturFree` nunca é chamado, deixando o embarque em estado `in-use` indefinidamente. Fix: mover `run setPreFaturFree` para dentro do `finally` com `no-error`. Também prefixar `throwError` na linha 55.
- **LpcoMessage.methodPost B4 (CIRURGICA MEDIO — ACEITO-PARC):** `create b-nit-lpco` sem `DO TRANSACTION` explícito. `block-level` já proporciona rollback implícito. Fix: envolver `create` + 14 SetValue + `appendMessageItemByReference` em `do transaction / end.`. Comportamento idêntico ao atual — mudança é de documentação e demarcação de atomicidade. Aproveitar para prefixar `AppError 'LPCO ja existe.'` com `'LpcoMessage: '`.
- **LpcoMessage.methodPost/methodDelete P2 (CIRURGICA BAIXO):** Sem LogUtil em nenhum dos dois métodos. AppError sem prefixo. Fix: `LogUtil:info` apos operações, prefixo `'LpcoMessage: '` em AppError. **B1 detectado fora do escopo P2:** `delete b-nit-lpco no-error.` (methodDelete linha 111) suprime QUALQUER erro do DELETE silenciosamente. Fix B1: remover `no-error` — aplicar junto com P2 na mesma edição.
- **EmbarqueMessage.methodPost B4 (CIRURGICA MEDIO — ACEITO-PARC):** `appendMessageItemByExternalReference` (linha 105) está ANTES do `do transaction` (linha 137); `appendCreatedShipmentItem` (linha 150) está DEPOIS do `end.` do transaction (linha 148). Fix: expandir o `do transaction` existente para incluir ambas as chamadas de `appendItem`. `setShipmentSuccessPayload` e setup de handle permanecem fora. Comportamento de atomicidade idêntico ao atual.
- **ANOMALIA ADICIONAL EmbarqueMessage:** `methodDelete` linha 174 verifica `if not available b-embarque` após `appendCreatedShipmentItem` (que faz FIND como side effect) — padrão frágil. Documentado para sessão separada.

## Próxima etapa — Sessão Dev

**Passagem 8 QA encerrada.** Todos os lotes de sugestões QA foram gerados (Lotes 1, 3–11). O Lote 2 foi a única sessão Dev executada (AuthenticationConfig).

**Sessões Dev pendentes — aplicar por ordem de dependência:**

| Prioridade | Lote | Arquivo de referência | Itens |
|------------|------|-----------------------|-------|
| 1 | Lote 1-Dev | p8-lote1-resultado.md | 5 (ConnectorConfig, RestConnector, ConnectorFactory) |
| 2 | Lote 3-Dev | p8-lote3-resultado.md | 3 (AuditLogService, EnvironmentContext) |
| 3 | Lote 4-Dev | p8-lote4-resultado.md | 4 (EmailMessageFactory D*, MessageFactory, OutboundMessage) |
| 4 | Lote 5-Dev | p8-lote5-resultado.md | 3 (MessageRepository, EnvironmentRepository) |
| 5 | Lote 6-Dev | p8-lote6-resultado.md | 4 (OutboundMessageService, Message.constructor) |
| 6 | Lote 7-Dev | p8-lote7-resultado.md | 5 (InboundMessage, InboundMessageService) |
| 7 | Lote 8-Dev | p8-lote8-resultado.md | 4 (MessageExecutionService, ConnectorService) |
| 8 | Lote 9-Dev | p8-lote9-resultado.md | 3 (SchedulingService) |
| 9 | Lote 10-Dev | p8-lote10-resultado.md | 5 (NotaFiscalPorEmbarqueMessage, LpcoMessage, EmbarqueMessage) |
| 10 | Lote 11-Dev | p8-lote11-resultado.md | 15 (EmailParamRepository, RestConnector, 12 classes P3) |

**CONSOLIDAÇÃO P8:** CIRURGICA: 48 | ESTRUTURAL: 3 | TOTAL QA: 51

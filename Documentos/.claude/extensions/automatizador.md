# Extensão: automatizador

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| LpcoMessage (outbound) | Mensagem outbound que serializa um LPCO (`nit-lpco`) para envio ao Automatizador | Template Method | OutboundMessage | OutboundMessageService (via config) |
| LpcoMessage (inbound) | Mensagem inbound de CRUD de LPCO: POST/PATCH/DELETE pelos defaults de `InboundMessage`; GET com listagem paginada | Template Method + Factory Method | InboundMessage, LpcoService, MethodTypeEnum | InboundMessageService (via `thl-objeto.classe-objeto`) |
| LpcoService | Serviço de domínio do LPCO: criação (com numeração sequencial por emitente), atualização, exclusão física e listagem paginada | Service (Template Method via `Service`) | Service, JsonSetter, PaginationHelper, ThlError | LpcoMessage (inbound) |

> **Movidas em 2026-09-24:** `LpcoMessage` (inbound) e `LpcoService` saíram de `thl-lib` (`…messaging.inbound.message` e `erp.service`) porque dependem do schema do cliente (`nit-lpco`). ⚠️ O registro de `thl-objeto.classe-objeto` da mensagem inbound precisa apontar para o novo nome completo.

---

## LpcoMessage (outbound — Automatizador)

**Caminho:** `thl-extensions\integration\automatizador\messaging\outbound\message\LpcoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.automatizador.messaging.outbound.message.LpcoMessage`

**Responsabilidade:** Implementa `appendPayloadObject()` para serializar campos do `nit-lpco` como JSON para integração com o sistema Automatizador. Inclui lookup de moeda (`moeda of b-nit-lpco`) para obter o código ISO de 3 caracteres.

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`.

**Tabelas acessadas:** `nit-lpco`, `moeda`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject()` | Busca moeda, inicializa `JsonObject`, popula campos: `codigo_emitente`, `numero_interno_lpco`, `codigo_cliente`, `faixa` (A/V), `moeda` (ISO da `moeda.char-2` pos 43 len 3), `quantidade`, `valor`, `ncm`, `descricao`, `informacoes_adicionais`. |
| `method public override character onLoadData( register as recid )` | Carrega `b-nit-lpco` por recid; retorna `"cod-emitente#num-interno-lpco"`. Lança via `errorHandler` se não encontrado. |

**Observações:**
- O código ISO da moeda é extraído de `moeda.char-2` com `substring(..., 43, 3)` — dependência de convenção de layout do campo.
- A flag `faixa` converte `logical` para `'A'` (faixa alta/ampla) ou `'V'` (faixa baixa/verde) — semântica específica do domínio Automatizador.
- Mesmo nome simples da mensagem inbound (`LpcoMessage`), em outro pacote: qualificar o `USING` quando as duas forem usadas juntas.

---

## LpcoMessage (inbound — Automatizador)

**Caminho:** `thl-extensions\integration\automatizador\messaging\inbound\message\LpcoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.automatizador.messaging.inbound.message.LpcoMessage`

**Responsabilidade:** Contrato inbound do CRUD de LPCO. POST, PATCH e DELETE usam os defaults de `InboundMessage` (`executeService` → `createService():execute(...)`); o GET faz a listagem paginada por faixa de número interno.

**Padrão de projeto:** Template Method (subclasse de `InboundMessage`) + Factory Method (`createService()`).

**INHERITS / IMPLEMENTS:** `inherits InboundMessage`

**Dependências diretas THL:** `InboundMessage` (via `USING thl-lib.integration.messaging.inbound.core.*`), `LpcoService`, `Service`, `ActionEnum`, `MethodTypeEnum`.

**Construtor:** `constructor public LpcoMessage( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode )` — repassa ao `super`. Instanciada por `MessageFactory` via `dynamic-new` com o nome em `thl-objeto.classe-objeto`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override Service createService()` | Retorna `new LpcoService()`. |
| `method protected override void methodGet()` | Lê os query params `NumeroInternoIni` (default `0`) e `NumeroInternoFin` (default `999999999`), cria a paginação com `createPagination( 100 )` (params `pageSize`/`page`) e chama `LpcoService:get(...)`. Para cada item, registra `referenceCode`/`externalReferenceCode` e chama `appendItem()`. |
| `method public override character getExternalReferenceField()` | `'numeroLpco'`. |
| `method protected override character getRequiredFields()` | PATCH, PUT e DELETE: `'codigoEmitente,numeroInternoLpco'`; demais (POST): `'codigoEmitente'`. |

**Contrato JSON (campos aceitos no payload / devolvidos no GET):** `codigoEmitente`, `numeroInternoLpco`, `classificacaoFiscal`, `descricao`, `faixaMercadoria`, `informacoesAdicionais`, `codigoMoeda`, `numeroLpco`, `paisDestino`, `quantidade`, `saldoQuantidade`, `saldoValor`, `situacao`, `unidade`, `valorTotal`, `valorUnitario`, `dataValidade`; o GET acrescenta `referenceCode`.

---

## LpcoService

**Caminho:** `thl-extensions\erp\automatizador\service\LpcoService.cls`

**Namespace ABL:** `thl-extensions.erp.automatizador.service.LpcoService`

**Responsabilidade:** Manutenção de `nit-lpco`: criação, atualização, exclusão e listagem paginada. Serviço "standalone" — herda só `Service` (sem BusinessObject/API Datasul).

**Padrão de projeto:** Service, com Template Method herdado de `thl-lib.erp.core.Service` (`execute()` → `initialize()` → `create()`/`update()`/`delete()` → `loadReferenceCode()` → `buildResponse()`).

**INHERITS / IMPLEMENTS:** `inherits Service`

**Dependências diretas THL:** `Service`, `JsonSetter`, `PaginationHelper`, `ThlError`.

**Tabelas acessadas:** `nit-lpco`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override character getEntityName()` | `'LPCO'`. |
| `method protected override void initialize()` | `positionRecord()`: `find first b-nit-lpco exclusive-lock` por `codigoEmitente` + `numeroInternoLpco` do `inContext` (`no-error`). |
| `method protected override void create()` | Rejeita se o registro já existe. Calcula `numeroInternoLpco = último num-interno-lpco do emitente + 1` (ou `1`), força `situacao = 1`, cria o registro em `do transaction` e mapeia os campos via `JsonSetter`. |
| `method protected override void update()` | Exige o registro posicionado; aplica `mapFields`. |
| `method protected override void delete()` | Exige o registro posicionado; **`delete` físico**. |
| `method public JsonArray get( pager as PaginationHelper, numInternoIni as integer, numInternoFin as integer )` | `for each` por faixa de `num-interno-lpco`, respeitando `pager` (`incrementPageCount`/`shouldSkipEntry`/`shouldStopPaging`); devolve um `JsonArray` com os campos do contrato + `referenceCode`. |
| `method protected override character loadReferenceCode()` | `cod-emitente#num-interno-lpco` do buffer posicionado (serve à escrita e à listagem). |

**Tratamento de erro:** `ThlError` para "LPCO ja existe." / "LPCO nao localizado." (os nomes de método nas mensagens — `criarLpco`, `atualizarLpco`, `excluirLpco` — são rótulos antigos, não os métodos reais).

**Observações:**
- ⚠️ **Numeração sequencial sem bloqueio:** `find last … no-lock` + `create` — duas criações simultâneas para o mesmo emitente podem gerar o mesmo `num-interno-lpco` (depende de índice único em `nit-lpco`, NÃO CONFIRMADO).
- A listagem do `get()` filtra só por faixa de número interno — **não filtra por emitente**.
- Diferente de `FretePrevistoService` (DVV), aqui o `delete` é físico.

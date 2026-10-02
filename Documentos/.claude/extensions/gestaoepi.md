# Extensão: gestaoepi

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| HeaderProvider | Calcula os headers de autenticação HMAC-SHA256 exigidos pelo callback do GestaoEPI | Strategy (implementa `IHeaderProvider`) | IHeaderProvider, ThlError, .NET (`HMACSHA256`, `Encoding`, `BitConverter`, `DateTimeOffset`) | HeaderProviderFactory → RestConnector (via config) |
| RequisicaoMessage | Outbound com a requisição inteira e **todos** os itens (status fixo "Entrege") | Template Method | OutboundMessage | OutboundMessageService (via config) |
| ItemRequisicaoMessage | Outbound com **um** item de requisição e status vindo do contexto | Template Method | OutboundMessage | OutboundMessageService (via config) |

> Nota criada em 2026-09-24 (lacuna L4 do diagnóstico).

---

## HeaderProvider

**Caminho:** `thl-extensions\integration\gestaoepi\connectors\headers\HeaderProvider.cls`

**Namespace ABL:** `thl-extensions.integration.gestaoepi.connectors.headers.HeaderProvider`

**Responsabilidade:** Gera os headers exigidos pela API de callback do GestaoEPI:
- `X-Datasul-Timestamp` — Unix timestamp UTC em segundos;
- `X-Datasul-Signature` — `"sha256=" + hex(HMAC-SHA256( timestamp + "." + body, secret ))`, em minúsculas.

**Padrão de projeto:** Strategy — implementa `thl-lib.integration.connectors.headers.interfaces.IHeaderProvider` e é instanciado por `HeaderProviderFactory:getProvider(className)` via `dynamic-new`.

**Como é ligado:** `ConnectorConfig` lê `thl-conexao-rest-header`. O nome completo da classe vem de `classe-parser` (`headerProviderClass`) e o *secret* do campo `parameters` (`headerParameter`), repassado a `getHeaders( contentText, headerParameter )`. O `RestConnector` só chama o provider quando `requiresHeaderProvider` está ativo.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public JsonArray getHeaders( body as longchar, parameters as character )` | Lança `ThlError` se `parameters` (o secret) estiver vazio. Calcula o HMAC com as classes .NET e devolve `[{key,value}, {key,value}]`. Faz `Dispose()` do `HMACSHA256` no `finally`. |

**Observações:**
- Depende do CLR (.NET) no agente PASOE/AVM.
- O cabeçalho cita `thl-conexao-rest-caberario.valor-parametro` e a mensagem de erro cita `thl-conexao-rest-header.valor-parametro`. **Nenhum dos dois está certo:** o campo lido de fato é `thl-conexao-rest-header.parameters` (`ConnectorConfig.cls:99`).
- A assinatura usa `string(body)`: o `longchar` é convertido para `character`, o que limita o corpo ao tamanho máximo de `character`. Payloads grandes podem falhar (NÃO CONFIRMADO o volume real).

---

## RequisicaoMessage

**Caminho:** `thl-extensions\integration\gestaoepi\messaging\outbound\message\RequisicaoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.gestaoepi.messaging.outbound.message.RequisicaoMessage`

**INHERITS:** `OutboundMessage` · **Tabelas:** `requisicao`, `it-requisicao`.

| Assinatura | Descrição |
|---|---|
| `method public override character onLoadData( register as recid )` | Posiciona `requisicao` por recid; retorna `nr-requisicao`. |
| `method public override void appendPayloadObject( objectContext as OutboundObjectContext )` | `{ numero_requisicao, itens: [ { it_codigo, status: "Entrege", qt_atendida } … ] }` com **todos** os itens da requisição. |

**Observações:** o status é fixo e grafado `'Entrege'` (sic). `USING FileUtil` e a variável `count` não são usados. Cabeçalho em branco.

---

## ItemRequisicaoMessage

**Caminho:** `thl-extensions\integration\gestaoepi\messaging\outbound\message\ItemRequisicaoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.gestaoepi.messaging.outbound.message.ItemRequisicaoMessage`

**INHERITS:** `OutboundMessage` · **Tabelas:** `it-requisicao`.

| Assinatura | Descrição |
|---|---|
| `method public override character onLoadData( register as recid )` | Posiciona `it-requisicao` por recid; retorna `nr-requisicao`. |
| `method public override void appendPayloadObject( objectContext as OutboundObjectContext )` | `{ numero_requisicao, itens: [ { it_codigo, status, qt_atendida } ] }` com um único item; `status` = `objectContext:additionalData:GetCharacter('content')`. |

**Uso típico (histórico de teste, arquivo hoje removido):** `new OutboundMessageService( 'GestaoEPI', 'ItemRequisicao', 'Atualizacao' )` + `addObject( new OutboundObjectContext( recid( it-requisicao ), '', 'ENTREGUE' ) )` — o 3º argumento vira `additionalData.content`.

**Observações:** sem referência estática no código (resolvida pelo banco). Se o contexto vier sem `additionalData.content`, o `GetCharacter` lança erro.

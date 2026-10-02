# Extensão: iacompras

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| ProcessoCompraMessage | Outbound que envia um processo de compra (dados, fornecedores com contato e ordens com quantidade) para o IA Compras | Template Method | OutboundMessage, StringUtil, ThlError | OutboundMessageService (via config) |

> Nota criada em 2026-09-24 (lacuna L4 do diagnóstico). Classe criada em 2026-09-16.

---

## ProcessoCompraMessage

**Caminho:** `thl-extensions\integration\iacompras\messaging\outbound\message\ProcessoCompraMessage.cls`

**Namespace ABL:** `thl-extensions.integration.iacompras.messaging.outbound.message.ProcessoCompraMessage`

**INHERITS:** `OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`, `StringUtil` (`formatIsoDate`), `ThlError`.

**Tabelas acessadas (buffers private):** `proc-compra`, `proc-fornec`, `emitente`, `cont-emit`, `ordem-compra`, `item`, `prazo-compra`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override character onLoadData( register as recid )` | Posiciona `proc-compra` por recid; retorna `nr-processo`. `ThlError` se não encontrado. |
| `method public override void appendPayloadObject()` | Valida o registro posicionado e monta o payload com os 3 blocos abaixo. |
| `method private void buildProcessData()` | Raiz: `Processo`, `Descricao`, `Comprador`, `Data_Inicio` (ISO), `Narrativa`. |
| `method private void addSuppliers()` | `Fornecedor[]`: para cada `proc-fornec`, o `emitente` e o contato **`cont-emit` de sequência 10** → `Fornec`, `Nome_Abrev`, `Nome`, `Email`. |
| `method private void addOrders()` | `Ordem[]`: `ordem-compra` do processo + `item` → `Ordem`, `Item`, `Descricao`, `Qtd`. |
| `method private decimal calculateOrderQuantity()` | Soma `prazo-compra.quantidade` da ordem corrente. |

**Contrato JSON (resumo):**
```json
{ "Processo": 0, "Descricao": "", "Comprador": "", "Data_Inicio": "AAAA-MM-DD", "Narrativa": "",
  "Fornecedor": [ { "Fornec": 0, "Nome_Abrev": "", "Nome": "", "Email": "" } ],
  "Ordem":      [ { "Ordem": 0, "Item": "", "Descricao": "", "Qtd": 0 } ] }
```

**Observações:**
- Um fornecedor **sem** contato de sequência 10 é omitido silenciosamente (join `first … sequencia = 10`).
- Uma ordem cujo item não existe é omitida (join `first b-item`).
- `onLoadData` é `protected override`, enquanto as outras extensões usam `public override` — as duas formas compilam (a base declara `protected abstract`).

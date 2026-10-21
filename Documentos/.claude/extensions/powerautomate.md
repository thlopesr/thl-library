---
tipo: modulo
camada: extension
status: vigente
tags: [extensao, powerautomate]
updated: 2026-10-13
---

# Extensão: powerautomate

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| SolicitacaoCompraMessage | Outbound que envia ao Power Automate uma **ordem de compra** ou uma **solicitação (item de requisição)**, conforme o registro recebido | Template Method | OutboundMessage, StringUtil, OrderStatusEnum, RequestStatusEnum | OutboundMessageService (via config) |
| OrderStatusEnum | Situação da ordem de compra (`ordem-compra.situacao`) | Enum | — | SolicitacaoCompraMessage |
| RequestStatusEnum | Situação do item de requisição (`it-requisicao.situacao`) | Enum | — | SolicitacaoCompraMessage |

> Nota criada em 2026-09-24 (lacuna L4 do diagnóstico). Classes de 2026-09-05; lógica portada das procedures `pi-ordem` / `pi-solicitacao`.

---

## SolicitacaoCompraMessage

**Caminho:** `thl-extensions\integration\powerautomate\messaging\outbound\message\SolicitacaoCompraMessage.cls`

**Namespace ABL:** `thl-extensions.integration.powerautomate.messaging.outbound.message.SolicitacaoCompraMessage`

**INHERITS:** `OutboundMessage` · **Payload:** `JsonArray` (`initializeArrayPayload()`), um objeto por registro — pensado para a estrutura *Multiple*.

**Tabelas acessadas:** `ordem-compra`, `it-requisicao`, `requisicao`, `item`, `item-uni-estab`, `requisitante`, `prazo-compra`, `cotacao-item`, `sub-div-ordem`, `proj-inv`.

**Métodos principais:**

| Assinatura | Descrição |
|---|---|
| `method public override character onLoadData( register as recid )` | Tenta posicionar `ordem-compra` pelo recid (referência = `numero-ordem`); se não achar, tenta `it-requisicao` (referência = `nr-requisicao#sequencia#it-codigo`); senão lança `AppError('Registro nao encontrado.', 17006)`. |
| `method public override void appendPayloadObject()` | Inicializa o array (se necessário) e chama `appendPurchaseOrder()` quando há ordem posicionada; senão, `appendPurchaseRequest()`. |
| `method private void appendPurchaseOrder()` | Objeto da ordem de compra (ver contrato). `qt-requisitada` = saldo pendente dos prazos; `preco-unit` = `getUnitPrice()`. |
| `method private void appendPurchaseRequest()` | Objeto da solicitação: `numero-ordem = 0`, `nr-processo = 0`, `sit-ordem = ''`, `situacao` pelo `RequestStatusEnum`; `narrativa` via `getNarrative`. |
| `method private decimal getUnitPrice()` | Prioridade: `cotacao-item` aprovada → `it-requisicao` da ordem → última `ordem-compra` do item com preço > 0 → `0`. |
| `method private character getNarrative( itemDescription, contractType )` | Para `tipo-contr = 4`, prefere a narrativa da requisição/item; senão, a descrição do item. |
| `loadItemData`, `loadItemEstablishment`, `loadInvestmentProject`, `getRequesterName`, `getOutstandingBalance`, `getOrderStatusLabel`, `getRequestStatusLabel` | Lookups auxiliares (item, `item-uni-estab` → estratégico `tp-ressup = 3` e comprador, projeto de investimento, requisitante, saldo, rótulos de situação). |

**Contrato JSON (cada elemento do array):** `nome`, `nr-requisicao`, `dt-requisicao` (ISO), `situacao`, `numero-ordem`, `cod-comprado`, `sit-ordem`, `nr-processo`, `qt-requisitada`, `preco-unit`, `fm-codigo`, `un`, `estrat` (`SIM`/`Nao`), `it-codigo`, `narrativa`, `num-projeto`, `descricao`.

**Observações:**
- ⚠️ **`onLoadData` decide o tipo do registro pelo recid**, tentando primeiro `ordem-compra`. Recids só são únicos dentro de uma área de armazenamento; se as duas tabelas compartilharem a área, um recid de `it-requisicao` pode casar por acaso com uma `ordem-compra` (NÃO CONFIRMADO no schema). Seria mais seguro distinguir o tipo pelo contexto (ex.: `additionalData`).
- `getOrderStatusLabel` não trata `ELIMINADA` nem `RECEBIDA` (devolve `''`).
- `getRequestStatusLabel` devolve `'Com Ordem'` para qualquer situação fora do enum.
- Lança `Progress.Lang.AppError` direto em vez de `ThlError`, diferente do padrão da biblioteca.

---

## OrderStatusEnum

**Namespace ABL:** `thl-extensions.integration.powerautomate.messaging.outbound.enum.OrderStatusEnum`

`NAO_CONFIRMADA = 1`, `CONFIRMADA = 2`, `COTADA = 3`, `ELIMINADA = 4`, `EM_COTACAO = 5`, `RECEBIDA = 6`.

## RequestStatusEnum

**Namespace ABL:** `thl-extensions.integration.powerautomate.messaging.outbound.enum.RequestStatusEnum`

`ABERTA = 1`, `FECHADA = 2`, `PENDENTE_COMPL = 3`.

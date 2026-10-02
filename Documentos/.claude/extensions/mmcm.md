# Extensão: mmcm

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| TokenProvider | Implementa `ITokenProvider` extraindo token e validade de resposta JSON aninhada (`data.data.token`) | Strategy | ITokenProvider, AuthenticationConfig | TokenProviderFactory (via dynamic-new) |
| PrePedidoMessage | Outbound que serializa embarque com pré-faturas (`pre-fatur`) para a API MMCM | Template Method | OutboundMessage | OutboundMessageService (via config) |
| PedidoMessage | Outbound que serializa nota fiscal com arquivo NF em Base64 para a API MMCM | Template Method | OutboundMessage, FileUtil | OutboundMessageService (via config) |

---

## TokenProvider

**Caminho:** `thl-extensions\integration\mmcm\connectors\auth\TokenProvider.cls`

**Namespace ABL:** `thl-extensions.integration.mmcm.connectors.auth.TokenProvider`

**Responsabilidade:** Implementa `ITokenProvider` para a API MMCM, que retorna o token em dois níveis de aninhamento JSON: `response.data.data.token`. Extrai o token e sua data de validade (`validade`) e os persiste via `AuthenticationConfig:saveToken`.

**Padrão de projeto:** Strategy (implementação concreta de `ITokenProvider`).

**INHERITS / IMPLEMENTS:** `implements ITokenProvider`

**Dependências diretas THL:** `ITokenProvider`, `AuthenticationConfig`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void parsingToken( authentication as AuthenticationConfig, response as JsonObject )` | Navega `response → data → data`, extrai `token` (character) e `validade` (datetime); chama `authentication:saveToken`. Lança `Progress.Lang.AppError` (código 17006) em cada etapa de navegação se o nó não existir ou for inválido. |

**Observações:**
- Usa `Progress.Lang.AppError` diretamente em vez de `ThlError` — não segue o padrão `[Classe.método]` da biblioteca.
- A estrutura `data.data.token` é peculiar à API MMCM (envelope duplo) — qualquer mudança na resposta quebrará a autenticação silenciosamente se o CATCH da `ConnectorService` não propagar o erro.

---

## PrePedidoMessage

**Caminho:** `thl-extensions\integration\mmcm\messaging\outbound\message\PrePedidoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.mmcm.messaging.outbound.message.PrePedidoMessage`

**Responsabilidade:** Serializa um embarque (`embarque`) com todas as suas pré-faturas (`pre-fatur`) e itens (`it-pre-fat`) como um array `pedidos` para a API MMCM. Sobrescreve `parseBusinessProcess` para ler `data.success` da resposta e determinar se o processamento foi bem-sucedido.

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`, `StringUtil`.

**Tabelas acessadas:** `embarque`, `pre-fatur`, `it-pre-fat`, `emitente`, `estabelec`.

**Construtor:**

```
constructor public PrePedidoMessage(
    objectName           as character,
    applicationName      as character,
    integrationOperation as character,
    methodType           as integer,
    connectorType        as integer,
    integrationDirection as logical,
    executionMode        as integer
)
```

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject()` | Itera `pre-fatur` pelo `cdd-embarq` do embarque; para cada pré-fatura monta objeto com `entrega`, `cliente` (cgc), `pedido`, `pedido_cliente`, `num_carga` e array de `itens` (codigo/qtde). Adiciona campo `token = ''`. Usa `this-object:initializeObjectPayload()` e adiciona ao payload via cast para `JsonObject`. |
| `method public override character onLoadData( register as recid )` | Carrega `b-embarque` por recid; retorna `"cdd-embarq#nr-embarque"`. Lança via `errorHandler` se não encontrado. |
| `method protected override logical parseBusinessProcess( input response as longchar )` | Parseia resposta; retorna `data:GetLogical('success')`. Retorna `false` se response vazio, não for JsonObject, ou não tiver campo `data`. CATCH loga via `log-manager` e retorna `false` — não propaga erro. |

**Observações:**
- O campo `token` é enviado como string vazia `''` no payload — provavelmente populado externamente pelo `ConnectorService` (autenticação Bearer/Token); o campo no JSON pode ser um legado.
- `appendPayloadObject()` assina o override de `void` (sem parâmetros), não a variante `( objectContext as OutboundObjectContext )` — compatível com `SingleMessageStructure`.
- `it-pre-fat` está sendo iterado mas o `item` (variável local) é reatribuído em cada iteração e apenas a última iteração é adicionada ao `items` array — possível bug onde somente o último item de cada pré-fatura é serializado.

---

## PedidoMessage

**Caminho:** `thl-extensions\integration\mmcm\messaging\outbound\message\PedidoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.mmcm.messaging.outbound.message.PedidoMessage`

**Responsabilidade:** Serializa uma nota fiscal (`nota-fiscal`) com o arquivo XML/PDF da NF em Base64 para a API MMCM. Suporta múltiplos anexos adicionais via `objectContext:additionalData['files']`. Define o parâmetro de rota `#Pedido#` com o número do pedido do cliente.

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`, `FileUtil`, `OutboundObjectContext`.

**Tabelas acessadas:** `nota-fiscal`.

**Construtor:**

```
constructor public PedidoMessage(
    objectName           as character,
    applicationName      as character,
    integrationOperation as character,
    methodType           as integer,
    connectorType        as integer,
    integrationDirection as logical,
    executionMode        as integer
)
```

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject( objectContext as OutboundObjectContext )` | Monta payload: `token = ''`, `nota_fiscal`, `serie_nota_fiscal`, `chave_acesso`, `nf_base64` (arquivo indicado por `additionalData['file']` convertido via `FileUtil:loadFileAsBase64`). Opcionalmente itera `additionalData['files']` para construir array `anexos`. Define path parameter `#Pedido#` com `b-nota-fiscal.nr-pedcli`. |
| `method public override character onLoadData( register as recid )` | Retorna `"cod-estabel#serie#nr-nota-fis"`. Lança via `errorHandler` se não encontrado. |

**Extensão / hook points:** Assina `appendPayloadObject( objectContext as OutboundObjectContext )` — variante com contexto de `MultipleMessageStructure`. Esperado que o chamador injete o caminho do arquivo via `additionalData`.

**Observações:**
- `FileUtil:loadFileAsBase64` lança `ThlError` se o arquivo não existir — se `additionalData['file']` for inválido, a mensagem toda falha.
- `setPathParameter('#Pedido#', b-nota-fiscal.nr-pedcli)` — o `nr-pedcli` é o número do pedido do cliente, usado como identificador na URL da API MMCM.
- `block-level on error undo, throw` ativo — erros não silenciados.

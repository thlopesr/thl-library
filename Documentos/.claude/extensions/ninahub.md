---
tipo: modulo
camada: extension
status: vigente
tags: [extensao, ninahub]
updated: 2026-10-13
---

# Extensão: ninahub

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| ChamadoMessage | Outbound que monta o payload de abertura de chamado na Ninahub a partir de um template JSON armazenado em variável de ambiente | Template Method | OutboundMessage, EnvironmentResource | OutboundMessageService (via config) |
| NinahubNotaFiscalMessage | Inbound de NF da Ninahub: estende `NotaFiscalMessage` e injeta `NinahubNotaFiscalService` via `createService()` | Template Method + Factory Method | NotaFiscalMessage, NinahubNotaFiscalService | InboundMessageService (via `thl-objeto.classe-objeto`) |
| NinahubNotaFiscalService | Especialização de `NotaFiscalService`: natureza de operação por tipo de operação Ninahub, transportadora, canal de venda, preço do payload, dados complementares em `es_nota_terceiros` e PDF em Base64 na resposta | Service (hooks de Template Method) | NotaFiscalService, FileUtil, ThlError | NinahubNotaFiscalMessage |

> **Sincronizado em 2026-09-24.** Absorveu a antiga `nina.md` (removida), que descrevia essas classes com os nomes antigos `NinaNotaFiscal*` e pacotes `…nina…` que não existem. Os cabeçalhos `File :` dos dois `.cls` ainda dizem `NinaNotaFiscal*`.

---

## ChamadoMessage

**Caminho:** `thl-extensions\integration\ninahub\messaging\outbound\message\ChamadoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.ninahub.messaging.outbound.message.ChamadoMessage`

**Responsabilidade:** Constrói o payload de abertura de chamado para a API Ninahub. O corpo da mensagem é integralmente baseado em um template JSON armazenado na variável de ambiente `infoAberturaChamado` (via `EnvironmentResource`). Apenas o campo `descricao` é sobrescrito dinamicamente com o conteúdo de `objectContext:getAdditionalDataContent()`.

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`, `EnvironmentResource`, `OutboundObjectContext`.

**Tabelas acessadas:** `embarque` (somente em `onLoadData`).

**Construtor:** padrão de 7 parâmetros (`objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode`), repassado ao `super`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject( objectContext as OutboundObjectContext )` | Lê o template JSON da variável de ambiente `infoAberturaChamado` com `fix-codepage UTF-8`; parseia para `JsonObject`; substitui (ou adiciona) o campo `descricao` com `objectContext:getAdditionalDataContent()`; atribui o objeto a `this-object:payload`. |
| `method public override character onLoadData( register as recid )` | Carrega `b-embarque` por recid; retorna `"cdd-embarq#nr-embarque"`. Lança via `errorHandler` se não encontrado. |

**Observações:**
- `block-level on error undo, throw` está **ativo** (a versão anterior desta nota dizia que estava comentado — corrigido no código).
- O payload inteiro vem do template de ambiente: qualquer campo além de `descricao` é configurado fora do código. Flexível, mas o contrato da API fica implícito.
- `createDate` recebe `now` e não é usado — variável morta.
- `new EnvironmentResource()` é instanciado a cada chamada.
- Cabeçalho copiado de outro arquivo (`File : centroCusto`, 2021).

---

## NinahubNotaFiscalMessage

**Caminho:** `thl-extensions\integration\ninahub\messaging\inbound\message\NinahubNotaFiscalMessage.cls`

**Namespace ABL:** `thl-extensions.integration.ninahub.messaging.inbound.message.NinahubNotaFiscalMessage`

**Responsabilidade:** Especialização de `NotaFiscalMessage` para a Ninahub. Só sobrescreve `createService()`, devolvendo `NinahubNotaFiscalService` fixo — ignora o `routePath` que a base usa para escolher entre NF direta e NF por embarque.

**Padrão de projeto:** Template Method (subclasse de `NotaFiscalMessage`) + Factory Method (`createService`).

**INHERITS:** `thl-lib.integration.messaging.inbound.message.NotaFiscalMessage`.

**Dependências diretas THL:** `NotaFiscalMessage`, `NinahubNotaFiscalService`, `Service`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override Service createService()` | Retorna `new NinahubNotaFiscalService()`. |

**Herdado de `NotaFiscalMessage`/`InboundMessage`:** `loadExternalReference`, `getRequiredFields`, e os verbos POST/PATCH/DELETE padrão (`executeService` → `Service:execute`).

---

## NinahubNotaFiscalService

**Caminho:** `thl-extensions\erp\ninahub\service\NinahubNotaFiscalService.cls`

**Namespace ABL:** `thl-extensions.erp.ninahub.service.NinahubNotaFiscalService`

**Responsabilidade:** Especializa os hooks de `thl-lib.erp.service.NotaFiscalService` com as regras da Ninahub.

**INHERITS:** `NotaFiscalService` (→ `NotaFiscalBaseService` → `BusinessObject` → `Service`).

**Dependências diretas THL:** `NotaFiscalService`, `FileUtil`, `ThlError`.

**Tabelas acessadas:** `nit-tipo-oper`, `nit-tipo-oper-natur`, `estabelec`, `loc-entr`, `item`, `emitente`, `transporte`, `es_nota_terceiros` (escrita).

**Buffers protected:** `b-nit-tipo-oper`, `b-estabelec`, `b-loc-entr`.

**Overrides:**

| Assinatura | Descrição |
|---|---|
| `method protected override void createInvoice()` | Chama `super:createInvoice()`. Se o payload trouxer `ccusto`, `responsavel`, `codigoEstabelecimento` e `seqWtDocto`, cria/atualiza `es_nota_terceiros` (chave `seq_wt_docto` + `cod_estabel`) com centro de custo e responsável. |
| `method protected override void printInvoiceWorker()` | Chama o `super`; se o payload tiver `arquivo`, adiciona `arquivo-base64` (via `FileUtil:loadFileAsBase64`) ao 1º objeto de `outPayload`. |
| `method protected override character resolveNature()` | Posiciona `nit-tipo-oper` (`tipo-operacao`), `estabelec` (`cod-estabel`), `loc-entr` (`cod-entrega` + `nome-abrev`) e o `item` do **primeiro** item do payload; busca `nit-tipo-oper-natur` por tipo de operação + estadual/interestadual (`loc-entr.estado = estabelec.estado`) + `log-baixa-estoque = item.baixa-estoq`. Retorna `nat-operacao`. |
| `method protected override character resolveNatureItem( item as JsonObject )` | Mesmo lookup para cada item, reaproveitando os buffers posicionados por `resolveNature()` (acoplamento temporal, garantido pela ordem de `createInvoice()` na base). |
| `method protected override character resolveTransport()` | Emitente por `cod-transp` (se vier) ou `nome-abrev` → `transporte` por CNPJ ou `cod-transp`; retorna `transporte.nome-abrev`. |
| `method protected override integer resolveSalesChannel()` | `emitente.cod-canal-venda` pelo `nome-abrev`. |
| `method protected override JsonObject getPrice( item as JsonObject )` | Devolve o próprio item — o preço vem no payload, sem cálculo. |

**Tratamento de erro:** `FIND`s sem `NO-ERROR` + um `CATCH` por método que relança `ThlError` com a mensagem original ("Erro ao resolver natureza de operacao…", "…transportadora…", "…canal de venda…").

**Observações:**
- ⚠️ Em `resolveNatureItem`, o parâmetro se chama `item` — o mesmo nome da tabela `item` usada no `find first item … where item.it-codigo = item:GetCharacter(...)`. Ambíguo de ler; confirmar que o compilador resolve como esperado.
- `es_nota_terceiros` usa *underscore* (tabela customizada de outro schema) — NÃO CONFIRMADO em qual banco.
- A natureza passou a depender também de `log-baixa-estoque` do item (a versão anterior desta nota não tinha esse critério).

## 2026-10-05 — Message de entrada retirada (não compilado)

`NinahubNotaFiscalMessage` virou `.cls.old`: Message e Processor padrão com `NinahubNotaFiscalService`; chave externa na extensão REST (`codigoEstabelecimento`, `serie`, `numeroNotaFiscal`, unidos por `#`, como a `NotaFiscalMessage` montava). `ChamadoMessage` (saída) não mudou. Sistema `ninahub`: 2 classes. Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md). As seções acima que descrevem a Message de entrada são histórico.

---
tipo: modulo
camada: extension
status: vigente
tags: [extensao, automatizador]
updated: 2026-10-13
---

# Extensão: automatizador

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| LpcoMessage (outbound) | Mensagem outbound que serializa um LPCO (`nit-lpco`) para envio ao Automatizador | Template Method | OutboundMessage | OutboundMessageService (via config) |
| LpcoMessage (inbound) | Mensagem inbound de CRUD de LPCO: POST/PATCH/DELETE pelos defaults de `InboundMessage`; GET com listagem paginada | Template Method + Factory Method | InboundMessage, LpcoService, MethodTypeEnum | InboundMessageService (via `thl-objeto.classe-objeto`) |
| ProcessoExportacaoMessage (outbound) | Lote de processos de exportacao (`processo-exp`) para o RPA, modo Multiple, corpo `{ "processos": [...] }` | Template Method | OutboundMessage | OutboundMessageService (via config) |
| LpcoService | Serviço de domínio do LPCO: criação (com numeração sequencial por emitente), atualização, exclusão física e listagem paginada | Service (Template Method via `Service`) | Service, JsonSetter, PaginationHelper, ThlError | LpcoMessage (inbound) |
| AutomatizadorMedicaoContratoService | Medição de contrato do Automatizador: validações V-01 a V-06 e V-09 a V-13 (V-07, V-08 e V-15 saíram: toda medição tem NF do RPA, com número e vencimento do próprio registro), **um método por regra** chamados em ordem pelo `validateMedicao` (`validateContract`, `validateSupplierActive`, `validateSupplierRequired/Exists/Matrix`, `validateInvoiceKey`, `loadInvoiceInRpa`, `validateInvoiceOwner`, `validateInvoiceRequired`, `validateDueDateRequired/NotPast/Minimum/ByContract`; o erro sai com o nome do método da regra); V-13/V-15 só avisam; V-14 omitida; V-09 (`resolveRpaMode`) desvia as regras do RPA, grava `es_ext_medicao_contrat`, `es_mla_lotacao_docto`, `rpa_nf_xml` e (quando vier `notaFiscal.codigoBarra`) `nit-integra-rpa-boleto` antes da API padrão (`MedicaoContratoService`), `integra_rpa_item` depois (o item da NF é o de `it_codigo` = código do item da medição; item não encontrado vira aviso). Tudo numa transação. Arquivos em base64 deixaram de ser recebidos. JSON: raiz = medição, `matrizRateio[]`, `notaFiscal{ codEmitente, chaveNf, tipoNf, codigoBarra }` (o número e o vencimento da NF vêm de `integra_rpa.nro_docto` e `integra_rpa.data_vencto`, não do JSON) (filha 1 para 0..1; `tipoNf` NFE, NFS, NFT ou NFR; `chaveNf`+`tipoNf` com o estabelecimento do contrato formam a chave primária de `integra_rpa`, localizada uma vez em `b-integra-rpa` e usada por V-13, V-15 e `integra_rpa_item`; `chaveNf` e `tipoNf` são sempre obrigatórios (exceto quando V-09 desvia as regras do RPA) e o registro tem de existir no RPA; a NF do RPA tem de ser do fornecedor informado) e `automatizador{ codLotacao, preenchimentoManual }`. `codigoBarra` é opcional: informado, grava `nit-integra-rpa-boleto` (chave `cod-estabel`, `chave-nota-fisc` = `chaveNf` e `tipo-nota-fiscal` = `tipoNf`; cria se não existir; `chaveNf` até 60 e `codigoBarra` até 50 caracteres; não grava quando V-09 desvia as regras do RPA). Rota `medicao-contrato/automatizador`. Campos obrigatórios no cadastro da operação (thl0022a, aba REST): `nrContrato,numSeqItem,numeroOrdem,numSeqEvent,numSeqMedicao` (a `InboundMessage` valida; a classe não repete). `notaFiscal.chaveNf` e `notaFiscal.tipoNf` são validados na classe (campos aninhados). O estabelecimento da medição (`tt-medicao.cod-estabel`) é sempre o do contrato; o `codEstabel` do JSON não é usado. Não compilado | Service (Template Method via hooks do `MedicaoContratoService`) | MedicaoContratoService, `JsonUtil`, `JsonSetter` | Processor (cadastro do objeto/operação) |

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

## 2026-10-05 — Message de entrada retirada (não compilado)

`LpcoMessage` de entrada virou `.cls.old`: o objeto usa a Message e o Processor padrão com `LpcoService`. O contrato foi para a extensão REST das operações (criar: `codigoEmitente`; alterar e eliminar: `codigoEmitente`, `numeroInternoLpco`; chave externa `numeroLpco`). `LpcoService` ganhou `consult()` (filtros `NumeroInternoIni`/`NumeroInternoFin`, paginação por `page`/`pageSize`); a lista chega ao `resourcen.p` como `{ items, hasNext: false }` — conferir que a resposta é a mesma de antes. A `LpcoMessage` de **saída** não mudou. Sistema `automatizador`: 2 classes. Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md). As seções acima que descrevem a Message de entrada são histórico.

## 2026-10-13 — ProcessoExportacaoMessage (outbound, não compilado)

**Caminho:** `thl-extensions\integrationutomatizador\messaging\outbound\message\ProcessoExportacaoMessage.cls`

Substitui o envio direto de `esex1986rp.p` (legado mantido até a validação em HML). Objeto `Automatizacao / ProcessoExportacao / Envio`, `ind-mensagem-simples` = Multiple. `onLoadData(recid)` valida `processo-exp`, `proces-exp-adic` e `es_processo_exp` e devolve `cod-estabel#nr-proc-exp`; `appendPayloadObject()` cria a raiz `{ "processos": [] }` na primeira chamada e acrescenta um objeto por processo (`codigoEstabelecimento`, `numeroProcessoExportacao`, `codigoSituacao`, `terminalEmbarque`, `idVeiculo`, `numeroViagem`). `dataEmbarque` estava comentado no legado e não foi migrado. O RPW `esex1987rp.p` (fora deste repositório, em `Nitro\Melhorias±0-048050`) faz a seleção e chama `OutboundMessageService`. Smoke test: `Utils/test/testProcessoExportacao.p`. ⚠️ O reenvio repete o lote inteiro; idempotência do RPA não confirmada.

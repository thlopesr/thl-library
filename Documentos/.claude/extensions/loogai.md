---
tipo: modulo
camada: extension
status: vigente
tags: [extensao, loogai]
updated: 2026-10-13
---

# Extensão: loogai

> **Sincronizado em 2026-09-24** com o código: contrato `Service` (sem `IService`), verbos pelos defaults de `InboundMessage` (`executeService`), assinaturas dos hooks sem parâmetro `payload`, `buildResponse` próprio e seção nova de `StatusDocumento`.

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| EntregaPedidoMessage | Outbound que serializa uma entrega de pedido de venda com rotas, item e dados do pedido para a Loog.ai | Template Method | OutboundMessage | OutboundMessageService (via config) |
| NotaFiscalMessage | Outbound que serializa uma nota fiscal (chave SEFAZ, embarque, NF) para a Loog.ai | Template Method | OutboundMessage | OutboundMessageService (via config) |
| LoogAiDocumentoMessage | Inbound da Loog.ai que estende DocumentoMessage, injetando LoogAiDocumentoService via createService() | Template Method | DocumentoMessage, DocumentoService | InboundMessageService (via config) |
| LoogAiDocumentoService | Serviço de domínio: lógica de natureza de operação por incidência fiscal (PIS/COFINS/ICMS) para a Loog.ai | Service | DocumentoService (herança) | LoogAiDocumentoMessage |
| LoogAiEmbarqueMessage | Inbound da Loog.ai que estende InboundMessage, injetando LoogAiEmbarqueService via createService() | Template Method | InboundMessage, LoogAiEmbarqueService | InboundMessageService (via config) |
| LoogAiEmbarqueService | Serviço de domínio: especializa EmbarqueService com lookup por CNPJ (contrato Loog.ai) | Service | EmbarqueService (herança) | LoogAiEmbarqueMessage |

---

## EntregaPedidoMessage

**Caminho:** `thl-extensions\integration\loogai\messaging\outbound\message\EntregaPedidoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage`

**Responsabilidade:** Serializa uma entrega de pedido de venda (`ped-ent`) para a API da Loog.ai com estrutura complexa: delivery (dados de entrega, cliente, estabelecimento, representante, datas), order (pedido, segmento, tipo: VENDA/BONIFICAÇÃO/TRANSFERÊNCIA), item (produto, família comercial), rotas (origem e destino com geolocalização).

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Dependências diretas THL:** `OutboundMessage`.

**Tabelas acessadas:** `ped-ent`, `ped-item`, `item`, `fam-comerc`, `ped-venda`, `canal-venda`, `estabelec`, `emitente`, `repres`, `es_ped_venda`, `es_ped_item`, `es_ped_ent`, `nit-loc-entr`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject()` | Constrói JSON hierárquico (`delivery`, `order`, `item`, `rotas`) e adiciona ao `JsonArray` do payload. Inclui lógica de tipo de carga (TRANSFERENCIA para emitentes que começam com 'COMPANHIA NITRO'). |
| `method public override character onLoadData( register as recid )` | Carrega `b-ped-ent` por recid; retorna chave composta de 8 campos. Lança via `errorHandler` se não encontrado. |

**Observações:**
- O tipo `'BONIFICACAO'` é detectado via `substring(ped-venda.char-1, 162, 5) = '54' or '56'` — dependência de layout de campo livre.
- `valorFreteEntrega` usa `es_ped_item.vlr_unit_frete` quando disponível, senão `1` — valor padrão questionável.
- Geolocalização de destino vem de `nit-loc-entr` (tabela de extensão customizada).

---

## NotaFiscalMessage

**Caminho:** `thl-extensions\integration\loogai\messaging\outbound\message\NotaFiscalMessage.cls`

**Namespace ABL:** `thl-extensions.integration.loogai.messaging.outbound.message.NotaFiscalMessage`

**Responsabilidade:** Serializa dados de uma nota fiscal (`nota-fiscal`) para a Loog.ai: chave SEFAZ, número do embarque, número do pedido, estabelecimento, série, número da NF, valor total, peso e data de cancelamento.

**Padrão de projeto:** Template Method (subclasse de `OutboundMessage`).

**INHERITS / IMPLEMENTS:** `inherits OutboundMessage`

**Tabelas acessadas:** `nota-fiscal`, `emitente`, `estabelec`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject()` | Busca emitente e estabelec da NF; monta `JsonObject` com 11 campos. |
| `method public override character onLoadData( register as recid )` | Retorna `"cod-estabel#serie#nr-nota-fis"`. Lança via `errorHandler` se não encontrado. |

---

## LoogAiDocumentoMessage

**Caminho:** `thl-extensions\integration\loogai\messaging\inbound\message\LoogAiDocumentoMessage.cls`

**Namespace ABL:** `thl-extensions.integration.loogai.messaging.inbound.message.LoogAiDocumentoMessage`

> **Refatorado em 2026-07-24 (thl-coding — separação Message/Service):** parecer arquitetural classificou como SEPARAR/ALTA prioridade — a classe com maior densidade de regra de negócio do lote de inbound sem Service. Toda a lógica de `prepareDocumentos` migrou para `LoogAiDocumentoService`; a Message ficou reduzida a `createService()` (override) + `getRequiredFields()`.

**Responsabilidade:** Especialização de `DocumentoMessage` para a Loog.ai. Sobrescreve `createService()` para injetar `LoogAiDocumentoService`, que concentra o lookup de estabelecimento, transportadora, condição de pagamento e determinação da natureza de operação por incidência fiscal (PIS/COFINS/ICMS) via tabela `nit-loog-natur-oper`.

**Padrão de projeto:** Template Method (subclasse de `DocumentoMessage`) — extensão via Factory Method (`createService`), não mais via override direto de `prepareDocumentos`.

**INHERITS / IMPLEMENTS:** `inherits DocumentoMessage`

**Dependências diretas THL:** `DocumentoMessage`, `DocumentoService`, `LoogAiDocumentoService`.

**Campos obrigatórios:** `tipoDocumento`, `cnpjEstabelecimento`, `cnpjTransportadora`, `documentoCliente`, `aliquotaCofins`, `aliquotaPis`, `aliquotaIcms`, `chaveAcesso`, `valorTotal`, `dataEmissao`, `serie`, `numeroDocumento`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method protected override Service createService()` | Retorna `new LoogAiDocumentoService()`. O retorno é a classe abstrata `thl-lib.erp.core.Service` (não existe interface `IService`). |
| `method protected override character getRequiredFields()` | Retorna lista de 12 campos obrigatórios (inalterado). |

---

## LoogAiDocumentoService

**Caminho:** `thl-extensions\erp\loogai\service\LoogAiDocumentoService.cls`

**Namespace ABL:** `thl-extensions.erp.loogai.service.LoogAiDocumentoService`

> **Movido em 2026-07-24 (sessão 6):** de `thl-extensions.integration.loogai.messaging.inbound.service` para `thl-extensions.erp.loogai.service`, acompanhando a mesma mudança do pai `DocumentoService` (`thl-lib.integration.messaging.inbound.service` → `thl-lib.erp.service`) — ver [`erp/erp-services.md`](../erp/erp-services.md).

**Responsabilidade (sincronizado 2026-07-27):** Serviço de domínio extraído de `LoogAiDocumentoMessage` (SRP). Sobrescreve o hook `prepareDocumentData` de `DocumentoService` com lógica de lookup de estabelecimento, transportadora, condição de pagamento e determinação da natureza de operação por incidência fiscal (PIS/COFINS/ICMS) via tabela `nit-loog-natur-oper`. Trata fluxo de Entrada (com rateio) e Saída diferenciadamente. Refatorado em 2026-07-27 para decomposição OO em 8 métodos protected.

**Padrão de projeto:** Service (subclasse de `DocumentoService`, especializa o hook Template Method).

**INHERITS:** `thl-lib.erp.service.DocumentoService`.

**Dependências diretas THL:** `DocumentoService` (herança), `ThlError`.

**Tabelas acessadas:** `estabelec`, `emitente` (buffer `b-emitente`), `mg.cidade`, `nit-loog-natur-oper`, `nota-fiscal`, `docum-est`, `item-doc-est`, `it-nota-fisc`, `cond-pagto`, `nit-frete-real` (buffer `b-nit-frete-real`).

**Properties protected (sincronizado 2026-07-27):**

| Nome | Tipo | Descrição |
|---|---|---|
| `hasPis` | `logical` | Incide PIS — determinada por `resolveEntry` / `resolveExit` |
| `hasCofins` | `logical` | Incide COFINS (= hasPis) |
| `hasIcms` | `logical` | Incide ICMS (aliquotaIcms <> '0.00') |
| `destinationState` | `character` | Estado destino para cálculo estadual/interestadual |
| `clientInvoiceNumber` | `character` | Número da NF do cliente (parseado de CSV) |
| `clientInvoiceSeries` | `character` | Série da NF do cliente (parseada de CSV) |

**Constantes de layout `char-2` (novo 2026-07-27):**

| Nome | Posição | Significado |
|---|---|---|
| `CHAR2_TIPO_NF_ENTRADA` | 143 | Flag de tipo de NF (1=Entrada, 0=Saída) |
| `CHAR2_ORIGEM_LOOGAI` | 151 | Flag de origem Loog.ai |
| `CHAR2_ESTADO_ORIGEM` | 211 | UF de origem |
| `CHAR2_IBGE_MUNICIPIO_ORIGEM` | 246 | Código IBGE do município de origem |
| `CHAR2_IBGE_MUNICIPIO_DESTINO` | 236 | Código IBGE do município de destino |

**Métodos protected (sincronizado 2026-07-27):**

| Assinatura | Descrição |
|---|---|
| `method protected override void prepareDocumentData( payload )` | Orquestrador: chama os 8 métodos abaixo na sequência correta, com branch por `tipoDocumento`. |
| `method protected void resolveEntities( payload )` | Posiciona `estabelec`, `bCarrier`, `cond-pagto`. Lança erro se não encontrar. |
| `method protected void parseClientInvoice( payload )` | Extrai `clientInvoiceNumber` e `clientInvoiceSeries` do primeiro elemento do array `notaFiscalTransportada`. |
| `method protected void buildDocumentHeader( payload )` | Cria `tt-docum-est` com os campos base (18 assigns). |
| `method protected void resolveEntry( payload )` | Localiza emitente/cidade/docum-est de referência, determina `hasPis`/`hasCofins`, posiciona `cidade` destino. |
| `method protected void resolveExit( payload )` | Localiza cidade/nota-fiscal/emitente, determina `hasPis`/`hasCofins`, posiciona `cidade` destino. |
| `method protected void resolveOperationNature( payload )` | Lookup em `nit-loog-natur-oper`, assign `nat-operacao` (estadual/interestadual) + IBGE destino. |
| `method protected void buildEntryItem( payload )` | Cria `tt-rat-docum` (rateio) + `tt-item-doc-est` com dados da NF de referência. |
| `method protected void buildExitItem( payload )` | Cria `tt-item-doc-est` com item fixo `'19077'`. |
| `method protected void buildPayableDuplicate()` | Cria `tt-dupli-apagar` com vencimento por `cond-pagto.prazos[1]`. |
| `method public override JsonObject execute( action, operation, context, output referenceCode )` | Chama `super:execute()`, e se `action = ActionEnum:CRIADO`, executa `loadActualFreight` + `createActualFreight`. |
| `method protected void loadActualFreight( payload )` | Itera o array `notaFiscalTransportada` do payload, criando um `tt-frete-realizado` por NF com `serie`, `numero`, `valorFrete`, `tipoFrete`, `observacaoFrete`. |
| `method protected void createActualFreight()` | Persiste todos os `tt-frete-realizado` na tabela `nit-frete-real` via `buffer-copy`. |

**Observações:**
- Código de item fixo `'19077'` em `buildExitItem` — hardcoded, específico ao contexto Loog.ai (mantido por decisão do usuário 2026-07-27).
- `tt-docum-est.serie-docto` é atribuído de `tt-docum-est.serie` em `buildPayableDuplicate` — possível erro de campo (`.serie` vs `.serie-docto`) — **preservado da versão anterior**, não corrigido nesta refatoração.
- Erros de validação usam `undo, throw new ThlError(...)` direto — convenção dos demais Services inbound.
- Convenção de nomenclatura (2026-07-27): métodos e variáveis em inglês camelCase; temp-tables do produto TOTVS mantêm nome original com hífens.

---

## LoogAiEmbarqueMessage

**Caminho:** `thl-extensions\integration\loogai\messaging\inbound\message\LoogAiEmbarqueMessage.cls`

**Namespace ABL:** `thl-extensions.integration.loogai.messaging.inbound.message.LoogAiEmbarqueMessage`

**Responsabilidade:** Especialização de `InboundMessage` para embarques Loog.ai. Sobrescreve `createService()` para injetar `LoogAiEmbarqueService`. Mesma estrutura de `LoogAiDocumentoMessage`.

**Padrão de projeto:** Template Method (subclasse de `InboundMessage`) — extensão via Factory Method (`createService`).

**INHERITS:** `thl-lib.integration.messaging.inbound.core.InboundMessage`

**Dependências diretas THL:** `InboundMessage`, `LoogAiEmbarqueService`.

**Campos obrigatórios (POST):** `codigoEstabelecimento` (recebe o **CNPJ**), `viagem`, `entregas`.

**Campos obrigatórios (DELETE):** `codigoEmbarque`, `viagem`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method protected override Service createService()` | Retorna `new LoogAiEmbarqueService()`. |
| `method protected override character getExternalReferenceField()` | Retorna `'viagem'`. |
| `method protected override character getRequiredFields()` | POST: `codigoEstabelecimento,viagem,entregas`. PATCH: `codigoEmbarque`. DELETE: `codigoEmbarque,viagem`. |

**Verbos:** POST e DELETE usam os defaults de `InboundMessage` (`executeService( CRIADO / DELETADO )`) — a mensagem **não** sobrescreve mais `methodPost`/`methodDelete`. Até 2026-07-31 o `methodPost` enriquecia o payload com defaults; isso migrou para os hooks `resolve*` de `LoogAiEmbarqueService`.

---

## LoogAiEmbarqueService

**Caminho:** `thl-extensions\erp\loogai\service\LoogAiEmbarqueService.cls`

**Namespace ABL:** `thl-extensions.erp.loogai.service.LoogAiEmbarqueService`

**Responsabilidade (sincronizado 2026-07-31):** Especialização de `EmbarqueService` para a Loog.ai. **Concentra todas as particularidades do contrato Loog.ai** — os campos que o integrador não envia no payload são resolvidos aqui, não injetados pela Message.

**Padrão de projeto:** Service (subclasse de `EmbarqueService`, especializa hooks protected).

**INHERITS:** `thl-lib.erp.service.EmbarqueService`

**Dependências diretas THL:** `EmbarqueService` (herança), `ThlError`.

**Métodos protected (10 overrides):**

| Assinatura | Descrição |
|---|---|
| `method protected override void resolveEstablishment()` | Localiza `estabelec` por `cgc = inContext:codigoEstabelecimento` (a Loog.ai manda o **CNPJ** no campo `codigoEstabelecimento`). Lança `ThlError` se não encontrar. |
| `method protected override character resolveIntegrationUser()` | Retorna `'loogai'` fixo — identifica no ERP que o embarque veio da Loog.ai. |
| `method protected override date resolveShipmentDate()` | Retorna `today` — o contrato Loog.ai não envia `dataEmbarque`. |
| `method protected override integer resolveSequence()` | Retorna `1` — a Loog.ai trata uma viagem como embarque único. |
| `method protected override date resolveDeliveryDate( input delivery as JsonObject )` | Retorna `today` — o contrato Loog.ai não envia `dataEntrega` por item. |
| `method protected override JsonObject buildResponse( input action as ActionEnum, input referenceCode as character )` | Resposta própria: `{ success: true, code: 200, message: 'Embarque gerado com sucesso.', codigoEmbarque: referenceCode }` (em vez do `ServiceResponse` padrão). |
| `method protected override void prepareWarehouseData()` | Chamado pela base a cada entrega do `create()` (com `eqapi300` aberto). Monta a `tt-deposito` (private desta classe) e envia ao `eqapi300`: o depósito de `param-dep-exc` do estabelecimento + tipo de operação do pedido (`substring( b-ped-venda.char-1, 162, 5 )`); sem parâmetro, todos os depósitos de acabado não exclusivos de outra operação. Veio da base em 2026-09-30. |
| `method protected override void create()` | `super:create()` e depois `saveShipmentExtension( codigoEmbarque )` (código gerado que a base devolve em `inContext`). |
| `method protected override void update()` | `super:update()` (PATCH de transporte) e depois `saveShipmentExtension( codigoEmbarque )`. |
| `method protected override void validateTransportContext()` | Aceita PATCH com campo de transporte (`TRANSPORT_FIELDS`) **ou** só `valorFrete`/`telefoneMotorista`. |

**Método private `saveShipmentExtension( input shipmentCode as decimal )`:** grava `ext-embarque` (cria se não existir) — `valorFrete` → `valor-frete`, `telefoneMotorista` → `telefone-motorista`. Os dois campos são **opcionais**: sem nenhum deles nada é gravado; campo ausente mantém o valor atual (`JsonSetter`). `ext-embarque` é tabela do banco do cliente, por isso fica só na extensão e não em `thl-lib`.

**Campos de transporte não enviados pela Loog.ai:** `codigoTipo`, `codigoRota`, `nomeTransportadora`, `placa`. Nenhum override é necessário — o `prepareShipmentData` da base os lê via `JsonSetter`, que deixa em branco o que não vem no payload.

**Observações:**
- Segue o mesmo padrão de `LoogAiDocumentoService` — herda do Service base e sobrescreve apenas hooks com lógica Loog.ai-specific.
- Usuário `'loogai'` é hardcode intencional: serve para identificar que o embarque foi gerado pela integração Loog.ai. Não usa env var nem `c-seg-usuar` (variável global TOTVS incompatível com classes OO).
- **Refatorado em 2026-07-31:** os defaults viviam em `LoogAiEmbarqueMessage:methodPost`, que enriquecia o payload antes de chamar o Service. Efeito colateral: o Service só funcionava se chamado pela Message — um `.p` interno que o instanciasse direto quebraria em `GetDate('dataEmbarque')`. Com os hooks, o Service é autossuficiente.
- Convenção de nomenclatura: métodos e variáveis em inglês camelCase.

---

## StatusDocumento

**Caminho:** `thl-extensions\integration\loogai\messaging\outbound\message\StatusDocumento.cls`

**Namespace ABL:** `thl-extensions.integration.loogai.messaging.outbound.message.StatusDocumento`

**Responsabilidade:** Outbound que envia à Loog.ai o status de um documento a partir de um texto em `additionalData.content` no formato `"<chaveAcesso>#<TipoMovto>"`. Não lê tabela nenhuma.

**INHERITS:** `OutboundMessage`

| Assinatura | Descrição |
|---|---|
| `method public override void appendPayloadObject( objectContext as OutboundObjectContext )` | `{ chaveAcesso: entry(1, content, '#'), TipoMovto: entry(2, content, '#') }`. |
| `method public override character onLoadData( register as recid )` | Retorna `''` — não há registro de negócio. |

**Observações:**
- Nome fora do padrão (`*Message`) e cabeçalho copiado (`File : centroCusto`, 2021). Declara `define private buffer b-docum-est`, mas não usa.
- Sem referência estática no código — resolvida pelo banco (`thl-objeto.classe-objeto`). Uso a confirmar (diagnóstico, decisão D5).
- Chamada típica: `addObject( new OutboundObjectContext( ?, '', '<chave>#<tipo>' ) )`.

## 2026-10-04 — `LoogAiDocumentoService` sem `execute` (não compilado)

`Service:execute` foi removido da base ([ADR](../adr/inbound-message-processor-service.md)). A sobrescrita de `execute` deste Service virou `method public override void create()`: `super:create()`, depois `loadActualFreight( inContext )` e `createActualFreight()`. O efeito pretendido é o mesmo (frete real só na criação), mas agora roda **antes** de `loadReferenceCode()`/`buildResponse()` — conferir no teste de POST do documento. A linha da tabela acima que descreve `execute` é histórico.

## 2026-10-05 — Message de entrada retirada (não compilado)

`LoogAiDocumentoMessage` e `LoogAiEmbarqueMessage` viraram `.cls.old` (e `DocumentoMessage`, de `thl-lib`, também): Message e Processor padrão com `LoogAiDocumentoService` e `LoogAiEmbarqueService`. Contrato na extensão REST: documento com os 12 campos obrigatórios; embarque com os campos por ação (criar: `codigoEstabelecimento`, `viagem`, `entregas`; alterar: `codigoEmbarque`; eliminar: `codigoEmbarque`, `viagem`) e chave externa `viagem`. As Messages de **saída** não mudaram. Sistema `loogai`: 5 classes. Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md). As seções acima que descrevem a Message de entrada são histórico.

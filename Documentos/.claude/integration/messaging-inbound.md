---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, mensageria, inbound]
updated: 2026-10-13
---

# Pacote: integration/messaging/inbound

> ⚠️ **2026-10-04 — Message → Processor → Service.** `InboundMessage` é concreta, `createService()` é opcional (devolve `?`) e a chamada passa pelo `Processor`; o carregador da entrada é o `InboundConfigLoader`. Ver a seção final desta nota e [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

> **Reescrito em 2026-09-24 a partir do código** (`Fontes\thl-lib\integration\messaging\inbound\**` + `Fontes\thl\integration\api\v1\resourcen.p`). A versão anterior era internamente contraditória: seções por classe com `IService`, `executeAndRegister` e `methodPost( context )`, e mensagens que não existem mais (`NotaFiscalPorEmbarqueMessage`). `LpcoMessage` e `FreteMessage` saíram deste pacote → `extensions/automatizador.md` e `extensions/dvv.md`.

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| InboundMessage (abstract) | Base das mensagens de entrada: despacha por verbo HTTP, valida payload e delega ao `Service` | Template Method + Factory Method | Message, InboundObjectContext, Service, ActionEnum, MethodTypeEnum, PaginationHelper, StringUtil | todas as mensagens inbound |
| InboundObjectContext | Contexto da requisição (payload, query/path params, operação, rota) | Value object | — | resourcen.p, InboundMessage |
| InboundRouteResolver | Converte os path params em aplicação, objeto, operação e rota (via `thl-objeto-rota`) | — | ThlError | resourcen.p |
| InboundMessageService | Orquestra o recebimento: registra a mensagem, processa online ou agenda, grava sucesso/erro | Service/Facade | MessageConfigLoader, MessageFactory, InboundSchedulingService | resourcen.p, thl0220z.p (RPW) |
| InboundSchedulingService | Agenda a mensagem para o RPW `thl0220z.p` | Service | Message, MessageConfig | InboundMessageService |
| 11 mensagens em `inbound\message\` | Contrato de cada objeto (ver tabela abaixo) | Template Method | InboundMessage + Service de `erp` | InboundMessageService (via `thl-objeto.classe-objeto`) |

✅ **Grafia de pacote corrigida em 2026-09-24:** todas as classes do pacote declaram `…messaging.inbound…` em minúsculas, igual à pasta (ver `convencoes.md`).

---

## Fluxo REST (online)

```text
resourcen.p (piPrincipal — rotas /*/* e /*/*/*, verbos POST/PATCH/PUT/GET/DELETE)
  ├─ InboundObjectContext: SetPayload / SetQueryParameters / SetPathParameters / setPayloadText
  ├─ InboundRouteResolver( pathParams ) → application, objectCode, operation, routePath
  ├─ method = MethodTypeEnum:GetEnum( request.method )
  └─ new InboundMessageService( application, object, method, operation ):receive( context )
        ├─ accept(): createMessage + grava conteúdo de entrada (DirectionEnum:INBOUND)
        ├─ forma-execucao = SCHEDULE → InboundSchedulingService:schedule(...)  (RPW thl0220z.p)
        └─ processOnline():
             InboundMessage:processInbound( context ) → dispatchInbound()
               POST          → validate(payload) → methodPost()   → executeService( CRIADO )
               PATCH / PUT   → validate(payload) → methodPatch()  → executeService( ATUALIZADO )
               DELETE        → validate(payload) → methodDelete() → executeService( DELETADO )
               GET           → methodGet()   (default: erro "Metodo GET nao implementado")
             executeService( action ):
               payload = createService():execute( action, context:operation, context:payload, referenceCode )
               externalReferenceCode = loadExternalReference( context:payload ); appendItem()
        finalize(): payload default {200, "Mensagem processada com sucesso."} se vazio → saveContent → saveInboundSuccess
     catch → saveInboundError( routePath, erro ) e relança
  resourcen.p: erro → RowErrors → JsonAPIResponseBuilder:asError; sucesso → ok( JsonArray | JsonObject )
```

**Resolução de rota (`InboundRouteResolver`):** com 1 path param, ele é a `routePath`; com mais de um, o **último é a operação** e os anteriores (unidos por `/`) formam a `routePath`. Procura **`thl-objeto-rota`** (substituiu `thl-inbound-rota` em 2026-10-06) com `rota-publica = routePath` e `ind-ativo`. Não achando exato, `findRouteByPrefix()` tenta os primeiros segmentos do mais longo para o mais curto e o resto vira operação; sem rota, `objeto = routePath sem "/"` e `aplicacao = 'TOTVS'`. Com `thl-objeto-rota.inicio-operacao >= 2`, `composeOperation()` monta a operação do segmento informado até o último. Fluxo completo em [fluxo-entrada.md](../fluxos/fluxo-entrada.md).

---

## InboundMessage (abstract)

**Caminho:** `thl-lib\integration\messaging\inbound\core\InboundMessage.cls` · **Namespace:** `thl-lib.integration.messaging.inbound.core.InboundMessage` · **INHERITS:** `Message`

**Propriedade:** `context` (`InboundObjectContext`, protected get).

| Assinatura | Descrição |
|---|---|
| `method public void processInbound( context as InboundObjectContext )` | Guarda o contexto e chama `dispatchInbound()`. |
| `method public void dispatchInbound()` | `case methodType` (ver fluxo). Verbo não suportado → erro. |
| `method protected void executeService( action as ActionEnum )` | Chama `createService():execute(...)`, carrega a referência externa e `appendItem()`. |
| `method protected void methodPost()` / `methodPatch()` / `methodDelete()` | Defaults → `executeService( CRIADO / ATUALIZADO / DELETADO )`. |
| `method protected void methodGet()` | Default lança erro; mensagens de consulta sobrescrevem. |
| `method protected void validate( payload )` | `validatePayload` (payload obrigatório) + `validateRequiredFields( payload, getRequiredFields() )` — acumula todos os campos faltantes e lança de uma vez (erro 17006). |
| `method protected character getRequiredFields()` | Default `''` (sem validação). |
| `method protected character getExternalReferenceField()` | Default `'externalID'`; `''` desativa a referência externa. |
| `method protected character loadExternalReference( context as JsonObject )` | Lê o campo de `getExternalReferenceField()` do payload. |
| `method protected PaginationHelper createPagination( defaultPageSize as integer )` | Usa os query params `pageSize` e `page` (default 1). |
| `method public void saveInboundSuccess( routePath )` / `saveInboundError( routePath, errorObject )` | Resultado + histórico no repositório; no erro, grava o JSON do erro como conteúdo de saída. |
| `method public void restoreForScheduledProcessing( messageCode )` | Recarrega mensagem e conteúdo para o processamento via RPW. |
| `method protected abstract Service createService()` | **Factory Method obrigatório.** Mensagens só de consulta devolvem `?`. |

## InboundObjectContext

**Namespace:** `thl-lib.integration.messaging.inbound.core.InboundObjectContext`

Propriedades públicas (get): `payload` (JsonObject), `queryParameters` (JsonObject), `pathParameters` (JsonArray), `payloadText` (longchar), `operation`, `routePath`. Setters: `SetPayload`, `SetQueryParameters`, `SetPathParameters`, `SetOperation`, `SetRoutePath`, `setPayloadText()`. Helpers: `hasPathParameters()`, `hasPayload()`, `getQueryParamInt( name, default )`, `getQueryParam( name, default )`.

## InboundMessageService

**Namespace:** `thl-lib.integration.messaging.inbound.service.InboundMessageService`

| Assinatura | Descrição |
|---|---|
| `constructor public InboundMessageService( applicationName, objectName as character, methodType as integer, operation as character )` | Carrega `MessageConfig` (`MessageConfigLoader:load`) e instancia a mensagem via `MessageFactory`; exige que seja `InboundMessage`. |
| `constructor public InboundMessageService( configuration_ as MessageConfig, … )` | Variante com a configuração já carregada. |
| `method public JsonConstruct receive( context as InboundObjectContext )` | Fluxo online ou agendamento (ver acima). |
| `method public JsonConstruct processScheduled( messageCode as character )` | Usado pelo RPW: restaura a mensagem, monta o contexto com o payload persistido e processa; rota registrada como `'RPW'`. |

## Limitação do contexto agendado

**Conferido por leitura em 02/10/2026; não reproduzido no ERP/PASOE.** `InboundMessageService:processScheduled()` restaura o payload e cria um novo `InboundObjectContext` com `SetPayload` e `SetOperation`. Não restaura `routePath`, `queryParameters` ou `pathParameters`; `restoreForScheduledProcessing()` recarrega mensagem e conteúdo, sem reconstruir esses dados.

`ObjetoMessage`, `NotaFiscalMessage` e outras Messages de agregado selecionam o Service por `context:routePath`. **Risco condicionado ao cadastro:** se configuradas como SCHEDULE, essas Messages chegam ao runner sem a rota necessária à seleção. Queries e paths também não devem ser presumidos disponíveis no processamento agendado.

Antes de habilitar esse cenário, definir como persistir/restaurar o contexto e validar cada rota pelo RPW. Esta nota registra uma limitação; não implementa correção nem comprova falha em ambiente implantado.

Evidências: [InboundMessageService.cls](../../../Fontes/thl-lib/integration/messaging/inbound/service/InboundMessageService.cls), [InboundMessage.cls](../../../Fontes/thl-lib/integration/messaging/inbound/core/InboundMessage.cls), [ObjetoMessage.cls](../../../Fontes/thl-extensions/integration/thl/messaging/inbound/message/ObjetoMessage.cls) e [NotaFiscalMessage.cls](../../../Fontes/thl-lib/integration/messaging/inbound/message/NotaFiscalMessage.cls).

## InboundSchedulingService

`method public JsonObject schedule( message_ as Message, … )` — agenda a execução com `run thl/thl0220z.p` e devolve `{ messageCode, pedidoExecucao, status }`.

---

## Mensagens (`inbound\message\`)

Todas herdam `InboundMessage`, têm o construtor padrão de 7 parâmetros e são instanciadas pelo banco (`thl-objeto.classe-objeto`).

| Mensagem | `createService()` | Verbos | Campos obrigatórios / query params | Observações |
|---|---|---|---|---|
| AuditoriaMessage | `?` | GET | `bancoIni/Fin`, `tabelaIni/Fin`, `dtCriacaoIni/Fin` (`yyyy-MM-ddTHH:mm`; default agora−24h … agora), `usuarioIni/Fin`, `pageSize`, `page` | chama `AuditoriaService:get` direto |
| CentroCustoMessage | `CentroCustoService` | GET | `empresa`, `plano`, `custo` | — |
| DocumentoMessage | `DocumentoService` | POST (default) | — | ponto de extensão: `LoogAiDocumentoMessage` |
| EmailMessage | `?` | GET | `dtEnvioIni/Fin` (`yyyy-MM-ddTHH:mm`; default agora−24h … agora), `idIni/Fin`, `codProgDtsulIni/Fin`, paginação | chama `EmailService:get` direto |
| EmbarqueMessage | `EmbarqueService` | POST, DELETE | POST: `codigoEstabelecimento,codigoUsuario,dataEmbarque,sequencia,entregas`; DELETE: `codigoEmbarque` | ponto de extensão: `LoogAiEmbarqueMessage` |
| EmitenteMessage | `?` | GET | operação `localentrega` → `LocalEntregaService:get( codigo, nome, entrega )`; senão `EmitenteService:get( codigo, nome )` | instancia os serviços direto |
| ItemMessage | operação `Saldo` → `SaldoService`; senão `ItemService` | GET | `Saldo`: `estabel`, `codigo`; item: `codigo` | — |
| MensageriaMessage | `?` | GET | operação `conteudo` → `MensageriaConteudoService:get( id, tipo )`; senão `MensageriaService:get(...)` com `codigo/objeto/operacao/aplicacao Ini/Fin`, `dtCriacao/dtIntegracao Ini/Fin` (`yyyy-MM-ddTHH:mm`; default agora−24h … agora), paginação | — |
| NotaFiscalMessage | rota `notafiscal` → `NotaFiscalService`; `notafiscal/embarque` → `NotaFiscalPorEmbarqueService`; outra → erro | POST (default) | a operação (último path param) escolhe o passo no Service: `geracao`, `geracao-xml`, `autorizacao-sefaz`, `impressao`, `notificacao`, `processamento` (só NF direta) | referência externa `codigoEstabelecimento#serie#numeroDocumento`; ponto de extensão: `NinahubNotaFiscalMessage` |
| RequisicaoMessage | operação `item` → `ItemRequisicaoService`; senão `RequisicaoService` | POST, DELETE | DELETE: `nr-requisicao` | referência externa desativada (`''`) |
| TransporteMessage | `?` | GET | `codigo` (cod-transp) ou `nome` (nome-abrev) | chama `TransporteService:get` direto; `referenceCode` = cod-transp |
| UsuarioMessage | `UsuarioService` | POST (default) | `codigoUsuario` | — |

**Padrão para uma mensagem nova** (arquivo em **ISO-8859-1**, pacote em minúsculas): implementar `createService()` e, se necessário, `getRequiredFields()`/`getExternalReferenceField()`; sobrescrever `methodGet()` só para consultas. Modelos: `UsuarioMessage` (escrita simples), `ItemMessage` (consulta por operação), `LpcoMessage` em `extensions/automatizador.md` (CRUD + GET paginado).

---

## Observações

- ⚠️ `AuditoriaMessage`, `EmailMessage` e `MensageriaMessage` ficam em `thl-extensions.integration.thl.messaging.inbound.message` (conferido em disco em 2026-10-02), não em `thl-lib`; em `thl-lib` restam 9 mensagens. Módulo de auditoria: [../logging/auditoria.md](../logging/auditoria.md).
- **Uma Message para vários Services:** `createService()` pode escolher o Service por `context:routePath` (várias rotas de `thl-objeto-rota` apontando para o mesmo objeto — `NotaFiscalMessage` e as cinco Messages de agregado do sistema [thl](../extensions/thl.md)) ou por `context:operation` (`MensageriaMessage`). ⚠️ Pela operação só cabe **um verbo por operação**: o `MessageConfigLoader` procura `thl-objeto-parametro` por método e operação, e a chave primária não inclui o método.
- `InboundObjectContext:getQueryParamDateTime( paramName, defaultValue as datetime-tz ): datetime` (2026-10-03, não compilado): lê a data e hora da query string no formato `yyyy-MM-ddTHH:mm` (`StringUtil:parseDateTime`); sem o parâmetro, devolve o padrão informado por quem chama (`now`, `add-interval( now, -24, 'hours' )`). Usado pelas rotas de métricas, ao lado de `getQueryParam` e `getQueryParamInt`.
- **Referências da mensagem** (2026-10-03, não compilado): a Message só pega as referências — a interna vem do Service (`execute`, parâmetro de saída; no GET, o `referenceCode` de cada item) e a externa vem do payload (`getExternalReferenceField` / `loadExternalReference`). `executeService` passou a ler a referência externa **antes** de chamar o Service; se o Service falhar, `saveInboundError` grava o item da mensagem só com a referência externa (uma vez, controlado por `referenceRegistered`). Antes, mensagem com erro ficava sem item. Objeto sem referência externa (ex.: cadastros do THL, que devolvem `''`) continua sem item no erro.
- `getRequiredFields()` fica para o que é contrato do sistema externo. Validar a chave da entidade é do Service (ver [extensions/thl.md](../extensions/thl.md)).
- ⚠️ `saveContentByType` da entrada roda em `InboundMessageService:accept`, antes de `processInbound` preencher o `context`: quem sobrescreve (máscara de segredo) não pode usar `context` nem um `createService()` que dependa dele.
- Mensagens só de consulta (`Auditoria`, `Email`, `Emitente`, `Mensageria`, `Transporte`) devolvem `?` em `createService()`: um POST/PATCH/DELETE nelas falha no `execute` (objeto inválido). Os verbos aceitos dependem do cadastro em `thl-objeto-parametro`.
- PUT é tratado como PATCH em `dispatchInbound`.
- A validação de campos obrigatórios não roda no GET.

## Message → Processor → Service (2026-10-04, não compilado)

```text
resourcen.p → InboundRouteResolver (rota; 2º segmento = operação)
  → InboundMessageService
      InboundConfigLoader:load( aplicação, objeto, método, operação )   valida message, processor e service
      MessageFactory → dynamic-new thl-objeto.classe-objeto             padrão: InboundMessage
      inboundMessage:setProcessing( processorClass, serviceClass )
  → InboundMessage:dispatchInbound → methodPost/Patch/Delete/Get
      createProcessor()  → dynamic-new thl-objeto.classe-processor       padrão: thl-lib.integration.messaging.inbound.core.Processor
      Processor:execute( action, context:operation, payload | query, output referenceCode )
          resolveService( operation ) → Service (do cadastro ou do agregado)
```

- `InboundMessage` não é mais abstrata; `createService()` devolve `?` por padrão. As 9 Messages de `thl-lib` e as das outras extensões continuam sobrescrevendo — a instância vai para o Processor por `setService` e tem prioridade sobre o cadastro.
- Objeto de entrada com classe de message, processor ou service em branco é recusado no carregador: "Objeto &1/&2 sem classe obrigatoria no cadastro (thl0021): &3."
- Um filho de agregado é a **operação** da URL; as quatro linhas de parâmetro por método do objeto atendem todas as operações (regra em [messaging-core.md](messaging-core.md)).
- ⚠️ A confirmar no teste: mensagem inbound **agendada** de uma operação sem linha própria em `thl-objeto-parametro` (o RPW reprocessa pela operação gravada).

**Padrão para um recebimento novo:** escrever o Service (`public override` nos verbos) e cadastrar o objeto com `classe-service`; Message e Processor ficam nos valores iniciais. Processor próprio só para agregado; Message própria só para comportamento de protocolo. Decisão em [adr/inbound-message-processor-service.md](../adr/inbound-message-processor-service.md).

## Mensagens de `thl-lib` depois da segunda rodada (2026-10-04, não compilado)

Restam **5** em `inbound\message\`: `DocumentoMessage`, `EmbarqueMessage`, `NotaFiscalMessage`, `RequisicaoMessage` (sem `createService()`; usa `RequisicaoProcessor`) e `UsuarioMessage`. `CentroCustoMessage`, `EmitenteMessage`, `ItemMessage` e `TransporteMessage` viraram `.cls.old`: os objetos passam a usar a Message padrão, com `ItemProcessor`/`EmitenteProcessor` onde há operação. A tabela "Mensagens" acima descreve o estado anterior. `thl-lib.integration` passa a ter 45 classes.

## Contrato pelo cadastro e fim das Messages específicas (2026-10-05, não compilado)

- `InboundConfigLoader`: a linha da operação é procurada pela **ação** do verbo recebido — (1) operação da URL + ação; (2) operação em branco + ação; (3) operação com o nome do verbo + ação; (4) primeira linha da ação. Sem resultado, repete pelo verbo nas linhas com ação zero (cadastro sem acerto). As classes são as da operação ou, em branco, as do objeto.
- `InboundMessageService` entrega o contrato à mensagem: `setContract( requiredFields, externalReferenceFields )`.
- `InboundMessage:getRequiredFields()` padrão devolve os campos do cadastro; `loadExternalReference()` usa a chave externa do cadastro quando informada (`[]` desliga; campos unidos por `#`; chave composta só vale inteira) e, em branco, o gancho `getExternalReferenceField()` (`externalID`).
- **Restou uma Message em `thl-lib`:** `NotaFiscalMessage` (escolhe o Service pela rota). `DocumentoMessage`, `EmbarqueMessage`, `RequisicaoMessage` e `UsuarioMessage` viraram `.cls.old`. `thl-lib.integration` tem 41 classes.
- Padrão para um recebimento novo: Service + objeto (classe de service) + operações (ação, e na aba REST os campos obrigatórios e a chave externa). Nenhuma classe além do Service.

Decisão em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md).

## Nota fiscal em dois objetos (2026-10-05, não compilado)

Decisão do responsável: nota fiscal **direta** e **por embarque** são objetos diferentes (características próprias), cada um com o seu Service — `NotaFiscalService` e `NotaFiscalPorEmbarqueService` —, Message e Processor padrão. A `NotaFiscalMessage`, que escolhia o Service pela rota, virou `.cls.old`; a chave externa (`codigoEstabelecimento`, `serie`, `numeroNotaFiscal`) foi para a extensão REST das operações. Sem rota cadastrada o roteador já separa os dois (`notafiscal` e `notafiscalembarque`). O `acerto-thl-objeto-classes.p` atribui o Service pela rota que atende cada objeto e, se as duas rotas apontarem para o mesmo, cria o objeto do embarque (`<objeto>Embarque`, com cópia de operações, extensões e usuários) e reaponta a rota. `thl-lib` não tem mais Messages de entrada (`inbound\\message\\` só com `.cls.old`); `thl-lib.integration` tem 40 classes.

## Operação composta pela rota (2026-10-06, não compilado) — substitui "Nota fiscal em dois objetos"

`InboundRouteResolver`: rota cadastrada com `inicio-operacao` ≥ 2 entrega a operação do segmento informado até o último, unida por `/` (`composeOperation`); zero ou rota sem cadastro mantém o comportamento de sempre (último segmento). O `resourcen.p` não mudou. A nota fiscal voltou a ser **um objeto**, com `NotaFiscalProcessor` (`embarque/<etapa>` → `NotaFiscalPorEmbarqueService`, que recebe só a etapa). Detalhe em [adr/operacao-acao-extensao-rest.md](../adr/operacao-acao-extensao-rest.md) §8.

## Pacote dos Processors (2026-10-06)

Os Processors são orquestração da **entrada** e ficam junto dela: `thl-lib.integration.messaging.inbound.process` (`Fontes	hl-lib\integration\messaging\inbound\process\`) e, nas extensões, `thl-extensions.integration.<sistema>.messaging.inbound.process`. Os Services continuam em `erp.service`. Pastas de `…\messaging\inbound\` em `thl-lib`: `core`, `message` (só `.cls.old`), `process`, `repository`, `route`, `service`.

## Processor base em `core` (2026-10-07)

A classe-base `Processor` foi para `thl-lib.integration.messaging.inbound.core` (`Fontes\thl-lib\integration\messaging\inbound\core\Processor.cls`), ao lado de `InboundMessage` e `InboundMessageConfig` — o mesmo padrão das Messages: base em `core`, específicas em pasta própria. Os Processors específicos continuam em `…messaging.inbound.process` (em `thl-lib`: item, emitente, requisição, nota fiscal; nas extensões: `dvv` e `thl`). Pastas de `inbound` em `thl-lib`: `core` (Message, Processor, configuração, contexto), `process` (4 específicos), `repository`, `route`, `service`, `message` (só `.cls.old`).

## `Processor:invokeWrite` (2026-10-08, não compilado)

O `execute` do Processor base passou a chamar `invokeWrite( action, service, operation )` (protegido) na escrita; o padrão chama `create`/`update`/`delete`. Processor de objeto com várias operações na mesma ação sobrescreve e chama o método do Service de cada operação — `NotaFiscalProcessor` (etapas da nota e o encadeamento `processamento`).

## `Processor:invokeQuery` e `MetricsProcessor` (2026-10-08, não compilado)

O `execute` do Processor base chama `invokeQuery( service, operation )` na consulta (padrão: `consult()`). `MetricsProcessor` (`thl-extensions.integration.thl.messaging.inbound.process`, confirmado no código) sobrescreve e, na operação `metricas`, chama `consultMetrics()` de `thl-extensions.erp.thl.interfaces.IMetricsService`. ⚠️ **Divergência (2026-10-13):** os cadastros (`Database/Data/OpenEdge/entrada/thl010.d` e `thl011.d`, `Database/Data/OpenEdge/Cadastro/thl011.d`, `Utils/scripts/acerto-thl-objeto-classes.p`, `acerto-thl-operacao-service.p`) ainda gravam `thl-lib.integration.messaging.inbound.process.MetricsProcessor`, classe que **não existe**: o `MetricsProcessor` está em `Fontes/thl-extensions/integration/thl/messaging/inbound/process/`. Com o nome atual no banco, `dynamic-new` falha. Decidir: mover a classe para `thl-lib` ou atualizar os cadastros e scripts (`> [!todo]`). Usado pelos objetos Auditoria e Email e herdado pelo `MensageriaProcessor`.

## Processors de agregado retirados (2026-10-08, não compilado)

`ItemProcessor`, `EmitenteProcessor` e `RequisicaoProcessor` viraram `.cls.old`: `Saldo`, `localentrega` e `item` são linhas de operação com o Service em `thl-objeto-parametro.classe-service`. Em `thl-lib...inbound.process` ficam `NotaFiscalProcessor` e `MetricsProcessor`. O gancho `resolveService( operation )` do Processor base continua existindo.

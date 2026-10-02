# Pacote: integration/messaging/inbound

> **Reescrito em 2026-09-24 a partir do código** (`Fontes\thl-lib\integration\messaging\inbound\**` + `Fontes\thl\integration\api\v1\resourcen.p`). A versão anterior era internamente contraditória: seções por classe com `IService`, `executeAndRegister` e `methodPost( context )`, e mensagens que não existem mais (`NotaFiscalPorEmbarqueMessage`). `LpcoMessage` e `FreteMessage` saíram deste pacote → `extensions/automatizador.md` e `extensions/dvv.md`.

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| InboundMessage (abstract) | Base das mensagens de entrada: despacha por verbo HTTP, valida payload e delega ao `Service` | Template Method + Factory Method | Message, InboundObjectContext, Service, ActionEnum, MethodTypeEnum, PaginationHelper, StringUtil | todas as mensagens inbound |
| InboundObjectContext | Contexto da requisição (payload, query/path params, operação, rota) | Value object | — | resourcen.p, InboundMessage |
| InboundRouteResolver | Converte os path params em aplicação, objeto, operação e rota (via `thl-inbound-rota`) | — | ThlError | resourcen.p |
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

**Resolução de rota (`InboundRouteResolver`):** com 1 path param, ele é a `routePath`; com mais de um, o **último é a operação** e os anteriores (unidos por `/`) formam a `routePath`. Procura `thl-inbound-rota` com `rota-publica = routePath` e `ind-ativo`; se achar, usa `objeto`/`aplicacao` da rota; senão, `objeto = routePath sem "/"` e `aplicacao = 'TOTVS'`.

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
| AuditoriaMessage | `?` | GET | `bancoIni/Fin`, `tabelaIni/Fin`, `dtCriacaoIni/Fin` (default hoje−30 … hoje+1), `usuarioIni/Fin`, `pageSize`, `page` | chama `AuditoriaService:get` direto |
| CentroCustoMessage | `CentroCustoService` | GET | `empresa`, `plano`, `custo` | — |
| DocumentoMessage | `DocumentoService` | POST (default) | — | ponto de extensão: `LoogAiDocumentoMessage` |
| EmailMessage | `?` | GET | `dtEnvioIni/Fin` (hoje−30 … hoje+1), `idIni/Fin`, `codProgDtsulIni/Fin`, paginação | chama `EmailService:get` direto |
| EmbarqueMessage | `EmbarqueService` | POST, DELETE | POST: `codigoEstabelecimento,codigoUsuario,dataEmbarque,sequencia,entregas`; DELETE: `codigoEmbarque` | ponto de extensão: `LoogAiEmbarqueMessage` |
| EmitenteMessage | `?` | GET | operação `localentrega` → `LocalEntregaService:get( codigo, nome, entrega )`; senão `EmitenteService:get( codigo, nome )` | instancia os serviços direto |
| ItemMessage | operação `Saldo` → `SaldoService`; senão `ItemService` | GET | `Saldo`: `estabel`, `codigo`; item: `codigo` | — |
| MensageriaMessage | `?` | GET | operação `conteudo` → `MensageriaConteudoService:get( id, tipo )`; senão `MensageriaService:get(...)` com `codigo/objeto/operacao/aplicacao Ini/Fin`, `dtCriacao/dtIntegracao Ini/Fin` (hoje−3 … hoje+1), paginação | — |
| NotaFiscalMessage | rota `notafiscal` → `NotaFiscalService`; `notafiscal/embarque` → `NotaFiscalPorEmbarqueService`; outra → erro | POST (default) | a operação (último path param) escolhe o passo no Service: `geracao`, `geracao-xml`, `autorizacao-sefaz`, `impressao`, `notificacao`, `processamento` (só NF direta) | referência externa `codigoEstabelecimento#serie#numeroDocumento`; ponto de extensão: `NinahubNotaFiscalMessage` |
| RequisicaoMessage | operação `item` → `ItemRequisicaoService`; senão `RequisicaoService` | POST, DELETE | DELETE: `nr-requisicao` | referência externa desativada (`''`) |
| TransporteMessage | `?` | GET | `codigo` (cod-transp) ou `nome` (nome-abrev) | chama `TransporteService:get` direto; `referenceCode` = cod-transp |
| UsuarioMessage | `UsuarioService` | POST (default) | `codigoUsuario` | — |

**Padrão para uma mensagem nova** (arquivo em **ISO-8859-1**, pacote em minúsculas): implementar `createService()` e, se necessário, `getRequiredFields()`/`getExternalReferenceField()`; sobrescrever `methodGet()` só para consultas. Modelos: `UsuarioMessage` (escrita simples), `ItemMessage` (consulta por operação), `LpcoMessage` em `extensions/automatizador.md` (CRUD + GET paginado).

---

## Observações

- ⚠️ `AuditoriaMessage`, `EmailMessage` e `MensageriaMessage` ficam em `thl-extensions.integration.thl.messaging.inbound.message` (conferido em disco em 2026-10-02), não em `thl-lib`; em `thl-lib` restam 9 mensagens. Módulo de auditoria: [../logging/auditoria.md](../logging/auditoria.md).
- **Uma Message para vários Services:** `createService()` pode escolher o Service por `context:routePath` (várias rotas de `thl-inbound-rota` apontando para o mesmo objeto — `NotaFiscalMessage` e as cinco Messages de agregado do sistema [thl](../extensions/thl.md)) ou por `context:operation` (`MensageriaMessage`). ⚠️ Pela operação só cabe **um verbo por operação**: o `MessageConfigLoader` procura `thl-objeto-parametro` por método e operação, e a chave primária não inclui o método.
- ⚠️ `saveContentByType` da entrada roda em `InboundMessageService:accept`, antes de `processInbound` preencher o `context`: quem sobrescreve (máscara de segredo) não pode usar `context` nem um `createService()` que dependa dele.
- Mensagens só de consulta (`Auditoria`, `Email`, `Emitente`, `Mensageria`, `Transporte`) devolvem `?` em `createService()`: um POST/PATCH/DELETE nelas falha no `execute` (objeto inválido). Os verbos aceitos dependem do cadastro em `thl-objeto-parametro`.
- PUT é tratado como PATCH em `dispatchInbound`.
- A validação de campos obrigatórios não roda no GET.

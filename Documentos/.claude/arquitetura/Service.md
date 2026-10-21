---
tipo: classe
camada: core
status: vigente
tags: [classe, arquitetura, service]
updated: 2026-10-13
---

# Service

> ⚠️ **2026-10-04 — Message → Processor → Service.** O `execute` saiu do Service e foi para o [Processor](../adr/inbound-message-processor-service.md); os verbos ficaram públicos. O bloco "Contrato para as filhas" abaixo está atualizado na seção final desta nota.

> Classe-base **abstrata** · `thl-lib.erp.core.Service` · `Fontes\thl-lib\erp\core\Service.cls` · volta ao [hub de arquitetura](../arquitetura.md)

## Papel

Contrato da **regra de negócio ERP** executada por uma [InboundMessage](InboundMessage.md) (via `createService()`). Não existe interface `IService`: o contrato é esta classe abstrata. É também a raiz das sub-bases que encapsulam APIs Datasul: [BusinessObject](BusinessObject.md) (BOs com `RowErrors`) e `ApplicationProgrammingInterface` (APIs com tabela de erros).

## Contrato para as filhas

```abl
method public JsonObject execute ( input  action        as ActionEnum,
                                   input  operation     as character ,
                                   input  context       as JsonObject,
                                   output referenceCode as character ).
```

| Membro | Obrigatório? | Uso |
|---|---|---|
| `loadReferenceCode()` → `character` | **abstrato** | Código do registro afetado (vira `referenceCode` da mensagem) |
| `getEntityName()` → `character` | **abstrato** | Nome da entidade para mensagens/log |
| `initialize()` | opcional | Preparação antes da ação |
| `create()` / `update()` / `delete()` | opcional | Uma por `ActionEnum` |
| `buildResponse(action, …)` | opcional | Monta o `JsonObject` devolvido |
| `inContext` / `outContext` | apoio | Entrada e saída da execução |

## Hierarquia

```mermaid
classDiagram
    direction LR
    class Service { <<abstract>> }
    class BusinessObject { <<abstract>> }
    class ApplicationProgrammingInterface { <<abstract>> }
    class EmailService_erp["EmailService (erp)"]
    class LpcoService["LpcoService (automatizador)"]
    class FretePrevistoService["FretePrevistoService (dvv)"]
    class LoogAiEmbarqueService["LoogAiEmbarqueService (loogai)"]
    Service <|-- BusinessObject
    Service <|-- ApplicationProgrammingInterface
    Service <|-- AuditoriaService
    Service <|-- CentroCustoService
    Service <|-- EmailService_erp
    Service <|-- EmitenteService
    Service <|-- ItemService
    Service <|-- LocalEntregaService
    Service <|-- MensageriaConteudoService
    Service <|-- MensageriaService
    Service <|-- SaldoService
    Service <|-- LpcoService
    Service <|-- FretePrevistoService
    ApplicationProgrammingInterface <|-- EmbarqueService
    EmbarqueService <|-- LoogAiEmbarqueService
```

## Filhas

**Sub-bases abstratas (`thl-lib.erp.core`):**

| Classe | Encapsula | Filhas |
|---|---|---|
| [BusinessObject](BusinessObject.md) | BOs Datasul — `throwRowErrorsIfAny(methodName)` | 5 (+ netas) |
| `ApplicationProgrammingInterface` | APIs Datasul — `throwApiErrorsIfAny(methodName)` | `EmbarqueService` → `LoogAiEmbarqueService` ([loogai](../extensions/loogai.md)) |

**Concretas diretas em `thl-lib.erp.service`** (6): `CentroCustoService`, `EmitenteService`, `ItemService`, `LocalEntregaService`, `SaldoService`, `TransporteService`. (`AuditoriaService`, `EmailService`, `MensageriaService` e `MensageriaConteudoService` passaram para `thl-extensions.erp.thl.service` — conferido em disco em 2026-10-02.)

**Concretas diretas em `thl-extensions.erp.<sistema>.service`:** `LpcoService` ([automatizador](../extensions/automatizador.md)), `FretePrevistoService` ([dvv](../extensions/dvv.md)), `AmbienteService`, `ParametroAmbienteService`, `ParametroVariavelService`, `ParametroProgramaService`, `AplicacaoService`, `AuditoriaService`, `EmailService`, `MensageriaService`, `MensageriaConteudoService`, `AuditoriaTabela*Service` (5), `ConexaoRest*Service` (4), `ObjetoService`, `ObjetoParametroService`, `ObjetoUsuarioService`, `ObjetoRotaService`, `EmailParametroService`, `GrupoEmailService`, `GrupoEmailUsuarioService` ([thl](../extensions/thl.md)).

⚠️ `thl-extensions.erp.thl.service.EmailService` (serviço ERP chamado pela `EmailMessage`) não é o mesmo que `thl-lib.communication.email.EmailService` (envio de e-mail) — ver [communication/email.md](../communication/email.md).

## Relacionados

[InboundMessage](InboundMessage.md) · [BusinessObject](BusinessObject.md) · [erp/erp-services.md](../erp/erp-services.md)

## Consulta no contrato (2026-10-03, não compilado)

O Template Method `execute` passou a cobrir os quatro verbos: além de `create()`, `update()` e `delete()`, despacha a ação `Consultado` para `consult()`, sem passar pelo `initialize()`. Detalhe em [erp/erp-services.md](../erp/erp-services.md) e [adr/get-no-execute-do-service.md](../adr/get-no-execute-do-service.md). Aplicado nos 24 Services do sistema [thl](../extensions/thl.md).

## Service sem `execute` (2026-10-04, não compilado)

O Service ficou só com a regra, os dados e o JSON da entidade. A orquestração é do `thl-lib.integration.messaging.inbound.core.Processor` ([ADR](../adr/inbound-message-processor-service.md)).

| Membro (todos **públicos**) | Obrigatório? | Uso |
|---|---|---|
| `prepare( operation, context )` | base | Recebe o payload (`inContext`) e a operação, antes dos verbos de escrita |
| `prepareQuery( operation, context )` | base | Recebe os parâmetros da query e cria `queryParameters`, antes do `consult()` |
| `initialize()` | opcional | Valida a chave (`JsonUtil:requireProperties`) e posiciona o registro |
| `create()` / `update()` / `delete()` | opcional | Padrão lança "Acao nao suportada" |
| `consult()` → `JsonConstruct` | opcional | GET: lê `queryParameters`, devolve `JsonArray` ou `JsonObject` |
| `buildQueryResponse( result )` | base | Array vira `{ items, hasNext: false }` |
| `buildResponse( action, referenceCode )` | opcional | Resposta dos verbos de escrita |
| `loadReferenceCode()` / `getEntityName()` | **abstratos** | Código do registro e nome da entidade |

Filha sobrescreve com `method public override` — uma sobrescrita não pode ser mais restrita que o método da base. As 211 declarações das filhas do repositório foram ajustadas.

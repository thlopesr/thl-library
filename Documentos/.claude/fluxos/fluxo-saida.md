---
tipo: guia
camada: ambos
status: vigente
tags: [fluxo, saida]
updated: 2026-10-13
---

# Fluxo — mensagem de saída (outbound REST)

> Visão de ponta a ponta: da montagem no ERP à chamada HTTP, e o cadastro que governa cada etapa. Referências por classe em [messaging-outbound.md](../integration/messaging-outbound.md), [messaging-core.md](../integration/messaging-core.md) e [connectors](../integration/messaging-core.md).
>
> Verificado por leitura do código em 2026-10-09. Nada executado contra PASOE.

## Cadeia de chamadas

```text
Programa do ERP
  ├─ OutboundMessageService:beginBuild()      cria a MessageStructureStrategy
  │    Single ou Multiple conforme ind-mensagem-simples
  ├─ addObject( recid | OutboundObjectContext )  n vezes
  ├─ finishBuild()                            structureStrategy:finishMessage()
  └─ process() | process( ExecutionMode )
       ONLINE   → MessageExecutionService:executeOnline()
       SCHEDULE → SchedulingService
       BATCH    → return true (nenhuma ação imediata)

MessageExecutionService:executeOnline( message, configuration )
  ├─ ConnectorRequest: connectorType, methodType, content, pathParameters
  ├─ ConnectorConfig( 'APLICACAO.OBJETO', parameterCode, routeParameterCode )
  │    └─ EnvironmentResource( programName )  ← resolve o parâmetro pelo programa
  │         getEnvironmentVariable( parameterCode )      → cod-conexao
  │         getEnvironmentVariable( routeParameterCode ) → cod-path
  ├─ ConnectorService:execute( request )  → RestConnector
  └─ message:saveResponse( response, historyEnabled )
```

## A indireção que resolve o destino

`thl-objeto-parametro.cod-param-ambiente` e `.cod-param-ambiente-destino` **não guardam parâmetro**: são passados como `variableCode` a `EnvironmentResource:getEnvironmentVariable()`. O **parâmetro** vem de `findParameterCodeByProgram('APLICACAO.OBJETO')`, em `thl-ambiente-param-prog`.

```text
thl-objeto-parametro.cod-param-ambiente          → nome da variável
   + parâmetro do vínculo APLICACAO.OBJETO
   + ambiente resolvido pelo PROPATH
   = thl-ambiente-param-variavel.valor-variavel  → cod-conexao  → thl-conexao-rest
                                                 → cod-path     → thl-conexao-rest-path
URL final = thl-conexao-rest.url-base + thl-conexao-rest-path.path
```

Mecanismo completo em [fluxo-ambiente.md](fluxo-ambiente.md).

**Erros do `ConnectorConfig`**, nesta ordem: código de conexão não informado para o parâmetro · código de path não informado · conexão não encontrada · path não encontrado. Os dois primeiros significam variável vazia (ou vínculo de programa ausente); os dois últimos, valor apontando para cadastro inexistente.

## Autenticação (`RestConnector`)

`case authentication:authenticationType`: `BASIC` · `BEARER` · `TOKEN` · `CUSTOM.BODY`. BEARER e TOKEN montam `Authorization: <tipo> <token>`; CUSTOM.BODY injeta no corpo.

> O dicionário do banco (`thl.df`) descreve este campo como "NONE, BASIC, BEARER, API_KEY, OAUTH2 ou CUSTOM" — **desatualizado**. Vale o `case` do conector, que é o que a tela web oferece.

## Resposta e reprocessamento

`saveResponse` grava status, mensagem e destino, atualiza as três situações e incrementa `qtd-tentativas`; com `historyEnabled`, grava `thl-mensagem-historico`. Falha antes da resposta (rede, DNS, timeout) grava `ConnectorResponse` sintético com `statusCode = 0` e a mensagem do erro — a mensagem nunca fica sem rastro.

`reprocess( messageCode )` restaura e força `ExecutionMode:ONLINE`. **Recusa mensagem com `executionMode = SCHEDULE`**, pedindo cancelamento do job — proteção contra envio duplicado.

## Cadastro que governa cada etapa

| Etapa | Tabela · campo | Efeito |
|---|---|---|
| Estrutura | `thl-objeto-parametro.ind-mensagem-simples` | Single ou Multiple structure |
| Destino | `.cod-param-ambiente` | Nome da variável que devolve `cod-conexao` |
| | `.cod-param-ambiente-destino` | Nome da variável que devolve `cod-path` |
| | `thl-ambiente-param-prog.cod-prog-dtsul` | Precisa conter `APLICACAO.OBJETO` |
| Chamada | `thl-conexao-rest.url-base` | Base da URL |
| | `thl-conexao-rest-path.path` · `.timeout` | Caminho e tempo limite |
| | `.ind-requisita-autenticacao` | Liga a aba de autenticação |
| Execução | `thl-objeto-parametro.forma-execucao` | Online · Agendar · **Batch (nenhuma ação)** |
| Tentativas | `.qtd-tentativas` | Limite de reprocessamento |
| Histórico | `thl-objeto.ind-gera-historico` | Uma linha por tentativa |

## Armadilhas

- **BATCH não faz nada** no `process()`: a mensagem fica gravada aguardando o processo em lote. No monitor aparece Pendente, sem erro.
- Reenvio pelo monitor roda **sempre online**, mesmo em objeto agendado.
- Com Multiple structure, o reenvio repete **o lote inteiro** — o destino precisa ser idempotente.
- `ConnectorConfig` usa `'APLICACAO.OBJETO'` como `programName`: sem essa linha em `thl-ambiente-param-prog`, falha antes de qualquer chamada HTTP.

## Versão para pessoas

[Notion — 2. Mensagem de saída](https://app.notion.com/p/3f4d3a2b48158118b291f2d84f0a4980).

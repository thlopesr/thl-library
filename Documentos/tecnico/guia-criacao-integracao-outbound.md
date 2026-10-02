# Guia de criação de integração outbound

Esta seção detalha passo a passo como criar uma nova integração outbound utilizando a THL‑Lib.

> Revisado em 2026-09-24 contra o código atual (`OutboundMessage`, `OutboundMessageService`, `OutboundObjectContext`, `MethodTypeEnum`, `ExecutionMode`). Exemplo real de referência: `thl-extensions\integration\loogai\messaging\outbound\message\EntregaPedidoMessage.cls`.

## 1. Planejar o objeto de integração

* **Identifique a entidade de negócio** que será enviada ao sistema externo (ex.: Pedido, Nota Fiscal, Usuário).  
* **Defina o fluxo** – Será um envio único (Single) ou múltiplo (Multiple)?  A THL‑Lib fornece as estratégias `SingleMessageStructure` e `MultipleMessageStructure`, escolhidas pela configuração (`ind-mensagem-simples` em `thl-objeto-parametro`).  
* **Estabeleça a classe de mensagem** – Mensagens de um sistema externo específico ficam em **`thl-extensions`**, nunca em `thl-lib`:  
  `Fontes\thl-extensions\integration\<sistema>\messaging\outbound\message\<Nome>Message.cls`  
  A classe herda de `OutboundMessage` e implementa `onLoadData` (posiciona o registro e devolve o código de referência) e `appendPayloadObject` (monta o JSON).

## 2. Configurar tabelas

1. **thl-objeto** – Insira um registro para o objeto.  Campos importantes:
   * `objeto` – Código (ex.: `PEDIDO`).
   * `aplicacao` – Aplicação ou módulo do ERP.
   * `classe-objeto` – **Nome completo** da classe, com pacote. A `MessageFactory` instancia via `dynamic-new` (ex.: `thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage`).
   * `sentido-fluxo` – `TRUE` (outbound).
   * `ind-gera-historico` – `TRUE` se deseja manter histórico de tentativas.
2. **thl-objeto-parametro** – Cadastre o método HTTP e operação:
   * `metodo` – Consulte `MethodTypeEnum`: **1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET**.
   * `forma-execucao` – Consulte `ExecutionMode`: **1=ONLINE (síncrono), 2=SCHEDULE (agendado/RPW), 3=BATCH**.  
   * `operacao` – **Código da operação de integração** (ex.: `Atualizacao`). É a chave usada, junto com aplicação e objeto, para localizar a configuração — não é um nome de método da classe.
   * `ind-mensagem-simples` – `TRUE` para envio único (Single), `FALSE` para múltiplo (Multiple).
   * `cod-param-ambiente` – Parâmetro de ambiente, se houver.
   * Outras opções: `ind-persistente`, `ind-gera-historico`, `tipo-log-requisicao` e `tipo-log-retorno`.
3. **thl-conexao-rest** – Crie uma conexão para o servidor externo e marque se requer autenticação.
4. **thl-conexao-rest-path** – Cadastre o path relativo ao serviço (ex.: `/pedidos`).  Informe timeout, content‑type e accept.
5. **thl-conexao-rest-autenticacao** – Configure a autenticação, se necessário.
6. **thl-objeto-usuario** – (Opcional) Inclua usuários autorizados.

## 3. Desenvolver a classe de mensagem

Esqueleto (mesma estrutura das mensagens existentes em `thl-extensions`):

```abl
using Progress.Json.ObjectModel.*.
using thl-lib.integration.messaging.outbound.core.OutboundMessage.

block-level on error undo, throw.

class thl-extensions.integration.<sistema>.messaging.outbound.message.PedidoExemploMessage inherits OutboundMessage.

    define private buffer b-ped-venda for ped-venda.

    constructor public PedidoExemploMessage ( objectName           as character ,
                                              applicationName      as character ,
                                              integrationOperation as character ,
                                              methodType           as integer   ,
                                              connectorType        as integer   ,
                                              integrationDirection as logical   ,
                                              executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor.

    //Posiciona o registro de negocio e devolve o codigo de referencia gravado na mensagem.
    method public override character onLoadData( register as recid ).
        find first b-ped-venda no-lock where recid(b-ped-venda) = register no-error.
        if not available b-ped-venda then
            this-object:errorHandler:throwError( 'onLoadData', 'Pedido nao encontrado.' ).
        return string( b-ped-venda.nr-pedido ).
    end method.

    //Monta o JSON do registro posicionado.
    method public override void appendPayloadObject().
        this-object:initializeObjectPayload().
        cast( payload, JsonObject ):add( 'codigoPedido', b-ped-venda.nr-pedido ).
        /* … demais campos conforme o contrato do sistema externo … */
    end method.

end class.
```

Pontos do contrato (`OutboundMessage.cls`):
* O construtor tem 7 parâmetros e é chamado pela `MessageFactory`; não instancie a mensagem diretamente.
* `onLoadData( register as recid )` é **abstrato** — obrigatório.
* `appendPayloadObject()` / `appendPayloadObject( objectContext )` lançam erro se não forem sobrescritos — implemente o que o fluxo usa.
* Parâmetros de path (ex.: `#Pedido#`) são preenchidos com `setPathParameter(...)`.

⚠️ Verificar a assinatura atual em `OutboundMessage.cls` antes de criar a classe. Pacotes sempre em minúsculas, iguais à pasta, e fontes gravados em **ISO-8859-1** (ver `.claude\convencoes.md`).

## 4. Integrar com o ERP

No evento de negócio (ex.: inclusão de pedido), instancie `OutboundMessageService` com **aplicação, objeto e operação**, monte a mensagem e processe:

```abl
using thl-lib.integration.messaging.outbound.service.OutboundMessageService.

define variable messageService as OutboundMessageService no-undo.

assign messageService = new OutboundMessageService( 'MinhaAplicacao', 'PEDIDO', 'Atualizacao' ).

messageService:beginBuild().
messageService:addObject( recid( ped-venda ) ).   /* ou addObject( new OutboundObjectContext( ... ) ) */
messageService:finishBuild().
messageService:process().                          /* usa a forma-execucao configurada */
```

* `beginBuild()` é obrigatório antes de `addObject(...)`, e `finishBuild()` é obrigatório antes de `process()` — o serviço lança erro se a ordem não for respeitada.
* `OutboundObjectContext` aceita `recid`, código de referência, `JsonObject` de dados adicionais ou combinações (`recid, referenceCode, additionalData`).
* `process()` devolve `logical`; o retorno do conector fica em `getLastConnectorResponse()`.

## 5. Monitorar e reprocessar

Após o envio, utilize o monitor **THL0120** para acompanhar o status das mensagens.  Se uma mensagem falhar, o `MessageExecutionService` registra o erro; o reprocessamento manual é feito pelo monitor ou por `OutboundMessageService:reprocess( messageCode )`.  Verifique também os registros de e‑mail para alertas em caso de falhas.

Seguindo estes passos, novas integrações outbound poderão ser implementadas de forma consistente e reutilizando os componentes da THL‑Lib.

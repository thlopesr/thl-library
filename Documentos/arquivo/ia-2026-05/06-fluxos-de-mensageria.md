# Fluxos de mensageria

A THL‑Lib implementa mensageria **inbound** e **outbound**, permitindo receber e enviar informações para sistemas externos de forma padronizada.  A seguir são descritos os fluxos básicos.

## Fluxo inbound (recebimento)

1. **Rota pública** – Um cliente externo envia uma requisição HTTP para o endpoint cadastrado em `thl-inbound-rota` (ex.: `/api/v1/usuario/criar`).  A rota indica qual objeto (`thl-objeto`) e operação devem ser executados.
2. **Endpoint genérico** – O programa `resourcen.p` recebe a requisição, cria um `InboundObjectContext` para armazenar payload, parâmetros de caminho e de query, e identifica o método HTTP (`MethodTypeEnum`).
3. **Resolução de rota** – A classe `InboundRouteResolver` lê `thl-inbound-rota` e determina o **objeto** e **operação** correspondentes à rota pública.  Esses dados são configurados no contexto.
4. **Processamento** – `InboundMessageService` é instanciado com o objeto, método e operação.  Ele chama `MessageFactory` para criar a classe de mensagem específica (ex.: `UsuarioMessage`) e executa a regra de negócio apropriada.
5. **Persistência** – A mensagem e seu conteúdo (request e response) são gravados em `thl-mensagem`, `thl-mensagem-item` e `thl-mensagem-conteudo`.  Situações, datas e tentativas são registradas em `thl-mensagem-historico`.  Erros são capturados por `ErrorHandler`.
6. **Resposta** – O serviço retorna uma `JsonObject` contendo a resposta de negócio ou, em caso de erro, um objeto de erro padronizado.  O endpoint converte para HTTP 201 (criado) ou HTTP 200 conforme o tipo de retorno.

## Fluxo outbound (envio)

1. **Evento interno** – Um evento no ERP (ex.: inclusão de pedido, aprovação de nota fiscal) dispara o envio de uma mensagem outbound.  Isso pode ser feito via triggers ou programas específicos que instanciam classes de mensagem (ex.: `EntregaPedidoMessage`).
2. **Criação de mensagem** – A classe de mensagem (filha de `OutboundMessage`) recebe o **recordId** e outros dados de contexto (`OutboundObjectContext`) e utiliza regras de negócio para gerar o payload JSON.  Campos adicionais podem ser preenchidos com ajuda de utilitários (`JsonSetter`, `StringUtil`).
3. **Configuração** – O serviço `MessageConfigLoader` lê `thl-objeto` e `thl-objeto-parametro` para verificar qual método HTTP utilizar, se a mensagem é síncrona ou assíncrona e quais parâmetros de ambiente aplicar.
4. **Envio** – `OutboundMessageService` monta um `ConnectorRequest` com o payload, busca no `MessageConfig` a conexão (`thl-conexao-rest`) e path (`thl-conexao-rest-path`) correspondentes e utiliza `ConnectorFactory` para obter o conector (normalmente `RestConnector`).  Se necessário, `TokenProviderFactory` é acionada para obter ou renovar o token.
5. **Gravação de mensagem** – Ao enviar, o serviço cria registro em `thl-mensagem` e `thl-mensagem-item`.  Após o retorno, grava `thl-mensagem-conteudo` com a resposta e atualiza as situações.  Caso ocorram falhas, a mensagem é marcada como `Erro` e pode ser reprocessada.
6. **Reprocessamento** – Mensagens com erro ou pendentes podem ser reprocessadas.  O serviço `MessageExecutionService` controla o número de tentativas (`qtd-tentativas`) e registra cada tentativa em `thl-mensagem-historico`.  O monitor `THL1986` permite identificar mensagens com erro e disparar reprocessamentos manualmente.

## Controle de status e histórico

* **sit-requisicao** – Indica o estado da requisição ao sistema externo (ex.: pendente, enviado, erro).  
* **sit-retorno** – Resultado retornado pelo sistema externo (sucesso, erro, não aplicável).  
* **sit-processamento** – Estado interno da mensagem no ERP (processada, em processamento, pendente).  
* **qtd-tentativas** – Número de envios tentados; controla reprocessamentos.  
* **thl-mensagem-historico** – Armazena cada tentativa de envio/recebimento, permitindo rastrear o histórico completo.

Esses fluxos permitem que a THL‑Lib trate integrações de forma resiliente, com registro de todas as etapas e capacidade de reprocessamento.

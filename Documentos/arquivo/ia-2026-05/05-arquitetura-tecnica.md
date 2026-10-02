# Arquitetura técnica

Esta seção descreve a arquitetura técnica da THL‑Lib, destacando os padrões e separação de responsabilidades utilizados.

## Separação em camadas

A arquitetura da THL‑Lib segue a prática de **separação de camadas**:

* **Apresentação (`thl/*.w`)** – Programas de tela que interagem com o usuário.  
  * São responsáveis por buscar e gravar dados nas tabelas via includes padrão Datasul.  
  * Utilizam as tabelas `thl-*` diretamente, sem depender das classes da biblioteca.  
  * Devem permanecer sem lógica de negócio complexa; apenas capturam dados de interface e chamam operações de serviço se necessário.

* **Serviços e Fábricas (classes)** – Encapsulam regras de negócio, orquestram casos de uso e delegam a persistência aos repositórios.  
  * **`ContextService`** obtém informações de contexto (usuário, ambiente).  
  * **`EnvironmentRepository`** lê e grava parâmetros de ambiente.  
  * **`InboundMessageService` / `OutboundMessageService`** processam mensagens de entrada/saída.  
  * **`ConnectorService`** realiza chamadas a APIs externas através de conectores REST.  
  * **`MessageFactory`** e **`ConnectorFactory`** instanciam classes específicas conforme o objeto ou tipo de conector.  

* **Repositórios** – Centralizam a persistência de dados (CRUD) nas tabelas da THL‑Lib.  
  * Por exemplo, `MessageRepository` grava e consulta mensagens e seus itens.  

* **Conectores** – Isolam detalhes de transporte e autenticação.  
  * `RestConnector` implementa chamadas HTTP usando `ConnectorRequest` e devolve `ConnectorResponse`.  
  * Os parâmetros de conexão são configurados nas tabelas `thl-conexao-rest`, `thl-conexao-rest-path` e `thl-conexao-rest-autenticacao`.  
  * Autenticação é configurada via `AuthenticationConfig` e o token é fornecido por implementações de `ITokenProvider`.

* **Mensageria** – Gerencia o ciclo de vida das integrações.  
  * **Inbound** – O endpoint `resourcen.p` recebe requisições REST e utiliza `InboundRouteResolver` para mapear a rota pública (`thl-inbound-rota`) para o objeto e operação.  A classe `InboundMessageService` cria uma instância de mensagem inbound, executa a operação específica (implementada em classes como `UsuarioMessage`) e grava a mensagem e seu conteúdo.  
  * **Outbound** – A partir de eventos do ERP, classes específicas (ex.: `EntregaPedidoMessage`) instanciam `OutboundMessageService`, que prepara a mensagem, chama o conector REST e grava o resultado.  Reprocessamentos e agendamentos são controlados por `MessageExecutionService` e `SchedulingService`.  
  * Todas as mensagens são gravadas em `thl-mensagem`, itens em `thl-mensagem-item` e conteúdos em `thl-mensagem-conteudo`; tentativas são registradas em `thl-mensagem-historico`.  

* **Utilitários e Comunicação** – Auxiliam as demais camadas.  
  * `EmailService` permite enviar e‑mails e grava registros em `thl-email`.  
  * `ErrorHandler` captura exceções e converte em `AppError` ou JSON padronizado.  
  * `LogUtil` e `AuditLogService` fornecem funções de log e auditoria.  
  * Utilitários de JSON, arquivo e texto facilitam a manipulação de dados.

## Padrões adotados

* **Repository Pattern** – Todas as operações de persistência são concentradas em classes repositório, evitando acesso direto às tabelas nas camadas superiores.  
* **Factory Pattern** – Fábricas criam instâncias de conectores e mensagens de forma desacoplada, permitindo extensão sem alterar código existente.  
* **Service Layer** – Serviços coordenam o fluxo de trabalho e implementam regras de negócio.  
* **Enumerações** – Enumeradores definem valores válidos para métodos (`MethodTypeEnum`), tipos de conector (`ConnectorTypeEnum`), direção (`DirectionEnum`) e modo de execução (`ExecutionMode`).  
* **Segregação de cliente** – Regras específicas de cliente não devem ser inseridas em `thl-lib`; devem ser implementadas em camadas superiores ou extensões.  

## Padrões de nomenclatura

* **Programas `thl000x`** – O número identifica o módulo; variantes (`b01`, `g01`, etc.) correspondem a abas e utilitários da mesma funcionalidade.  
* **Tabelas `thl-*`** – Representam entidades técnicas.  O campo `cod-*` geralmente indica chave primária; campos `ind-*` são indicadores lógicos.  
* **Classes em inglês** – As classes da biblioteca permanecem em inglês para facilitar o entendimento técnico e padronizar com práticas de programação.  

Esta arquitetura permite **escalar a biblioteca** com novos objetos, conexões e mensagens sem quebrar integrações existentes.  Ao adicionar novos recursos, respeite a separação de responsabilidades e utilize os padrões existentes.

# Inventário de classes `.cls`

Esta seção resume as classes encontradas na biblioteca `thl‑lib`, agrupadas por área funcional.  Para cada classe é indicada sua responsabilidade principal.  Para detalhes completos, consulte o código‑fonte correspondente.

## Core

| Classe | Responsabilidade |
|-------|----------------|
| **ContextService** | Fornece o contexto de execução (usuário, empresa, data) para outras classes. |
| **EnvironmentResource** | Representa recursos de ambiente; fornece acesso a configurações armazenadas em `thl-ambiente` e tabelas relacionadas. |
| **EnvironmentUtil** | Funções utilitárias para buscar dados de ambiente (ex.: ip, nome, código). |
| **EnvironmentRepository** | Centraliza operações de persistência das tabelas de ambiente (leitura/gravação). |
| **ErrorHandler** | Classe de tratamento de erros; acumula múltiplos erros e converte para `AppError` ou JSON padronizado. |

## Logging e Auditoria

| Classe | Responsabilidade |
|-------|----------------|
| **LogUtil** | Rotinas de log geral (informações, avisos, erros). |
| **AuditLogService** | Registra auditoria de alterações, armazenando informações na tabela `thl-audit-registro`. |

## Comunicação (E‑mail)

| Classe | Responsabilidade |
|-------|----------------|
| **EmailMessageFactory** | Monta dados de mensagens de e‑mail a partir de parâmetros centralizados (ex.: `int-param-email`, `thl-ambiente-param-grupo-usuar`). |
| **EmailLogger** | Responsável por gravar logs de envio de e‑mail. |
| **EmailSerivce** | Serviço para envio de e‑mails; utiliza a fábrica para gerar mensagens e o logger para registrar resultados. |

## Integração – Conectores

| Classe | Responsabilidade |
|-------|----------------|
| **ConnectorConfig** | Armazena configuração de uma conexão (URL base, cabeçalhos, timeout). |
| **ConnectorRequest / ConnectorResponse** | Representam requisições e respostas de conectores de forma genérica. |
| **ConnectorTypeEnum / MethodTypeEnum** | Enumeradores que indicam o tipo de conector (por enquanto REST) e o método HTTP (GET, POST, PUT, DELETE). |
| **ConnectorFactory** | Instancia o conector adequado de acordo com a enumeração (`ConnectorTypeEnum`). |
| **ConnectorService** | Serviço que executa chamadas através de um conector e trata as respostas. |
| **IntegrationConnector** | Classe base para conectores de integração. |
| **RestConnector** | Implementação concreta de um conector REST; suporta autenticação via token. |
| **AuthenticationConfig** | Configuração de autenticação (URL de token, content‑type, parâmetros); utilizada pelo conector. |
| **ITokenProvider / TokenProviderFactory** | Interface e fábrica para provedores de token; permitem diferentes estratégias de obtenção de token. |

## Integração – Mensageria

### Núcleo

| Classe | Responsabilidade |
|-------|----------------|
| **Message** | Classe base de mensagem; encapsula propriedades comuns a mensagens inbound e outbound. |
| **MessageConfig** | Carrega e aplica configurações de mensagens definidas nas tabelas. |
| **MessageFactory** | Fabrica instâncias de mensagens específicas conforme o objeto e operação. |
| **MessageRepository** | Persiste e consulta mensagens (`thl-mensagem`, `thl-mensagem-item`, `thl-mensagem-conteudo`). |
| **MessageConfigLoader** | Carrega configurações de integração (objeto, método, parâmetros) a partir das tabelas `thl-objeto`, `thl-objeto-parametro`. |
| **DirectionEnum** | Enumeração que define se a mensagem é inbound ou outbound. |
| **ExecutionMode** | Enumeração do modo de execução (síncrono, assíncrono, etc.). |

### Inbound

| Classe | Responsabilidade |
|-------|----------------|
| **InboundMessage** | Representa uma mensagem recebida de um sistema externo. |
| **InboundObjectContext** | Mantém informações de contexto para mensagens inbound: payload, parâmetros de rota, query string e texto bruto. |
| **InboundRouteResolver** | Resolve qual objeto e operação devem ser executados com base nos parâmetros de rota cadastrados em `thl-inbound-rota`. |
| **InboundMessageService** | Serviço responsável por processar mensagens inbound: valida, chama a classe de negócio específica e gera a resposta. |
| **LpcoMessage, NotaFiscalPorEmbarqueMessage, UsuarioMessage** | Exemplos de mensagens inbound específicas; cada uma contém regras para interpretar o payload e mapear para entidades do ERP. |

### Outbound

| Classe | Responsabilidade |
|-------|----------------|
| **OutboundMessage** | Representa uma mensagem enviada para um sistema externo. |
| **OutboundObjectContext** | Mantém o contexto de uma mensagem outbound (recordId, referenceCode, dados adicionais). |
| **MessageStructureStrategy** | Interface para definir estrutura de mensagens outbound. |
| **SingleMessageStructure / MultipleMessageStructure** | Estratégias que compõem uma única mensagem ou múltiplas mensagens a partir de registros. |
| **OutboundMessageService** | Serviço que envia mensagens outbound; orquestra a montagem do payload, chama o conector e persiste resultados. |
| **MessageExecutionService** | Coordenador de execução das mensagens; gerencia filas, tentativas e reprocessamentos. |
| **SchedulingService** | Serviço de agendamento para envio periódico de mensagens. |
| **EntregaPedidoMessage, LpcoMessage, NotaFiscalMessage** | Exemplos de mensagens outbound específicas; contêm regras para extrair dados do ERP e gerar o payload.

## Utilitários

| Classe | Responsabilidade |
|-------|----------------|
| **FileUtil** | Operações de leitura e escrita de arquivos. |
| **JsonSetter / JsonWriter** | Facilita montagem e leitura de objetos JSON. |
| **StringUtil** | Operações auxiliares com texto. |

Esta lista resume 51 classes encontradas.  Outras classes utilitárias ou variações poderão surgir conforme novas integrações sejam implementadas.

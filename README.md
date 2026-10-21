# THL-Library

Biblioteca/framework corporativo para o ERP TOTVS Datasul, desenvolvida em **OpenEdge ABL**, com foco em padronização arquitetural, reutilização de componentes e suporte a integrações corporativas.

A THL-Library foi concebida para centralizar recursos comuns de infraestrutura e integração, reduzindo acoplamento, melhorando a rastreabilidade e criando uma base reutilizável para múltiplos projetos e clientes.

## Objetivos

- Padronizar integrações entre o ERP Datasul e sistemas externos;
- Centralizar recursos de mensageria, conectores, configuração por ambiente, e-mail, logs e tratamento de erros;
- Fornecer uma arquitetura modular, extensível e reutilizável;
- Reduzir código específico por projeto ou cliente;
- Apoiar rastreabilidade, reprocessamento e manutenção evolutiva.

## Ambiente técnico

- **ERP:** TOTVS Datasul 12
- **Linguagem:** OpenEdge ABL / Progress
- **Paradigma:** OOABL, procedures e telas Datasul
- **IDE:** Progress Developer Studio for OpenEdge
- **Integração principal:** REST / JSON
- **Persistência:** tabelas customizadas da THL
- **Codificação dos fontes:** **ISO-8859-1** (padrão do projeto para `.cls`, `.p`, `.w` e `.i`)

## Estrutura do repositório

```text
THL-Library/
├── Database/
│   └── thl.df
├── Documentos/
├── Fontes/
│   ├── thl/
│   └── thl-lib/
├── Utils/
├── .gitignore
├── .project
├── .propath
└── build.config
```

### `Fontes/thl`

Contém a camada ligada ao ERP Datasul:

- telas `.w` de cadastro e monitoramento;
- procedures auxiliares;
- recursos de endpoint via framework TOTVS;
- monitores operacionais.

Exemplos de programas:

- `thl0001` — cadastro de ambiente/IP;
- `thl0002` — cadastro de parâmetros e variáveis por ambiente;
- `thl0011` — cadastro de grupos e usuários;
- `thl0021` — cadastro de objetos de integração;
- `thl0022` — cadastro de métodos/parâmetros e permissões;
- `thl0030`–`thl0033` — conexão REST (URI, path, autenticação, cabeçalho);
- `thl0040` — rotas inbound;
- `thl0050`/`thl0051` — auditoria (tabela e parâmetros);
- `thl0020` — cadastro de aplicações (sistemas externos);
- `thl0110` — monitor de comunicação/e-mail;
- `thl0120` — monitor de mensageria;
- `thl0150` — consulta de auditoria;
- `thl0210` / `thl0222` / `thl0250` — expurgo de e-mails, mensagens e auditoria (RPW);
- `thl0220` / `thl0221` — reprocessamento outbound e processamento inbound agendado (RPW).

Numeração: `thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa, com o mesmo `NN` do assunto (ver `Documentos/.claude/convencoes.md` §7).

### `Fontes/thl-lib`

Contém as classes reutilizáveis da biblioteca, organizadas por domínio:

```text
thl-lib/
├── communication/
│   └── email/
├── core/
│   ├── context/
│   ├── environment/
│   └── error/
├── integration/
│   ├── connectors/
│   └── messaging/
├── logging/
└── util/
```

## Módulos principais

### Ambiente e contexto

Responsável por identificar o ambiente de execução e resolver configurações dinâmicas por ambiente, evitando valores fixos no código.

Principais componentes:

- `ContextService`
- `EnvironmentUtil`
- `EnvironmentResource`
- `EnvironmentRepository`

### Mensageria

Responsável pelo ciclo de vida das mensagens de integração, incluindo:

- criação;
- conteúdo;
- histórico;
- tentativas;
- status;
- reprocessamento;
- fluxos inbound e outbound.

Principais componentes:

- `Message`
- `MessageConfig`
- `MessageFactory`
- `MessageRepository`
- `InboundMessageService`
- `OutboundMessageService`
- `MessageExecutionService`

### Conectores

Responsável pela execução técnica das integrações externas.

Conector atualmente presente no pacote:

- `RestConnector`

Estrutura preparada para evolução futura de conectores como:

- SOAP;
- banco de dados;
- arquivos.

Principais componentes:

- `ConnectorConfig`
- `ConnectorRequest`
- `ConnectorResponse`
- `ConnectorFactory`
- `ConnectorService`
- `IntegrationConnector`

### Comunicação e e-mail

Responsável por padronizar o envio e o registro de mensagens de e-mail.

Principais componentes:

- `EmailLogger`
- `EmailMessageFactory`
- `EmailSerivce`

### Logs, auditoria e utilitários

- `LogUtil`
- `AuditLogService`
- `JsonSetter`
- `JsonWriter`
- `StringUtil`
- `ErrorHandler`

## Tabelas principais

O arquivo `Database/Definition/thl.df` contém as tabelas utilizadas pela biblioteca.

### Configuração de ambiente

- `thl-ambiente`
- `thl-ambiente-param`
- `thl-ambiente-param-prog`
- `thl-ambiente-param-variavel`

### Permissões e grupos

- `thl-ambiente-param-grupo`
- `thl-ambiente-param-grupo-usuar`
- `thl-objeto-usuario`

### Objetos de integração

- `thl-objeto`
- `thl-objeto-parametro`

### Mensageria

- `thl-mensagem`
- `thl-mensagem-conteudo`
- `thl-mensagem-historico`
- `thl-mensagem-item`

### Comunicação

- `thl-email`

## Princípios arquiteturais

A biblioteca segue os seguintes princípios:

- separação clara entre interface ERP, domínio, infraestrutura e persistência;
- uso de `Repository` para centralizar persistência;
- uso de `Service` para orquestração de casos de uso;
- uso de `Factory` para resolução dinâmica de classes;
- uso de `Strategy` quando houver variação estrutural de comportamento;
- uso de `Template Method` em fluxos base de mensagens e conectores;
- isolamento entre **Messaging** e **Connectors**;
- configuração por ambiente, sem URL, token, usuário ou senha fixos no código;
- preferência por classes reutilizáveis e baixo acoplamento;
- regras específicas de cliente fora das classes base.

## Fluxos suportados

### Outbound

Fluxo conceitual:

```text
OutboundMessageService
  -> MessageConfigLoader
  -> MessageFactory
  -> MessageStructureStrategy
  -> MessageRepository
  -> MessageExecutionService
  -> ConnectorService
  -> ConnectorFactory
  -> RestConnector
```

Modos previstos:

- **Online** — execução imediata;
- **Agendado** — execução futura;
- **Batch/Fila** — consumo por rotina posterior.

### Inbound

Fluxo conceitual:

```text
Endpoint TOTVS
  -> InboundMessageService
  -> MessageConfigLoader
  -> MessageFactory
  -> InboundMessage concreta
  -> MessageRepository
  -> ErrorHandler
```

## Convenções de desenvolvimento

- Codificação: fontes ABL (`.cls`, `.p`, `.w`, `.i`) sempre em **ISO-8859-1** — nunca UTF-8 nem com BOM;
- Pacote ABL idêntico à pasta, sempre em minúsculas (ex.: `thl-lib.integration.messaging.inbound.core.InboundMessage`);
- Código técnico em inglês: classes, métodos e propriedades;
- Interface ERP pode permanecer em português;
- Evitar variáveis públicas; preferir propriedades;
- Evitar persistência fora de `Repository`;
- Evitar lógica HTTP dentro de classes de mensagem;
- Evitar regras de negócio específicas em classes base;
- Preservar rastreabilidade e reprocessamento;
- Manter a biblioteca preparada para distribuição em múltiplos clientes.

## Situação atual e evoluções futuras

### Presente no pacote atual

- módulo de ambiente;
- módulo de mensageria inbound e outbound;
- conector REST;
- comunicação por e-mail;
- logs, auditoria, utilitários JSON/string e tratamento de erros;
- tabelas customizadas da biblioteca;
- telas ERP e endpoints de integração.

### Evoluções previstas

- conectores SOAP, Database e File;
- amadurecimento do agendamento e execução batch;
- testes automatizados para componentes core;
- revisão de nomenclaturas legadas;
- ampliação da documentação técnica.

## Como utilizar no PDSOE

1. Importe o projeto no Progress Developer Studio for OpenEdge;
2. Ajuste o `PROPATH` conforme o ambiente Datasul;
3. Importe a estrutura de banco de `Database/Definition/thl.df` no banco de destino;
4. Configure ambientes, parâmetros, objetos de integração e permissões pelas telas THL;
5. Utilize as classes de `thl-lib` nos fluxos de integração desejados.

## Versionamento

A branch principal do projeto é:

```text
main
```

Sugestão de fluxo:

- `main` — versão estável;
- `develop` — integração de desenvolvimento;
- `feature/*` — novas funcionalidades;
- `fix/*` — correções.

## Observações

Este projeto deve ser tratado como uma **biblioteca corporativa reutilizável**, e não como uma solução pontual de um único cliente ou integração.

Sempre que possível, novas funcionalidades devem preservar:

- modularidade;
- baixo acoplamento;
- extensibilidade;
- clareza de responsabilidades;
- compatibilidade com o ambiente TOTVS Datasul / OpenEdge ABL.


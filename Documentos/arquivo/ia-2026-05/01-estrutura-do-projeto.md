# Estrutura do projeto THL‑Lib

A árvore de diretórios da solução contém duas raízes principais:

```
thl/          # programas .w e includes para o ERP
  include/   # includes de suporte (i01thl011.i etc.)
  thl0002.w, thl0003.w, … thl2000.w
  integration/api/v1/resourcen.p  # endpoint REST inbound

thl‑lib/      # biblioteca de classes reutilizáveis (.cls)
  communication/email/…            # envio de e‑mail
  core/context/, core/environment/ # contexto e ambiente
  integration/connectors/…         # conectores REST e autenticação
  integration/messaging/…          # classes de mensageria inbound/outbound
  logging/                         # log e auditoria
  util/file/, util/json/, util/string/ # utilitários gerais
```

### Componentes principais

**Programas `.w` (thl)**

* *Cadastros* – Permitem criar/alterar registros em tabelas da biblioteca (ambientes, parâmetros, objetos, conexões, rotas).  
* *Consultas e monitores* – Visualizam mensagens processadas, e‑mails enviados e histórico de execução.  
* *Variantes* (`b01`, `g01`, `v01`, `q01`, `z01`, etc.) – Telas auxiliares de cada cadastro/consulta (abordagem padrão Datasul com abas e versões).  
* *Endpoint API* – O arquivo `thl/integration/api/v1/resourcen.p` implementa um endpoint REST genérico que roteia chamadas inbound para classes de mensageria conforme a rota cadastrada.

**Biblioteca `thl‑lib`**

* *Core* – Classes de contexto e ambiente que fornecem acesso às informações de execução (usuário, empresa) e leitura dos parâmetros (tabelas `thl-ambiente*`).  
* *Integration / Messaging* – Implementa as classes `Message`, `InboundMessage`, `OutboundMessage` e serviços correspondentes. Permite definir mensagens inbound/outbound, carregar configurações (`MessageConfig`), orquestrar envio (`OutboundMessageService`) ou processamento (`InboundMessageService`) e registrar histórico no banco.  
* *Integration / Connectors* – Define enumeradores (`ConnectorTypeEnum`, `MethodTypeEnum`) e classes para REST (`RestConnector`), incluindo configuração (`ConnectorConfig`, `AuthenticationConfig`) e serviços de fábrica (`ConnectorFactory`, `TokenProviderFactory`).  
* *Communication* – Fornece serviços de e‑mail (`EmailService`), gerando mensagens a partir de parâmetros (`EmailMessageFactory`) e registrando log (`EmailLogger`).  
* *Logging* – Utilitários para auditoria (`AuditLogService`) e log de execução (`LogUtil`).  
* *Util* – Funções auxiliares para manipular arquivos (`FileUtil`), JSON (`JsonSetter`, `JsonWriter`) e texto (`StringUtil`).

A estrutura modular permite incluir novos conectores, mensagens ou utilitários sem alterar programas existentes.

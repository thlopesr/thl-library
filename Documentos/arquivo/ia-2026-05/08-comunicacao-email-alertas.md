# Comunicação por e‑mail e alertas

A biblioteca THL‑Lib oferece funcionalidades para envio de e‑mails técnicos ou de notificação, reutilizando cadastros existentes no ERP e parâmetros configuráveis.

## Tabela `thl-email`

Todos os e‑mails enviados são registrados na tabela `thl-email`, com campos para data de envio, remetente, destinatário(s), assunto, anexo, mensagem e retorno do servidor.  O campo `cod-param-ambiente` permite relacionar o envio ao ambiente específico (via `thl-ambiente-param`).

## Grupos de e‑mail

Os programas **THL0004** e **THL0004b** permitem cadastrar grupos de e‑mail em `thl-ambiente-param-grupo` e relacionar usuários em `thl-ambiente-param-grupo-usuar`.  Esses grupos são usados pela **EmailMessageFactory** para determinar destinatários com base no ambiente e no tipo de notificação.

## Classes de envio

* **EmailMessageFactory** – Monta a mensagem de e‑mail lendo parâmetros de diversas tabelas do ERP (ex.: `param_email`, `int-param-email`) e os grupos cadastrados na THL‑Lib.  Permite compor destinatários, assunto e corpo padrão.  
* **EmailLogger** – Registra log do envio e atualiza `thl-email`.  
* **EmailSerivce** – Serviço que envia a mensagem propriamente dita.  Pode utilizar APIs externas ou serviços internos de e‑mail conforme a configuração do ERP.

## Uso típico

1. **Cadastrar grupos e usuários** – Use o programa *THL0004* para criar grupos (ex.: *ALERTAS_INTEGRACAO*) e associar usuários e e‑mails alternativos.  
2. **Configurar parâmetros de e‑mail** – Defina no ERP as tabelas padrão de e‑mail (`param_email`, `int-param-email`) apontando para os grupos criados.  
3. **Gerar e‑mail via código** – Nos serviços ou programas que precisarem enviar alertas, instancie `EmailSerivce`, passando a configuração e os dados específicos (ex.: erro de integração).  O serviço montará a mensagem, enviará e gravará o log.  
4. **Consultar e‑mails enviados** – Use o programa *THL2000* para pesquisar registros em `thl-email`, com filtros de data, remetente, destinatário e programa.  É possível abrir o registro para ver detalhes da mensagem e o retorno do servidor.

## Alertas automáticos

Recomenda‑se criar alertas automáticos para determinadas situações de mensageria (ex.: após N tentativas de envio com erro).  Isso pode ser implementado no `MessageExecutionService`, disparando uma mensagem de e‑mail através de `EmailSerivce` para um grupo de suporte.

## Considerações

* A THL‑Lib não implementa um serviço próprio de SMTP; utiliza recursos existentes do ERP.  
* É importante manter o cadastro de grupos de e‑mail atualizado para garantir que alertas cheguem às pessoas corretas.  
* Para grandes volumes de e‑mail, considere limitar o registro de anexos na tabela `thl-email` a metadados e armazenar arquivos em diretórios.

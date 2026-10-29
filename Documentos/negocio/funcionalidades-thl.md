# Funcionalidades da Biblioteca THL (Technical Helper Library)

A THL é uma biblioteca de apoio ao desenvolvimento de customizações para o ERP TOTVS. Este conjunto de guias descreve, em nível de negócio, cada funcionalidade e os cadastros que a configuram.

| Funcionalidade | O que resolve | Guia |
|---|---|---|
| **Utils** | Utilitários de uso geral que qualquer programa pode chamar: texto, datas, JSON, arquivos, dicionário de dados, CSV, varredura de fontes e compilação. Com exemplos de chamada | [funcionalidade-utils.md](funcionalidade-utils.md) |
| **Integração** | Troca de mensagens com sistemas externos, de entrada e de saída, com rastreio e reprocessamento. Inclui os cadastros de aplicação, objeto, conexão, autenticação, header e path | [funcionalidade-integracao.md](funcionalidade-integracao.md) |
| **E-mail** | Envio padronizado de e-mails, com texto e destinatários cadastrados e monitor de envios. Cadastros de grupo de e-mail e parâmetro de e-mail | [funcionalidade-email.md](funcionalidade-email.md) |
| **Variável de ambiente** | Valores que mudam entre produção, homologação e desenvolvimento, fora do código. Cadastros de ambiente e parâmetro | [funcionalidade-variavel-ambiente.md](funcionalidade-variavel-ambiente.md) |
| **Auditoria** | Registro de quem alterou o quê nas tabelas do ERP, com níveis de acesso e retenção. Cadastros de tabela auditada, campos, acessos, notificações e expurgo | [funcionalidade-auditoria.md](funcionalidade-auditoria.md) |

## Como as funcionalidades se relacionam

- **Variável de ambiente** é a base: a Integração de saída e o E-mail descobrem seus valores por ela.
- **E-mail** usa grupos de e-mail, que a **Auditoria** também usa nas notificações.
- **Utils** é independente: não exige cadastro.

## Outros guias

| Guia | Conteúdo |
|---|---|
| [guia-telas-web.md](guia-telas-web.md) | Cada tela web, campo a campo |
| [guia-operacional-biblioteca-thl.md](guia-operacional-biblioteca-thl.md) | Visão operacional e rotinas |
| [guia-monitoramento-mensageria.md](guia-monitoramento-mensageria.md) | Passo a passo do monitor de mensageria |
| [guia-monitoramento-comunicacao.md](guia-monitoramento-comunicacao.md) | Passo a passo do monitor de e-mail |
| [faq-biblioteca-thl.md](faq-biblioteca-thl.md) | Perguntas frequentes |
| [guia-cadastros-thl.md](guia-cadastros-thl.md) | Cadastros nos programas Datasul (desatualizado; prefira os guias acima e o guia das telas web) |

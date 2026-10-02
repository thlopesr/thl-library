# Pacote: communication/email

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| EmailMessageFactory | Monta os dados de uma mensagem de e-mail lendo parâmetros de ambiente e tabelas de configuração | Factory | EnvironmentContext, EnvironmentResource, EmailParamRepository | EmailService |
| EmailService | Executa o envio de e-mail via API Datasul (`utapi019`) e persiste o resultado | Service | EmailMessageFactory, EmailLogger | Programas de negócio |
| EmailLogger | Persiste o registro de envio de e-mail na tabela `thl-email` | Repository | EmailMessageFactory | EmailService |
| EmailParamRepository | Carrega parâmetros de e-mail das tabelas `thl-email-param`, `param_email` e grupos de usuário | Repository | StringUtil, ThlError | EmailMessageFactory |

---

## EmailMessageFactory

**Caminho:** `thl-lib\communication\email\EmailMessageFactory.cls`

**Namespace ABL:** `thl-lib.communication.email.EmailMessageFactory`

**Responsabilidade:** Faz a leitura centralizada de todos os parâmetros necessários para envio de e-mail (remetente, destinatários, assunto, corpo, SMTP, TLS/SSL) a partir do ambiente configurado. Após o construtor, os campos podem ser ajustados via `applyPlaceholder` para substituição de tokens dinâmicos.

**Padrão de projeto:** Factory (builder de dados).

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `EnvironmentContext`, `EnvironmentResource`, `EmailParamRepository`.

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `sender` | `character` |
| `toRecipients` | `character` |
| `ccRecipients` | `character` |
| `subject` | `character` |
| `attachmentPath` | `character` |
| `body` | `character` |
| `importance` | `integer` (inicial = 0) |
| `programName` | `character` |
| `environmentParameter` | `character` |
| `saveReturn` | `logical` |
| `smtpServer` | `character` |
| `smtpPort` | `integer` |
| `useTLS` | `logical` |
| `useSSL` | `logical` |
| `debug` | `logical` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public EmailMessageFactory()` | Resolve ambiente atual via `EnvironmentResource`, carrega `codigoEmail` da variável de ambiente, popula todas as propriedades. |
| `method public void applyPlaceholder( input pField as character, input pToken as character, input pValue as character )` | Substitui token em `sender`, `subject` ou `body` usando `replace`. |

---

## EmailService

**Caminho:** `thl-lib\communication\email\EmailService.cls`

**Namespace ABL:** `thl-lib.communication.email.EmailService`

**Responsabilidade:** Envia e-mail chamando `utp/utapi019.p` (API Datasul de e-mail) e, se `saveReturn = true`, persiste o resultado via `EmailLogger`. Suporta dois construtores: um que instancia `EmailMessageFactory` automaticamente e outro que recebe injeção da factory.

**Padrão de projeto:** Service.

**INHERITS / IMPLEMENTS:** Nenhum. Inclui temp-tables da API via `{utp/utapi019.i2}`.

**Dependências diretas THL:** `EmailMessageFactory`, `EmailLogger`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public EmailService()` | Instancia `EmailMessageFactory` automaticamente. |
| `constructor public EmailService( pMessageFactory as EmailMessageFactory )` | Recebe factory externa (para testes ou customização). |
| `method public void sender()` | Chama `executeDatasulMailService()` e depois `saveReturn()`. |
| `method public void executeDatasulMailService()` | Monta `tt-envio2`, `tt-mensagem`, `tt-paramEmail2` e chama `pi-execute4` do `utapi019`. |
| `method public void saveReturn()` | Se `saveReturn = true`, serializa temp-tables para longchar e chama `EmailLogger:save`. |

**Observações:** Usa `error-status:error` e `not temp-table tt-erros:has-records` para determinar sucesso — combinação que pode ser imprecisa se `error-status` não for resetado entre chamadas.

---

## EmailLogger

**Caminho:** `thl-lib\communication\email\repository\EmailLogger.cls`

**Namespace ABL:** `thl-lib.communication.email.repository.EmailLogger`

**Responsabilidade:** Persiste o registro de envio de e-mail na tabela `thl-email`, incluindo remetente, destinatário, assunto, retorno da API e corpo da mensagem.

**Padrão de projeto:** Repository.

**Tabelas acessadas:** `thl-email` (create).

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `messageText` | `longchar` (corpo da mensagem serializado) |
| `sendInfo` | `longchar` (temp-table `tt-envio2` serializada) |
| `returnPayload` | `longchar` (temp-table `tt-erros` serializada) |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void save( emailMessageFactory as EmailMessageFactory, success as logical )` | Cria registro em `thl-email` com `log-envio = 2` (sucesso) ou `3` (falha). Trunca `mensagem` para 4000 caracteres se necessário. |

---

## EmailParamRepository

**Caminho:** `thl-lib\communication\email\repository\EmailParamRepository.cls`

**Namespace ABL:** `thl-lib.communication.email.repository.EmailParamRepository`

**Responsabilidade:** Encapsula leitura das tabelas de configuração de e-mail: parâmetros de envio (`thl-email-param`), parâmetros SMTP (`param_email`) e lista de destinatários por grupo de usuários (`thl-ambiente-param-grupo-usuar` + `usuar_mestre`).

**Padrão de projeto:** Repository.

**Tabelas acessadas:** `thl-email-param`, `param_email`, `thl-ambiente-param-grupo-usuar`, `usuar_mestre`.

**Propriedades públicas (get público, set privado):**

| Nome | Tipo |
|---|---|
| `saveReturn` | `logical` |
| `sender` | `character` |
| `subject` | `character` |
| `body` | `character` |
| `ccRecipients` | `character` |
| `importance` | `integer` |
| `userGroupCode` | `character` |
| `smtpServer` | `character` |
| `smtpPort` | `integer` |
| `useTLS` | `logical` |
| `useSSL` | `logical` |
| `debug` | `logical` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void loadEmailParameters( input emailParamCode as character )` | Carrega `thl-email-param` pelo código. Lança `ThlError` se código vazio ou registro não encontrado. |
| `method public void loadConnectionParameters()` | Carrega `param_email`. Lança `ThlError` se não encontrado. |
| `method public character loadRecipients( input groupCode as character )` | Monta lista de destinatários concatenando email alternativo e email do `usuar_mestre` por grupo. Retorna `''` se `groupCode` vazio. |

**Observações:** `useSSL`, `useTLS` e `debug` são lidos de `param_email.cod_livre_2` como entradas delimitadas por `'|'` (posições 1, 2, 3). Dependência de convenção de dados no campo livre.

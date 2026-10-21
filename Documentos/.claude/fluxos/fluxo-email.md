---
tipo: guia
camada: ambos
status: vigente
tags: [fluxo, email]
updated: 2026-10-13
---

# Fluxo — envio de e-mail

> Do parâmetro à API de e-mail do Datasul. Usa o mecanismo de [fluxo-ambiente.md](fluxo-ambiente.md). Referência por classe em [communication/email.md](../communication/email.md).
>
> Verificado por leitura do código em 2026-10-09. Nada executado contra PASOE.

## Cadeia de chamadas

```text
Programa do ERP
  └─ new EmailService()                      [ou EmailService( factory ) para injeção]
       └─ new EmailMessageFactory()
            ├─ new EnvironmentResource()                      ← sobe o call stack
            │    getEnvironmentVariable( 'codigo.email' )      → cod-email-param
            ├─ EmailParamRepository:loadEmailParameters( cod ) → thl-email-param
            ├─ EmailParamRepository:loadConnectionParameters() → param_email (Datasul)
            └─ loadRecipients( userGroupCode )                → thl-ambiente-param-grupo-usuar
       ├─ applyPlaceholder( 'sender' | 'subject' | 'body', token, valor )   n vezes
       └─ sender()
            ├─ executeDatasulMailService()   utp/utapi019.p, pi-execute4
            └─ saveReturn()                  só se thl-email-param.log-gerar
```

## Escolha do parâmetro de e-mail

O programa **não informa** `cod-email-param`. O THL lê a variável **`codigo.email`** do parâmetro de ambiente vinculado ao programa atual (construtor sem argumento → sobe o call stack).

Como é variável de ambiente, o mesmo programa envia e-mails diferentes por ambiente — em homologação, `codigo.email` pode apontar para um parâmetro cujo grupo só tem a equipe interna.

Não encontrando `thl-email-param`: `ThlError` "Parametros de conexao de email thl-email-param nao encontrados".

## Montagem dos destinatários

`loadRecipients` percorre `thl-ambiente-param-grupo-usuar` do grupo e, para cada registro:

```text
if hasValue( email-alternativo )            → recipients += ',' + email-alternativo
if available usuar_mestre and
   hasValue( cod_e_mail_local )             → recipients += ',' + cod_e_mail_local
```

**Não há `else`: os dois endereços entram.** Usuário com e-mail no ERP e alternativo preenchido recebe duas vezes. A lista sai com `trim( recipients, ',' )`; separador é vírgula, igual ao campo `copia`.

## Envio

`executeDatasulMailService` monta `tt-envio2`, `tt-mensagem` e `tt-paramEmail2` e chama `pi-execute4` em `utp/utapi019.p`. Pontos fixos no código: `versao-integracao = 1`, `formato = 'HTML'`, `caminhoEmail = 5`, `log-enviada = no`, `log-lida = no`.

Servidor e porta vêm de **`param_email` (tabela do Datasul)**, não do THL — junto com TLS, SSL e debug. Falha generalizada de envio é configuração do ERP ou rede, não cadastro THL.

## Registro

`saveReturn()` retorna cedo quando `saveReturn = false` (`thl-email-param.log-gerar`). Caso contrário, serializa `tt-erros`, `tt-mensagem` e `tt-envio2` em JSON e grava via `EmailLogger` — é o que alimenta `thl-email` e, com ele, o monitor e as métricas de e-mail.

**Sem `log-gerar`, o envio não deixa rastro algum.**

## Marcadores

`applyPlaceholder( pField, pToken, pValue )` faz `replace` em `sender`, `subject` ou `body`. Os tokens (`#1#`, `#2#`…) e seus valores são responsabilidade do programa chamador — não há catálogo no framework. Token sem substituição **chega literal ao destinatário**.

## Cadastro que governa cada etapa

| Etapa | Tabela · campo | Efeito |
|---|---|---|
| Escolha do e-mail | `thl-ambiente-param-variavel` com `cod-variavel = 'codigo.email'` | Qual `thl-email-param` o programa usa, por ambiente |
| Conteúdo | `thl-email-param.assunto` · `.mensagem` · `.copia` · `.remetente` · `.importancia` | Texto e endereços fixos |
| Destinatários | `thl-email-param.cod-grp-usuar` | Grupo consultado |
| | `thl-ambiente-param-grupo-usuar.email-alternativo` | **Soma** ao e-mail do `usuar_mestre` |
| Registro | `thl-email-param.log-gerar` | Grava `thl-email` ou não |
| Transporte | `param_email` (Datasul) | Servidor, porta, TLS/SSL |

## Armadilhas

- **Alternativo soma, não substitui** — causa de "recebi duas vezes".
- Sem `log-gerar`, o envio existe e não é auditável.
- `codigo.email` igual nos dois ambientes faz teste de homologação alcançar o destinatário real.
- O corpo vai sempre como **HTML**; texto puro aparece sem formatação, não como texto plano.

## Versão para pessoas

[Notion — 4. E-mail](https://app.notion.com/p/3f4d3a2b481581708185e89066896697), com roteiro de montagem.

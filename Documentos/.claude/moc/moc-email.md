---
tipo: guia
camada: core
status: vigente
tags: [moc, email, comunicacao]
updated: 2026-10-13
---

# MOC — E-mail

Mapa de navegação: só aponta. Voltar a [moc-geral.md](moc-geral.md).

| O quê | Onde |
|---|---|
| Classes (`EmailMessageFactory`, `EmailService`, `EmailLogger`, `EmailParamRepository`) | [communication/email.md](../communication/email.md) |
| Fluxo ponta a ponta (destinatários que somam, `utapi019`, registro condicionado a `log-gerar`) | [fluxos/fluxo-email.md](../fluxos/fluxo-email.md) |
| Tabelas | `thl-email`, `thl-email-param`, `thl-ambiente-param-grupo`, `thl-ambiente-param-grupo-usuar` — [data/schema.md](../data/schema.md) |
| Telas Datasul | `thl0010` (parâmetros), `thl0011` (grupos de e-mail), `thl0110` (monitor), `thl0210` + `thl0210rp.p` (expurgo) — [thl/camada-datasul.md](../thl/camada-datasul.md) |
| Serviços REST (extensão `thl`) | `EmailService`, `EmailParametroService`, `GrupoEmailService`, `GrupoEmailUsuarioService` — [extensions/thl.md](../extensions/thl.md); Postman: pastas `Email`, `Email Parametro` e `Grupo Email` |
| Telas web | monitor de e-mail e métricas — [web/app-web.md](../web/app-web.md) |
| Roadmap | reenvio automático de e-mails com falha e layout comum de e-mail: ver [moc-jobs-rpw.md](moc-jobs-rpw.md) |

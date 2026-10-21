---
tipo: guia
camada: core
status: vigente
tags: [moc, auditoria, log]
updated: 2026-10-13
---

# MOC — Auditoria

Mapa de navegação: só aponta. Voltar a [moc-geral.md](moc-geral.md).

| O quê | Onde |
|---|---|
| Visão de ponta a ponta (trigger → `AuditLogService` → consulta → expurgo, achados D1–D5) | [logging/auditoria.md](../logging/auditoria.md) |
| Pacote de log e auditoria | [logging/logging.md](../logging/logging.md) |
| Tabelas | `thl-audit-tabela`, `-acesso`, `-campo`, `-notificacao`, `-purge`, `thl-audit-registro`, `-detalhe`, `-notificar` — [data/schema.md](../data/schema.md), [data/er-diagrama.md](../data/er-diagrama.md) |
| Telas Datasul | `thl0050` e `thl0051` (+b/c/d/e/h): configuração; `thl0150` (+b): consulta; `thl0250` + `thl0250rp.p`: expurgo — [thl/camada-datasul.md](../thl/camada-datasul.md) |
| Serviços REST (extensão `thl`) | `AuditoriaTabelaService` e filhos (`Acesso`, `Campo`, `Notificacao`, `Expurgo`), `AuditoriaService` — [extensions/thl.md](../extensions/thl.md); Postman: pastas `Auditoria Tabela` e `Auditoria` |
| ADRs | [auditoria-desempenho-trigger](../adr/auditoria-desempenho-trigger.md) (proposta), [niveis-sensibilidade-auditoria](../adr/niveis-sensibilidade-auditoria.md) (proposta) |
| Dívida | TD-002, TD-003, TD-004 e TD-010 em [tech-debt/REGISTRO.md](../tech-debt/REGISTRO.md) |

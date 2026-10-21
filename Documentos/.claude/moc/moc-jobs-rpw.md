---
tipo: guia
camada: core
status: vigente
tags: [moc, rpw, jobs]
updated: 2026-10-13
---

# MOC — Jobs RPW

Mapa de navegação: só aponta. Voltar a [moc-geral.md](moc-geral.md).

> [!todo] O **framework de jobs RPW** (`ThlJob`, runner genérico, histórico de execução) é item de roadmap e **não tem código no repositório**. Esta nota cobre só os RPWs que existem hoje.

| RPW (tela + `rp.p`) | Assunto | Onde |
|---|---|---|
| `thl0210` / `thl0210rp.p` | expurgo de e-mails | [thl/camada-datasul.md](../thl/camada-datasul.md) |
| `thl0220` / `thl0220rp.p` (+ `thl0220z.p`, agendador) | reprocessamento outbound | idem; fluxo em [fluxos/fluxo-saida.md](../fluxos/fluxo-saida.md) |
| `thl0221` / `thl0221rp.p` | processamento inbound agendado | idem; [limitação do contexto agendado](../integration/messaging-inbound.md) |
| `thl0222` / `thl0222rp.p` | expurgo de mensagens | idem; [ADR de métricas e expurgo](../adr/metricas-conteudo-expurgo-mensagens.md) |
| `thl0250` / `thl0250rp.p` | expurgo da auditoria | idem; achados D2 e D3 em [logging/auditoria.md](../logging/auditoria.md) |

Roadmap: página "THL — Roadmap de novas funcionalidades" no Notion (jobs RPW, resiliência, event bus). Dívida relacionada: TD-004 e TD-010 em [tech-debt/REGISTRO.md](../tech-debt/REGISTRO.md).

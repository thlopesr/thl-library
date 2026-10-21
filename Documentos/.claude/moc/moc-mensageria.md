---
tipo: guia
camada: core
status: vigente
tags: [moc, mensageria, inbound, outbound]
updated: 2026-10-13
---

# MOC — Mensageria (inbound e outbound)

Mapa de navegação: só aponta. Voltar a [moc-geral.md](moc-geral.md).

| O quê | Onde |
|---|---|
| Arquitetura e classes-base | [arquitetura.md](../arquitetura.md); [Message](../arquitetura/Message.md), [InboundMessage](../arquitetura/InboundMessage.md), [OutboundMessage](../arquitetura/OutboundMessage.md), [Service](../arquitetura/Service.md), [BusinessObject](../arquitetura/BusinessObject.md), [MessageStructureStrategy](../arquitetura/MessageStructureStrategy.md) |
| Pacotes | [messaging-core](../integration/messaging-core.md), [messaging-inbound](../integration/messaging-inbound.md), [messaging-outbound](../integration/messaging-outbound.md), [erp-services](../erp/erp-services.md) |
| Fluxos ponta a ponta | [fluxo-entrada](../fluxos/fluxo-entrada.md), [fluxo-saida](../fluxos/fluxo-saida.md) |
| Tabelas | `thl-aplicacao`, `thl-objeto`, `thl-objeto-parametro`, `thl-objeto-parametro-rest`, `thl-objeto-rota`, `thl-objeto-usuario`, `thl-mensagem`, `-conteudo`, `-historico`, `-item`, `-ped-exec` — [data/schema.md](../data/schema.md), [data/er-diagrama.md](../data/er-diagrama.md) |
| Telas Datasul | `thl0020` (aplicação), `thl0021` (objeto), `thl0022` (+a/b: parâmetros e usuários), `thl0120` (+a/b/c: monitor), `thl0220`, `thl0221`, `thl0222` (RPWs) — [thl/camada-datasul.md](../thl/camada-datasul.md) |
| Serviços REST (extensão `thl`) | `AplicacaoService`, `ObjetoService`, `ObjetoParametroService`, `ObjetoUsuarioService`, `ObjetoRotaService`, `MensageriaService`, `MensageriaConteudoService` — [extensions/thl.md](../extensions/thl.md); Postman: pastas `Aplicação`, `Objeto` e `Mensageria` |
| Extensões com mensagens | [automatizador](../extensions/automatizador.md), [dvv](../extensions/dvv.md), [gestaoepi](../extensions/gestaoepi.md), [iacompras](../extensions/iacompras.md), [loogai](../extensions/loogai.md), [mmcm](../extensions/mmcm.md), [ninahub](../extensions/ninahub.md), [powerautomate](../extensions/powerautomate.md) |
| Telas web | monitor de mensageria e métricas — [web/app-web.md](../web/app-web.md) |
| ADRs | [inbound-message-processor-service](../adr/inbound-message-processor-service.md), [operacao-acao-extensao-rest](../adr/operacao-acao-extensao-rest.md), [get-no-execute-do-service](../adr/get-no-execute-do-service.md), [metricas-conteudo-expurgo-mensagens](../adr/metricas-conteudo-expurgo-mensagens.md), [separacao-core-extensoes](../adr/separacao-core-extensoes.md) |
| Backlog e dívida | [refactoring/backlog-inbound-erp.md](../refactoring/backlog-inbound-erp.md); TD-001 em [tech-debt/REGISTRO.md](../tech-debt/REGISTRO.md) |

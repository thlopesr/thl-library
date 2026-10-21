---
tipo: guia
camada: core
status: vigente
tags: [moc, ambiente, parametros]
updated: 2026-10-13
---

# MOC — Ambiente e parâmetros

Mapa de navegação: só aponta; o conteúdo está nas notas ligadas. Voltar a [moc-geral.md](moc-geral.md).

| O quê | Onde |
|---|---|
| Classes (`EnvironmentUtil`, `EnvironmentContext`, `EnvironmentResource`, `EnvironmentRepository`, `ContextService`) | [core/environment.md](../core/environment.md), [core/context.md](../core/context.md) |
| Fluxo ponta a ponta (PROPATH, vínculo programa → parâmetro, cache de sessão) | [fluxos/fluxo-ambiente.md](../fluxos/fluxo-ambiente.md) |
| Tabelas | `thl-ambiente`, `thl-ambiente-param`, `thl-ambiente-param-variavel`, `thl-ambiente-param-prog` — [data/schema.md](../data/schema.md), [data/er-diagrama.md](../data/er-diagrama.md) |
| Telas Datasul | `thl0001` (ambiente), `thl0002` (+a/b/c: parâmetros, variáveis, programas) — [thl/camada-datasul.md](../thl/camada-datasul.md) |
| Serviços REST (extensão `thl`) | `AmbienteService`, `ParametroAmbienteService`, `ParametroVariavelService`, `ParametroProgramaService` — [extensions/thl.md](../extensions/thl.md); Postman: pastas `Ambiente` e `Parametro` |
| Telas web | cadastro de ambientes e parâmetros — [web/app-web.md](../web/app-web.md), [web/motor-cadastro.md](../web/motor-cadastro.md) |
| ADRs | [api-rest-cadastros-thl](../adr/api-rest-cadastros-thl.md), [renumeracao-cadastros-depara](../adr/renumeracao-cadastros-depara.md), [separacao-core-extensoes](../adr/separacao-core-extensoes.md) |

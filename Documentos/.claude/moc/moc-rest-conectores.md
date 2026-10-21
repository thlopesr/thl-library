---
tipo: guia
camada: core
status: vigente
tags: [moc, rest, conectores, autenticacao]
updated: 2026-10-21
---

# MOC — REST e conectores

Mapa de navegação: só aponta. Voltar a [moc-geral.md](moc-geral.md).

| O quê | Onde |
|---|---|
| Pacote | [integration/connectors.md](../integration/connectors.md) |
| Contratos | [IntegrationConnector](../arquitetura/IntegrationConnector.md), [ITokenProvider](../arquitetura/ITokenProvider.md), [IHeaderProvider](../arquitetura/IHeaderProvider.md) |
| Fluxo de saída (variável → conexão/path, autenticação) | [fluxos/fluxo-saida.md](../fluxos/fluxo-saida.md) |
| Tabelas | `thl-conexao-rest`, `thl-conexao-rest-path`, `thl-conexao-rest-autenticacao`, `thl-conexao-rest-header` — [data/schema.md](../data/schema.md) |
| Telas Datasul | `thl0030` (conexão), `thl0031` (path), `thl0032` (autenticação), `thl0033` (header) — [thl/camada-datasul.md](../thl/camada-datasul.md) |
| Dicionário de campos das telas | [thl003-conexao-rest.md](../thl/cadastros/thl003-conexao-rest.md): [thl0030](../thl/cadastros/thl0030-conexoes-rest.md), [thl0031](../thl/cadastros/thl0031-paths-conexao.md), [thl0032](../thl/cadastros/thl0032-autenticacao-conexao.md), [thl0033](../thl/cadastros/thl0033-header-provider-conexao.md) |
| Serviços REST (extensão `thl`) | `ConexaoRestService`, `ConexaoRestPathService`, `ConexaoRestAutenticacaoService`, `ConexaoRestHeaderService` — [extensions/thl.md](../extensions/thl.md); Postman: pastas `Conexao REST` e `Conexao REST Path` |
| Providers por sistema | `TokenProvider` em [mmcm](../extensions/mmcm.md); `HeaderProvider` em [gestaoepi](../extensions/gestaoepi.md) |
| Cuidado | providers são carregados por `dynamic-new` com o nome gravado no cadastro; mover ou renomear exige atualizar o cadastro — [separacao-core-extensoes](../adr/separacao-core-extensoes.md) |

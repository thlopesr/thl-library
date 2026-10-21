---
tipo: guia
camada: ambos
status: vigente
tags: [moc, navegacao]
updated: 2026-10-19
---

# MOC — Mapa geral

Entrada de navegação do Obsidian. Estrutura apenas; o conteúdo vive nas notas. O ponto de partida dos agentes continua sendo o [INDEX.md](../INDEX.md).

## Mapas por módulo

- [Ambiente e parâmetros](moc-ambiente.md)
- [E-mail](moc-email.md)
- [Mensageria](moc-mensageria.md)
- [REST e conectores](moc-rest-conectores.md)
- [Auditoria](moc-auditoria.md)
- [Jobs RPW](moc-jobs-rpw.md)

## Transversais

[Convenções](../convencoes.md) · [Arquitetura](../arquitetura.md) · [Schema](../data/schema.md) · [Camada Datasul](../thl/camada-datasul.md) · [App web](../web/app-web.md) · [Registro de dívida](../tech-debt/REGISTRO.md) · [Changelog](../CHANGELOG.md) · [Mapa Notion](../notion-map.md)

## Vocabulário do frontmatter

| Campo | Valores |
|---|---|
| `tipo` | `modulo` · `classe` · `tabela` · `adr` · `guia` |
| `camada` | `core` (`thl-lib`) · `extension` (`thl-extensions`) · `ambos` (nota que atravessa as duas) |
| `status` | `vigente` · `referencia` (material externo) · `historico` (changelog) · `backlog`; ADRs usam `aceita`, `proposta`, `substituída`, `descartada` |
| `tags` | assunto e sistema, em minúsculas |

Links entre classe, tabela, serviço REST e ADR são **links Markdown relativos** (o Obsidian os resolve); wikilinks não são usados, por regra do `AGENTS.md`.

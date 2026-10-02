# Documentos — THL-Library

Organização por **público**:

| Pasta | Público | Conteúdo |
|---|---|---|
| `.claude\` | **agentes e desenvolvedores** (Claude, Codex e navegação pelo Obsidian) | Base de conhecimento viva, com entrada por `INDEX.md`. Deve refletir o código atual de `Fontes\` |
| `negocio\` | usuário funcional | FAQ e guias de cadastro/monitoramento |
| `tecnico\` | desenvolvedor | Guias de uso da biblioteca (conectores, inbound/outbound, reprocessamento, ambiente) |
| `pesquisa\` | referência | Pesquisas brutas que alimentaram a base (PO UI, rodadas 1–4) |
| `relatorios\qa\` | histórico | Relatórios de auditoria QA e prompts de correção, em subpastas datadas (`AAAA-MM-…`). Não são atualizados |
| `arquivo\` | histórico | Material superado, mantido só para consulta (`ia-2026-05\`: docs "para IAs" anteriores à `.claude\`; `thl-lib-core-environment-arquitetura.md`: versão 2025 do módulo environment — a atual é `.claude\core\environment.md`) |

Regras:
- **Padrão de codificação do projeto: ISO-8859-1** para os fontes ABL (detalhes em `.claude\convencoes.md`).
- Conhecimento que os agentes devem seguir vai **só** para `.claude\`.
- Relatórios pontuais vão para `relatorios\`, nunca para `.claude\`.
- Nomes de arquivo em minúsculas, kebab-case, sem espaços nem acentos; histórico com prefixo de data.

## Autoridade do conteúdo

Convenções e ADRs aceitas registram regras e decisões. Notas de pacote descrevem o código atual; propostas e backlog não autorizam mudanças. Pesquisas, relatórios e arquivo são referências históricas. Consulte o [índice compartilhado](.claude/INDEX.md) e o [histórico documental](.claude/CHANGELOG.md).

---
tipo: guia
camada: ambos
status: vigente
tags: [notion, publicacao]
updated: 2026-10-19
---

# Mapa de publicação no Notion

Relaciona cada nota publicada no Notion à sua página. A fonte de verdade continua sendo a nota no repositório; a página do Notion é derivada e leva no rodapé `Fonte: <caminho> — <data>`. Só entram aqui páginas já criadas; a skill [thl-docs](../../.claude/skills/thl-docs/SKILL.md) atualiza apenas as notas mapeadas.

| Nota (link relativo) | Página Notion (id/URL) | Observação |
|---|---|---|
| [funcionalidades-thl.md](../negocio/funcionalidades-thl.md) | https://app.notion.com/p/400d3a2b48158145a8f9d772d649f593 | Índice. Espaço Informações THL, página "THL-Library — Funcionalidades". Criada em 21/10/2026 |
| [funcionalidade-utils.md](../negocio/funcionalidade-utils.md) | https://app.notion.com/p/400d3a2b481581848467f6f77ff3b9bd | Subpágina do índice |
| [funcionalidade-integracao.md](../negocio/funcionalidade-integracao.md) | https://app.notion.com/p/400d3a2b481581d298eef16af727b205 | Subpágina do índice |
| [funcionalidade-email.md](../negocio/funcionalidade-email.md) | https://app.notion.com/p/400d3a2b48158194a4f3cae9ae320600 | Subpágina do índice |
| [funcionalidade-variavel-ambiente.md](../negocio/funcionalidade-variavel-ambiente.md) | https://app.notion.com/p/400d3a2b481581fab4f8f4aaa0b30f91 | Subpágina do índice |
| [funcionalidade-auditoria.md](../negocio/funcionalidade-auditoria.md) | https://app.notion.com/p/400d3a2b481581e0a118d1b6d20f9758 | Subpágina do índice |

As páginas "THL-Library — Parte Web" e "THL-Library — Como funciona", do mesmo espaço, já existiam (09/10/2026), foram escritas fora desta skill e **não estão mapeadas**: não atualizar sem decisão do usuário.

## Páginas do Notion que não são publicação

As páginas citadas no campo `notion:` do frontmatter das notas `thl0030` a `thl0033` (em [thl/cadastros/](thl/cadastros/cadastros-thl.md)) pertencem ao banco **Testes de telas .w — Cadastros THL**: são checklists de teste (status, prioridade e roteiro), conferidas em 21/10/2026. **Não eram cópias das notas.** O banco foi apagado a pedido do usuário em 21/10/2026 (o Notion o mostra na lixeira, e dá para restaurar de lá). Os links `notion:` das quatro notas apontavam para essas páginas e foram removidos.

## Candidatas a publicação

Ainda não criadas no Notion nem mapeadas; ids ficam em branco até a decisão de publicar.

### Guias para usuário e operação (`Documentos/negocio/`)

- [faq-biblioteca-thl.md](../negocio/faq-biblioteca-thl.md)
- [guia-cadastros-thl.md](../negocio/guia-cadastros-thl.md)
- [guia-monitoramento-comunicacao.md](../negocio/guia-monitoramento-comunicacao.md)
- [guia-monitoramento-mensageria.md](../negocio/guia-monitoramento-mensageria.md)
- [guia-operacional-biblioteca-thl.md](../negocio/guia-operacional-biblioteca-thl.md)
- [guia-telas-web.md](../negocio/guia-telas-web.md)

### Guias técnicos (`Documentos/tecnico/`)

- [guia-configuracao-conector-rest.md](../tecnico/guia-configuracao-conector-rest.md)
- [guia-criacao-integracao-inbound.md](../tecnico/guia-criacao-integracao-inbound.md)
- [guia-criacao-integracao-outbound.md](../tecnico/guia-criacao-integracao-outbound.md)
- [guia-monitoramento-tecnico.md](../tecnico/guia-monitoramento-tecnico.md)
- [guia-reprocessamento-mensagem.md](../tecnico/guia-reprocessamento-mensagem.md)
- [guia-tecnico-utilizacao-thl-lib.md](../tecnico/guia-tecnico-utilizacao-thl-lib.md)
- [guia-validador-endpoints.md](../tecnico/guia-validador-endpoints.md)

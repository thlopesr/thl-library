---
name: thl-docs
description: "Fechar uma tarefa da THL-Library atualizando a documentação — notas de Documentos/.claude (fonte de verdade e vault do Obsidian), guias, Notion, Postman e, com aprovação, skills afetadas. Use ao final de cada tarefa de uma sessão de tópico ou quando o usuário chamar /thl-docs."
---

# thl-docs — fechamento documental da THL-Library

Siga o `AGENTS.md` da raiz. Esta skill aplica, no fim de uma tarefa, a regra "Documentação (manter sincronizada)" do `AGENTS.md`; não a substitui. Divergências código × documentação encontradas em análise seguem o protocolo de sincronização do `thl-architect`; decisões arquiteturais seguem o `thl-adr`; dívida técnica segue o `thl-tech-debt`.

## Princípio

Há **uma fonte de verdade**: as notas em `Documentos/.claude/`, versionadas com o código. O resto é derivado.

| Destino | Papel | Como é atualizado |
|---|---|---|
| `Documentos/.claude/` | Fonte de verdade e vault do Obsidian | Editado por esta skill |
| Obsidian | Navegação | Nada a sincronizar: lê o mesmo vault. Manter links, frontmatter e MOCs válidos |
| `Documentos/negocio/` e `Documentos/tecnico/` | Guias para usuário e operação | Só quando a tarefa muda comportamento visível ao usuário ou ao operador |
| Notion | Publicação para quem não usa o repositório | Gerado a partir da nota, somente páginas mapeadas |
| Postman | Contrato REST executável | Só quando um endpoint muda |
| `.claude/skills/` | Instruções dos agentes | Proposta + aprovação explícita (passo 5) |

Nunca registrar no Notion ou no Postman informação que não esteja antes numa nota (exceto exemplos de request/response no Postman).

## Referências do repositório

```
KB            = Documentos/.claude/
INDEX         = Documentos/.claude/INDEX.md        (mapa + changelog no topo)
CHANGELOG     = Documentos/.claude/CHANGELOG.md    (histórico; status: historico)
CONVENCOES    = Documentos/.claude/convencoes.md
ADR           = Documentos/.claude/adr/
MOC           = Documentos/.claude/moc/            (moc-geral.md + um por módulo)
TECH_DEBT     = Documentos/.claude/tech-debt/REGISTRO.md
QA            = Documentos/relatorios/qa/
NOTION_MAP    = Documentos/.claude/notion-map.md   (nota → página Notion; se não existir, pular o Notion)
POSTMAN       = collection Nitro (workspace Lopesth) > TOTVS > Projeto > THL-Library > THL (uma subpasta por recurso, cenários como Examples)
SKILLS        = .claude/skills/<nome>/SKILL.md     (conteúdo mantido)
SKILLS_CODEX  = .agents/skills/<nome>/SKILL.md     (entrada Codex: só encaminha para SKILLS)
```

## Escopo por sessão

| Sessão | Código | Notas que pode editar |
|---|---|---|
| OpenEdge Backend | `Fontes/` thl-lib e thl-extensions | `core/`, `integration/`, `communication/`, `logging/`, `erp/`, `util/`, `data/`, `extensions/`, `fluxos/`, `arquitetura/<Classe>.md` |
| OpenEdge Front (Datasul) | `Fontes/thl` (`.w`, `.p`) | `thl/` |
| Web (PO UI) | `Fontes/web` | `web/`, `poui/` |

Qualquer sessão pode **acrescentar a linha de changelog** no topo do `INDEX` (regra do `AGENTS.md`).

Arquivos transversais — só **propor**, salvo pedido explícito do usuário: estrutura do `INDEX`, `convencoes.md`, `arquitetura.md`, `moc/moc-geral.md`, `AGENTS.md`, `CLAUDE.md`, ADRs (via `thl-adr`). Nota de outra sessão afetada pela tarefa → registrar como pendência para a sessão dona, não editar.

Antes de editar, consultar `git status` e preservar alterações locais fora da tarefa.

## Processo

### 1. Levantar o que mudou
- Identificar a sessão (tópico). Se não estiver claro, perguntar.
- `git status` e `git diff` dos arquivos da tarefa; separar o que é da tarefa do que já estava alterado.
- Ler o `INDEX` e abrir só as notas afetadas (index-first).

### 2. Classificar cada alteração

| Alteração | Destino |
|---|---|
| Comportamento, método, contrato de classe ou pacote | Nota do pacote na KB |
| Classe-base nova ou filha nova | Nota do pacote + `arquitetura.md` (propor) e `arquitetura/<Classe>.md` |
| Convenção nova ou alterada | Propor em `convencoes.md`; verificar skills (passo 5) |
| Decisão entre alternativas, com trade-off | `thl-adr` — não escrever ADR por conta própria |
| Contrato REST (rota, verbo, payload, erros, status) | Nota do pacote + Postman |
| Comportamento visível ao usuário ou ao operador | Guia em `negocio/` ou `tecnico/` |
| Divergência ou dívida encontrada e não corrigida | `TECH_DEBT` via `thl-tech-debt` (propor) |
| Achado de QA | `QA` |
| Sem impacto documental | Nada; citar no relatório que foi avaliada |

Se uma alteração não se encaixar, perguntar em vez de criar arquivo novo.

### 3. Atualizar as notas (fonte de verdade)
- Editar o trecho existente; a nota descreve o **estado atual**. Histórico fica no git, no `CHANGELOG` e nas ADRs.
- Corrigir ou remover afirmações que a tarefa tornou falsas.
- Separar implementação atual, decisão aceita, proposta e histórico (como o `AGENTS.md` pede).
- Declarar o nível de verificação do que foi documentado: "verificado com `<comando>`" ou "por leitura, sem compilação".
- Frontmatter, mantendo os valores em uso no vault:
  ```yaml
  ---
  tipo: guia | modulo | classe | tabela | adr
  camada: core | extension | ambos
  status: vigente | referencia | proposta | aceita | backlog | historico
  tags: [<modulo>, ...]
  updated: AAAA-MM-DD
  ---
  ```
  Atualizar `updated` em toda nota editada. Nota nova recebe o frontmatter completo.
- Links Markdown relativos (`[texto](../erp/erp-services.md)`), nunca `[[wikilinks]]`. Não editar `.obsidian/workspace*.json`.
- Nota nova: incluir no `INDEX` (propor a linha se mudar a estrutura) e no MOC do módulo em `moc/`.
- Relatórios vão para `Documentos/relatorios/`; material antigo para `Documentos/arquivo/`. Nada solto na raiz.

### 4. Changelog
- Uma entrada no topo do `INDEX`, no padrão existente: `**Atualização DD/MM/AAAA (<assunto>):** <o que mudou, uma ou duas frases> — ver [<nota>](<caminho>). <nível de verificação>.`
- Curta: o detalhe fica na nota, não no `INDEX`.
- Se o topo do `INDEX` acumular entradas de sessões anteriores além de uma tela, propor mover as mais antigas para o `CHANGELOG` (não mover sem aprovação).

### 5. Impacto nas skills
Skills são instruções de comportamento: um erro numa skill se repete em toda sessão futura. Esta skill **propõe**, não aplica.

- Verificar em `SKILLS` as skills que tratam do assunto alterado (nomenclatura e ABL → `thl-coding`; arquitetura e pacotes → `thl-architect`; critérios de revisão → `thl-qa`; Angular/PO UI → `thl-web-coding`, `thl-poui-design`, `thl-web-qa`).
- Para cada skill que agora contradiz a convenção ou deixou de cobrir um padrão novo, apresentar: skill e trecho atual, trecho proposto (diff) e motivo, apontando a nota ou ADR que justifica.
- Aplicar **somente após aprovação explícita**, uma skill por vez, alterando só o trecho aprovado.
- Preferir que a skill aponte para a nota em vez de duplicar a regra.
- Editar sempre o conteúdo em `SKILLS`. A entrada em `SKILLS_CODEX` só muda se `name` ou `description` mudarem — nesse caso, manter os dois frontmatters idênticos.
- Nunca alterar a própria `thl-docs` neste fluxo, nem criar skill nova (tarefa própria; skill nova também exige entrada em `SKILLS_CODEX` e linha na tabela de tarefas do `AGENTS.md`).

### 6. Notion
- Se `NOTION_MAP` não existir ou a ferramenta do Notion não estiver disponível, pular e registrar no relatório.
- Para cada nota editada presente no mapa: atualizar a página com o conteúdo da nota e, no rodapé, `Fonte: <caminho no repositório> — <data>`.
- Nota sem mapeamento: não criar página; listar como candidata a publicação.

### 7. Postman
Só se a tarefa alterou endpoint REST (rota, verbo, payload, erros ou status). A fonte é a collection **Nitro na nuvem**, lida e alterada pelo conector do Postman; não gerar nem exportar `.postman_collection.json` para o repositório.

1. **Ferramentas:** carregar as ferramentas do conector (`getEnabledTools`). Se voltar `serverType: minimal` ou o conector não existir na sessão, não criar nada: listar as alterações pendentes no relatório e, se for subpasta nova, pedir ao usuário que a crie vazia.
2. **Localizar:** `getCollection` da Nitro e navegar até `POSTMAN`, resolvendo os ids pelo nome (não fixar ids na skill). Conferir se a subpasta do recurso já existe.
3. **Recurso novo:** criar a **subpasta junto** (`createCollectionFolder`) e as requests dentro dela, nunca requests soltas na pasta `THL`. Padrão: `GET Lista`, `POST`, `PATCH`, `DELETE`, com rota `${url}/api/thl/integration/v1/resourcen/<rota>` e as variáveis de ambiente que a collection já usa.
4. **Recurso existente:** `updateCollectionRequest` só nos requests afetados; mover com `transferCollectionRequests`.
5. **Examples:** um por cenário (sucesso, validação, não encontrado, erro) com `createCollectionResponse` / `updateCollectionResponse`, usando dados fictícios.
6. **Descrição:** cada request aponta para a nota do contrato em `Documentos/.claude/`.
7. **Apagar:** pasta, request ou example só com confirmação explícita do usuário, item por item.
8. **Segredos:** a collection tem credenciais e hosts de cliente. Nunca copiar para o repositório, para notas ou para o relatório; usar variáveis, não valores.
9. **Verificação opcional:** o validador `Utils/scripts/validador-endpoints/` ([guia](../../../Documentos/tecnico/guia-validador-endpoints.md)) executa a pasta `THL`; ele grava dados de verdade, então só em ambiente de projeto/homologação e se o usuário pedir. Registrar no relatório se foi executado ou não.
10. No relatório, listar os requests e examples criados, alterados e pendentes.

### 8. Validar
- Links relativos das notas editadas apontam para arquivos existentes.
- Frontmatter válido e `updated` atualizado.
- Nada contradiz `convencoes.md`, ADRs aceitas ou outra nota do tópico.
- Nota nova está no `INDEX` e no MOC (ou proposta).
- Nenhum arquivo fora do escopo da sessão foi alterado.

### 9. Relatório final

```
## Documentação — <tarefa>
Sessão: <tópico>

Atualizados:
- <arquivo> — <o que mudou, uma linha>

Changelog: <linha incluída no INDEX>

Propostas (aguardando aprovação):
- <arquivo transversal ou de outra sessão> — <alteração sugerida>

ADR sugerida: <não | sim — assunto>
Dívida técnica: <não | sim — resumo>
Skills: <sem impacto | propostas pendentes | aplicadas após aprovação>
Notion: <atualizadas | pendentes | candidatas | sem mapa>
Postman: <atualizados | pendentes | sem alteração de API>
Avaliado sem impacto: <itens>
```

Não fazer commit (regra do `AGENTS.md`). As alterações ficam para o usuário revisar com o código.

## O que esta skill não faz
- Não decide arquitetura (vai para `thl-adr`).
- Não reescreve notas por estilo; só corrige o que a tarefa desatualizou.
- Não regenera a base inteira; sincronização é incremental.
- Não edita notas de outra sessão nem arquivos transversais sem aprovação.
- Não cria páginas no Notion sem mapeamento.
- Não altera skills sem aprovação explícita.

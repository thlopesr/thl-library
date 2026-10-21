---
name: "thl-adr"
description: "Criar ou avaliar ADRs (Architecture Decision Records) da THL-Library, mantendo o histórico de decisões em Documentos\\.claude\\adr\\."
---

# THL ADR

Registrar e avaliar decisões de arquitetura da THL-Library, formando o histórico oficial de decisões do projeto.

## Modos
- **Criar ADR**: "Devemos usar X ou Y para ...?"
- **Avaliar proposta**: revisar um design (vinda de análise da `thl-architect` ou de um pedido do usuário) contra os ADRs vigentes.
- **Retroativo**: registrar uma decisão já tomada e implementada que ainda não tem ADR.
- **Superseder**: substituir ADR antigo, mantendo o original com status Superseded e link para o novo.

## Passo 0 — Contexto obrigatório
1. `Documentos\.claude\INDEX.md`.
2. Listar `Documentos\.claude\adr\` e ler os ADRs afins: os arquivos usam **slug sem número** (ex.: `inbound-message-processor-service.md`). Checar conflito, sobreposição e ADRs parcialmente substituídos antes de criar outro.
3. Ler código relevante em `Fontes\` se a decisão afeta implementação existente.

## Decisões históricas candidatas a ADR retroativo
Antes de propor, confirme em `Documentos\.claude\adr\` quais já estão cobertas (ex.: front-end web, API REST dos cadastros). Para as que faltam, propor registrá-las (status aceita):
1. Separação thl-lib (core) × thl-extensions (cliente).
2. Mensageria em subpacotes inbound/outbound com nomenclatura `<Domínio><Padrão>.cls`; remoção do sufixo `Message` redundante em extensões.
3. Auditoria: AuditLogService nunca propaga exceção em trigger.
4. Auditoria: notificação assíncrona via RPW.
5. Níveis de sensibilidade/acesso espaçados (1/5/9).
6. Diffs de auditoria em JSON com serialização manual via JsonObject (serialização direta de buffer descartada).
7. Acesso dinâmico via handle (BUFFER-FIELD/BUFFER-VALUE) em vez de cast para buffer tipado.
8. Encoding padrão ISO-8859-1 / CRLF.
9. Numeração de programas por dezena por grupo de cadastro.
10. Padrão de tela de cadastro baseado em thl0005.
11. Modernização de telas com PO-UI (stack PO-UI 21 / Angular 21 / TS 5.9 / @totvs/po-theme), front-end separado do back-end Progress.
12. Service REST padronizado (GET/POST/PATCH/DELETE) por cadastro, documentado no Postman.
13. Testes em Utils\test\, exemplos em Utils\example\.
14. KB versionada em Documentos\.claude\ junto ao código, consulta index-first.

## Dimensões de avaliação específicas THL
Além de complexidade e custo, avaliar sempre:
- **Impacto core × extensões** (quantos clientes afeta).
- **Runtime PASOE** (estado, sessão de agente, ciclo de vida de objetos).
- **Transação ERP / triggers** (risco de rollback ou lock no Datasul).
- **Oracle** (volume, índices, schema change).
- **Compatibilidade OpenEdge 12** e padrão framework TOTVS.
- **Familiaridade da equipe ABL** e esforço de manutenção.

## Formato
```markdown
---
tipo: adr
modulo: <erp|integration|web|database|util|thl>
status: proposta | aceita | substituída | descartada
updated: AAAA-MM-DD
---

# ADR — [Título]

**Decisores:** [quem aprova]
**Escopo:** thl-lib | thl-extensions | ambos | front-end PO-UI
**Relacionados:** [outro-adr.md](outro-adr.md), TD-NNN, notas de pacote afetadas (links Markdown relativos)

## Contexto
[Situação, forças, histórico que levou à decisão]

## Decisão
[O que foi decidido]

## Opções consideradas
### Opção A: [Nome]
| Dimensão | Avaliação |
|---|---|
| Complexidade | |
| Impacto core × extensões | |
| Runtime PASOE | |
| Transação/triggers | |
| Oracle | |
| Familiaridade equipe | |

**Prós:** / **Contras:**

### Opção B: [Nome]
[mesmo formato]

## Análise de trade-offs

## Consequências
- O que fica mais fácil
- O que fica mais difícil
- O que revisitar

## Ações
1. [ ] Implementação → /thl-coding (ABL) ou /thl-web-coding (Angular/PO UI)
2. [ ] Validação → /thl-qa (ABL) ou /thl-web-qa (web)
3. [ ] Atualizar INDEX.md e .md afetados → /thl-architect
```

## Saída
- Arquivo `Documentos\.claude\adr\<slug>.md` em UTF-8 com LF (`.md` não segue a regra ISO-8859-1/CRLF do ABL). Links Markdown relativos, nunca `[[wikilinks]]`.
- Registrar a linha do ADR na tabela de `Documentos\.claude\INDEX.md` (seção de ADRs) e uma linha de changelog no topo. Não existe `adr\INDEX.md`.
- Se superseder, no ADR antigo altere só o `status` do frontmatter e acrescente o aviso `> ⚠️` com link para o novo, como em `get-no-execute-do-service.md`.
- Proposta não autoriza implementação: informe se o ADR é proposta ou aceita, e que aprovação não comprova implantação.

---
tipo: adr
modulo: database
status: proposta
updated: 2026-10-13
camada: ambos
tags: [adr, database]
---

# ADR — Níveis de sensibilidade e de acesso da auditoria (1 / 5 / 9)

**Decisores:** Thiago Lopes (responsável pelo projeto)
**Escopo:** thl-lib e front-end PO-UI
**Relacionados:** [../logging/auditoria.md](../logging/auditoria.md), [../data/schema.md](../data/schema.md), [../web/motor-cadastro.md](../web/motor-cadastro.md), [auditoria-desempenho-trigger.md](auditoria-desempenho-trigger.md)

> ADR **retroativa e proposta**: o valor numérico 5/9 tem **duas definições conflitantes** no repositório. Não foi marcada como aceita porque a decisão depende de você. Nenhum código foi alterado.

## Contexto

A auditoria usa um nível numérico em quatro pontos: `thl-audit-tabela.nivel-sensibilidade`, `thl-audit-tabela-campo.nivel-sensibilidade`, `thl-audit-tabela-notificacao.nivel-sensibilidade` e o nível de acesso do usuário (`thl-audit-tabela-acesso`). A regra de visibilidade: o usuário só vê o que tem sensibilidade menor ou igual ao seu nível de acesso. Os valores são **espaçados (1, 5, 9)** para permitir níveis intermediários sem renumerar.

## Divergência medida (2026-10-13)

| Fonte | 5 | 9 |
|---|---|---|
| `Database\Definition\thl.df` (descrição dos campos) | Restrito | Crítico |
| `Fontes\thl\include\i01thl026.i` (telas) | Crítico | Restrito |
| `Fontes\web\src\app\cadastros\cadastros.defs.ts` e `auditoria-metricas.component.ts` | Crítico | Restrito |
| [../web/motor-cadastro.md](../web/motor-cadastro.md) | Crítico | Restrito |

O código (telas e web) concorda entre si; só o `.df` difere. Pela regra "o código vence", o comportamento atual é **5 = Crítico, 9 = Restrito**. A intenção de negócio (qual dos dois rótulos é o mais grave) não está registrada em nenhum fonte e precisa de confirmação.

## Decisão proposta

1. Valores: `1` Normal, `5` e `9` espaçados.
2. Rótulos: **você decide** entre (a) manter o código — 5 = Crítico, 9 = Restrito — e corrigir a descrição do `.df` pelo Data Dictionary, ou (b) adotar o `.df` — 5 = Restrito, 9 = Crítico — e alterar `i01thl026.i`, `cadastros.defs.ts`, `auditoria-metricas.component.ts` e as notas.
3. Padrão da regra de visibilidade (`<=`) mantido.

## Opções consideradas

| Opção | Impacto |
|---|---|
| (a) manter o código | Muda só a descrição do `.df` (arquivo gerado pelo responsável); sem recompilar telas nem web |
| (b) adotar o `.df` | Altera tela, web, notas e possivelmente dados já gravados (a semântica dos valores 5 e 9 inverte) |

## Consequências

- Fica mais fácil: rótulos iguais em banco, tela, web e documentação.
- Fica mais difícil: se a opção (b) for escolhida, dados e telas mudam de significado.
- Revisitar: o `.df` é gerado pelo Data Dictionary e não é editado à mão.

## Ações

1. [ ] **Decisão do responsável** sobre (a) ou (b) — `> [!todo]`.
2. [ ] Implementação → `/thl-coding` (ABL) ou `/thl-web-coding` (web).
3. [ ] Atualizar [../data/schema.md](../data/schema.md) e [../INDEX.md](../INDEX.md) (a divergência já está marcada como ⚠️ no INDEX).

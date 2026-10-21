---
tipo: adr
modulo: auditoria
status: proposta
updated: 2026-10-02
camada: ambos
tags: [adr, auditoria]
---

# ADR — Desempenho da gravação de auditoria na trigger

> **Proposta em 2026-10-02 — nada implementado.** Baseada em leitura do código; nenhum tempo foi medido.
>
> Contexto: [logging/auditoria.md](../logging/auditoria.md) · classes: [logging/logging.md](../logging/logging.md), [util/util.md](../util/util.md) · tabelas e índices: [data/schema.md](../data/schema.md) · expurgo: [thl/camada-datasul.md](../thl/camada-datasul.md)

## 1. Contexto

A auditoria é gravada por triggers WRITE/DELETE das tabelas do ERP, que chamam `thl-lib.logging.audit.AuditLogService`. Tudo roda dentro da transação do usuário. Hoje, a cada registro gravado, o serviço relê o cadastro da tabela, refaz o parse da chave e recria a temp-table de serialização (duas vezes na alteração).

Requisitos do responsável (2026-10-01):

- A trigger não pode onerar o ERP: **desempenho é o critério**.
- A trigger continua simples: `buffer-compare` + uma chamada, recebendo **buffer**.
- O JSON continua sendo gerado pelo método da linguagem (`write-json`).
- Tamanho da tabela de registros não é preocupação: o snapshot segue sendo o registro inteiro, e o expurgo (thl0250) controla o crescimento.

## 2. Decisões propostas

| # | Decisão | Onde | Muda o que é gravado? |
|---|---|---|---|
| P1 | Cadastro da tabela auditada em memória por sessão (temp-table estática), incluindo o resultado "não auditada", com validade de alguns minutos | `AuditLogService` | não |
| P2 | Campos de `pk` e campos monitorados já interpretados, no mesmo cache | `AuditLogService` | não |
| P3 | Temp-table de serialização preparada uma vez por tabela e reaproveitada | `JsonWriter` ou `AuditLogService` | não |
| P4 | `JsonWriter:toJsonFromBuffer` respeita `prettyPrint`; a auditoria grava sem formatação | `JsonWriter` | mesmo JSON, sem espaços |
| P5 | Remover o índice `idx-audit-data` (sem consulta no repositório) | `.df`, pelo Data Dictionary | não |
| P6 | Os dois snapshots da alteração em um único detalhe | `AuditLogService` + leitores | **sim** — só com medição |

Fora do desempenho, mas a corrigir na mesma passada do `AuditLogService`: inclusão gravada como alteração (`writeChange`), ausência de `block-level on error undo, throw` e `matches` no lugar de `lookup`.

## 3. Restrições

- **Formato do snapshot:** `{"<tabela>":[{…}]}` é lido por `thl0150.w` (`read-json`) e por `AuditoriaService`. P1 a P5 não o alteram.
- **PASOE:** a sessão é reaproveitada entre usuários. O usuário Datasul não entra no cache de sessão.
- **Validade do cache:** mudança no cadastro (thl0050/thl0051 ou API) só vale nos agentes ativos depois de vencer a validade.
- **Handles estáticos:** vivem enquanto a sessão viver; mudança de schema da tabela auditada exige reiniciar os agentes.
- **Contrato:** `writeChange` e `deleteRecord` não têm chamadores no repositório, mas a assinatura é mantida para não mexer nas triggers já instaladas em clientes.

## 4. Alternativas descartadas

| Alternativa | Motivo |
|---|---|
| Gravar só os campos alterados | O responsável prefere o registro inteiro; tamanho não é o problema |
| Gravação assíncrona (trigger grava bruto, RPW converte) | Exige tabela intermediária, job e atraso na consulta; só se a medição mostrar que P1–P5 não bastam |
| Trigger gerada a partir do cadastro | Cada mudança de cadastro exigiria regerar e recompilar |
| `buffer:serialize-row()` direto no buffer de banco | Não confirmado para buffer de banco, e o formato de saída é diferente |

## 5. Como validar

Laço de alguns milhares de alterações com `etime`, em três situações — sem trigger, com trigger e tabela não auditada, com auditoria ativa —, antes e depois. Compilação no PDSOE ou com `Utils/scripts/compilar-thl.p`.

## 6. Em aberto

1. Aceitar P1–P4 e passar para a skill `thl-coding`.
2. P5: remover `idx-audit-data` do `.df`.
3. Tempo de validade do cache.
4. Prefixo `sh`: normalizar em um ponto único (hoje repetido em quatro lugares e ausente no `thl0250rp.p`).

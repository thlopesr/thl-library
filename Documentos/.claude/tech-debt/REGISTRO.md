---
tipo: guia
camada: core
status: ativo
tags: [divida-tecnica, registro]
updated: 2026-10-13
---

# Registro de dívida técnica — THL-Library

Histórico vivo da dívida (criado em 2026-10-13 pela Fase 0 da atualização documental). Notas **por leitura estática**; nada foi compilado ou executado. Pontuação (estimada): **(Impacto + Risco) × (6 − Esforço) × raio**, com raio 1,5 para o core e 1 para extensão (regra da skill `thl-tech-debt`).

## Itens abertos

| ID | Categoria | Local | Descrição | I | R | E | Raio | Pont. | Executa |
|---|---|---|---|---|---|---|---|---|---|
| TD-001 | Arquitetura / Runtime | `thl-extensions/integration/thl/.../MetricsProcessor.cls`, cargas `Database/Data/**/thl010.d` e `thl011.d`, `Utils/scripts/acerto-thl-*.p` | Os cadastros gravam `thl-lib.integration.messaging.inbound.process.MetricsProcessor`; a classe está em `thl-extensions` (e `IMetricsService` idem, não em `thl-lib.erp.interfaces`). Com o nome do banco, o `dynamic-new` falha e `<rota>/metricas` não responde. Ver [messaging-inbound.md](../integration/messaging-inbound.md) | 4 | 5 | 1 | ext. | 45 | `/thl-coding` (+ `/thl-adr` se mover a classe) |
| TD-002 | Código / Trigger | `thl-lib/logging/audit/AuditLogService.cls` | D1 (inclusão gravada como alteração), D4 (sem `block-level on error undo, throw`), D5 (`matches` casa campo parcial). Código em trigger, dentro da transação do ERP. Ver [auditoria.md](../logging/auditoria.md) | 4 | 4 | 2 | core | 48 | `/thl-coding`, `/thl-qa` |
| TD-003 | Arquitetura / Doc | `Database/Definition/thl.df` × telas × web | 5/9 de sensibilidade com rótulos invertidos; decisão pendente na [ADR proposta](../adr/niveis-sensibilidade-auditoria.md) | 3 | 4 | 2 | core | 42 | decisão do responsável; depois `/thl-coding` |
| TD-004 | Código | `Fontes/thl/thl0250rp.p` | D2 (expurgo compara banco sem o prefixo `sh`) e D3 (grava `dt-ultima-execucao` com `no-lock`): pela leitura, o expurgo da auditoria não apaga nada | 4 | 3 | 1 | ext. | 35 | `/thl-coding` |
| TD-005 | Teste | `Utils/test/` | Só `testProcessoExportacao.p`; nenhum teste de mensageria inbound/outbound, conectores, ambiente ou Services | 4 | 4 | 4 | core | 24 | `/thl-qa` |
| TD-006 | Teste / Doc | `Utils/example/` | Exemplos só para auditoria, e-mail e `util`; sem exemplo de mensageria, conectores, ambiente, Services ERP | 3 | 2 | 3 | core | 22,5 | `/thl-coding` |
| TD-007 | Código | `Utils/example/exampleEmail.p` | Usa `EmailSerivce`, classe renomeada para `EmailService`: exemplo não compila | 2 | 1 | 1 | core | 22,5 | `/thl-coding` |
| TD-008 | Infraestrutura | 19 em `thl-lib`, 4 em `thl-extensions`, 3 em `Utils` | Fontes ABL ainda em UTF-8 (convenção: ISO-8859-1). Contagem por leitura de bytes em 2026-10-13. Ver [ADR](../adr/codificacao-iso-8859-1-crlf.md) | 2 | 3 | 3 | core | 22,5 | `/thl-coding` |
| TD-009 | Código | `Fontes/thl/thl0120c.w`, `thl0120b.w:493` | Cabeçalho com o placeholder do template (`XX9999 9.99.99.999`) e `run thl\thl0120c.w` com `\` no caminho | 2 | 2 | 1 | ext. | 20 | `/thl-coding` |
| TD-010 | Arquitetura | `thl-audit-tabela-notificacao`, `thl-audit-registro-notificar` | Cadastro, API e tela existem, mas nenhum código lê `grupo-email` nem grava a fila de notificação. Item de roadmap (jobs RPW) | 3 | 3 | 4 | core | 18 | `/thl-adr` → `/thl-system-design` |

## Itens resolvidos

| ID | Item | Resolução |
|---|---|---|
| TD-R01 | `INDEX.md` com contagens incompatíveis (144 no cabeçalho, 153 na tabela) | Corrigido em 2026-10-13: 145 classes (94 `thl-lib` + 51 `thl-extensions`) |
| TD-R02 | Referências de linha do `AuditLogService` na nota de auditoria | Atualizadas em 2026-10-13 (`:43-52`, `:171`, `:209`) |

## Observações

- **Falso positivo descartado:** `AuditoriaTabelaCampoService`, `…ExpurgoService` e `…NotificacaoService` não estão sem nota; estão na tabela de [extensions/thl.md](../extensions/thl.md) (nome sem o sufixo `Service`). `thl0002a`, `thl0011a` e `thl0110a` são cobertos por "(+a/b/c)" nas notas de tela.
- A lacuna real de tela era `thl0120c`, agora em [thl/camada-datasul.md](../thl/camada-datasul.md).

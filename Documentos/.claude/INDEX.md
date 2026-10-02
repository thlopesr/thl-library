# THL-Library — Índice de documentação compartilhada

**Última sincronização:** 02/10/2026, por inventário e leitura estática. Nenhuma compilação ou validação de implantação nesta revisão.

**Atualização 02/10/2026:** lote 3 concluído; referências e contagens sincronizadas, limitação inbound agendada registrada. Histórico completo em [CHANGELOG.md](CHANGELOG.md).

## Como consultar

Comece por [convencoes.md](convencoes.md) e [arquitetura.md](arquitetura.md); abra apenas a nota do pacote pertinente. Confirme assinaturas e comportamento no código quando a precisão importar.

| Conteúdo | Autoridade e uso |
|---|---|
| Convenções e ADR aceita | Regra ou decisão aprovada; aprovação não comprova implantação |
| Nota de pacote | Descrição atual, confirmável no código |
| ADR proposta e backlog | Alternativa ou planejamento; não autoriza implementação |
| Catálogo PO UI e pesquisa | Referência externa; priorize decisões do projeto e confirme versão |
| Changelog, relatórios e arquivo | Evidência histórica; não define comportamento atual |

## Mapa de documentos

| Arquivo | Descrição |
|---|---|
| [convencoes.md](convencoes.md) | **Convenções do projeto** — codificação **ISO-8859-1**, pacote = pasta em minúsculas, onde colocar o código, nomes |
| **Núcleo (`thl-lib`)** | |
| [core/context.md](core/context.md) | `ContextService` — usuário do SO, usuário Datasul (`getErpUser` via `thl/api/geterpuser.p`) e call stack |
| [core/environment.md](core/environment.md) | `EnvironmentUtil`, `EnvironmentContext`, `EnvironmentResource` (Facade), `EnvironmentRepository` — ambiente e parâmetros |
| [core/error.md](core/error.md) | `ThlError` (formata `msg [Classe.metodo]`) e `ErrorHandler` (acumulação e conversão de erros) |
| [erp/erp-services.md](erp/erp-services.md) | **Contrato Message↔Service** (`Service` abstrata — não há interface), bases `BusinessObject`/`ApplicationProgrammingInterface`, `ServiceResponse`, enums e os 14 Services de `thl-lib.erp.service` (transacionais e de consulta) |
| [integration/connectors.md](integration/connectors.md) | Conectores REST: config, request/response, `RestConnector`, factories, `ITokenProvider`, `IHeaderProvider` |
| [integration/messaging-core.md](integration/messaging-core.md) | `Message`, `MessageConfig`, enums Direction/ExecutionMode/Status, `MessageFactory`, `MessageConfigLoader`, `MessageRepository` |
| [integration/messaging-outbound.md](integration/messaging-outbound.md) | `OutboundMessage`, `OutboundObjectContext`, estratégias Single/Multiple, `MessageExecutionService`, `OutboundMessageService`, `SchedulingService` |
| [integration/messaging-inbound.md](integration/messaging-inbound.md) | **Fluxo REST completo** (`resourcen.p` → `InboundRouteResolver` → `InboundMessageService` → `InboundMessage` → `Service`) e as 9 mensagens inbound de `thl-lib` |
| [communication/email.md](communication/email.md) | `EmailMessageFactory`, `EmailService` (utapi019), `EmailLogger`, `EmailParamRepository` |
| [logging/logging.md](logging/logging.md) | `LogUtil` (log-manager) e `AuditLogService` (tabelas `thl-audit-*`) |
| [logging/auditoria.md](logging/auditoria.md) | **Módulo de auditoria de ponta a ponta**: gravação pela trigger, consulta, cadastros, expurgo, achados e plano de desempenho |
| [util/util.md](util/util.md) | `StringUtil`, `JsonSetter`, `JsonWriter`, `FileUtil`, `PaginationHelper`, `SchemaUtil`, `JsonArrayCsvExporter`, scanner (4) e compile (3) |
| **Extensões (`thl-extensions\{erp,integration}\<sistema>\`)** | |
| [extensions/thl.md](extensions/thl.md) | API REST dos cadastros e consultas do próprio THL: um Service por tabela, **uma Message por agregado** (pai + filhos, escolha por rota), rotas, carga `.p` e script pelos endpoints |
| [extensions/automatizador.md](extensions/automatizador.md) | `LpcoMessage` outbound e inbound, `LpcoService` (`nit-lpco`) |
| [extensions/dvv.md](extensions/dvv.md) | `FreteMessage` inbound, `FretePrevistoService` (`nit-frete-prev`), `SituacaoFreteEnum` |
| [extensions/gestaoepi.md](extensions/gestaoepi.md) | `HeaderProvider` (HMAC-SHA256), `RequisicaoMessage`, `ItemRequisicaoMessage` |
| [extensions/iacompras.md](extensions/iacompras.md) | `ProcessoCompraMessage` (processo de compra, fornecedores, ordens) |
| [extensions/loogai.md](extensions/loogai.md) | `EntregaPedidoMessage`, `NotaFiscalMessage`, `StatusDocumento` (outbound); `LoogAiDocumentoMessage`/`Service`, `LoogAiEmbarqueMessage`/`Service` (inbound) |
| [extensions/mmcm.md](extensions/mmcm.md) | `TokenProvider` (parser `data.data.token`), `PrePedidoMessage`, `PedidoMessage` |
| [extensions/ninahub.md](extensions/ninahub.md) | `ChamadoMessage` (outbound), `NinahubNotaFiscalMessage`/`Service` (inbound NF) |
| [extensions/powerautomate.md](extensions/powerautomate.md) | `SolicitacaoCompraMessage` (ordem de compra / solicitação), `OrderStatusEnum`, `RequestStatusEnum` |
| **Dados, camada Datasul e web** | |
| [data/schema.md](data/schema.md) | Tabelas `thl-*` por domínio, relações, domínios de códigos e divergências `.df` × código |
| [data/er-diagrama.md](data/er-diagrama.md) | Diagrama (Mermaid) dos vínculos entre as 30 tabelas THL — contínua = `fk-*`, tracejada = só código/valor; gerado por `Utils/scripts/gerar-er-diagrama.py` |
| [thl/camada-datasul.md](thl/camada-datasul.md) | Telas `thlNNNN`, monitores, RPWs (`thl0220rp`/`thl0221rp`/`thl0222rp`), `thl0220z.p`, `geterpuser.p`, endpoint `resourcen.p`, includes |
| [web/app-web.md](web/app-web.md) | App Angular + PO UI: rotas, serviços, endpoints `resourcen`, componentes `thl-*`, build/deploy |
| [web/motor-cadastro.md](web/motor-cadastro.md) | Contrato do motor genérico de cadastros: `CrudResource`/`CrudField`, regras, decisões de layout e cor, cadastros em uso, domínios, pendências da v2 |
| [web/poui-licoes.md](web/poui-licoes.md) | Armadilhas do PO UI 21 confirmadas rodando (o que o componente **não** faz) |
| [poui/INDEX.md](poui/INDEX.md) | KB de referência PO UI 21 (15 notas) para gerar telas web |
| **Decisões e planejamento (consulte o status)** | |
| [adr/api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) | ADR aceita: API REST e uma Message por agregado, um Service por tabela |
| [adr/arquitetura-front-end-web.md](adr/arquitetura-front-end-web.md) | ADR (aceita e aplicada, 2026-10-02): dois apps separados, cadastro como definição do motor, standalone por feature, mock por `fileReplacements` — com alternativas descartadas e pontos em aberto |
| [adr/auditoria-desempenho-trigger.md](adr/auditoria-desempenho-trigger.md) | ADR (**proposta**, 2026-10-02): desempenho da gravação de auditoria na trigger — cache por sessão, temp-table reaproveitada, restrições de PASOE e formato do snapshot |
| [adr/renumeracao-cadastros-depara.md](adr/renumeracao-cadastros-depara.md) | ADR (aceita e executada, 2026-09-25): DE-PARA da renumeração dos cadastros `thl0xxx`, conflitos de número, ordem de migração e referências por programa |
| [refactoring/backlog-inbound-erp.md](refactoring/backlog-inbound-erp.md) | Backlog inbound × ERP (2026-07-25) — nomes das Fases 0–2 superados; decisões abertas 2.6, 3.7, 4.9, 4.10; item 0.4 reaberto |

---

## Distribuição por pacote

Contagem em 02/10/2026: **160 classes = 96 em `thl-lib` + 64 em `thl-extensions`**. Inclui interfaces e enums em arquivos `.cls`; exclui worktrees e gerados.

| Pacote | Arquivos `.cls` |
|---|---:|
| `thl-lib.communication` | 4 |
| `thl-lib.core` | 7 |
| `thl-lib.erp` | 21 |
| `thl-lib.integration` | 45 |
| `thl-lib.logging` | 4 |
| `thl-lib.util` | 15 |
| `thl-extensions — automatizador` | 3 |
| `thl-extensions — dvv` | 3 |
| `thl-extensions — gestaoepi` | 3 |
| `thl-extensions — iacompras` | 1 |
| `thl-extensions — loogai` | 7 |
| `thl-extensions — mmcm` | 3 |
| `thl-extensions — ninahub` | 3 |
| `thl-extensions — powerautomate` | 3 |
| `thl-extensions — thl` | 38 |
| **Total** | **160** |

## Limitação funcional a validar

O contexto inbound agendado não restaura rota, query nem path parameters: veja [messaging-inbound.md](integration/messaging-inbound.md#limitação-do-contexto-agendado). Messages que escolhem Service pela rota exigem análise antes de habilitar SCHEDULE.

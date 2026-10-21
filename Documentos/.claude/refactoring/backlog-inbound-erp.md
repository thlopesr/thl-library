---
tipo: guia
camada: core
status: backlog
tags: [backlog, mensageria, erp]
updated: 2026-10-13
---

# Backlog de Refatoração — Mensageria Inbound × Serviços ERP

**Origem:** análise thl-architect de 2026-07-25 (sessão 2) sobre `thl-lib/integration/messaging/inbound/message` e `thl-lib/erp/service`.
**Escopo:** TODOS os pontos identificados, sem exceção de complexidade. Itens de decisão pendente estão marcados `[DECIDIR]`.
**Execução:** incremental, na ordem das fases — nunca big-bang. Cada fase termina compilando e com regressão dos fluxos POST/PATCH/DELETE/GET afetados.
**Complexidade:** S (pequena, <1h), M (média, meio dia), L (grande, 1+ dia). **Status:** ☐ pendente.

> **Estado em 2026-09-24 (sincronização com o código):**
> - Os nomes usados nas Fases 0–2 foram **superados** pelo código atual: não existe `IErpService`/`IService` (o contrato é a classe abstrata `thl-lib.erp.core.Service`); `executeAndRegister` virou `executeService`; `methodPost/Patch/Delete` não recebem `context`. Referência atual: `erp/erp-services.md` e `integration/messaging-inbound.md`.
> - `LpcoService`/`LpcoMessage` foram para `thl-extensions\…\automatizador\` e `FretePrevistoService`/`FreteMessage` para `thl-extensions\…\dvv\` (os itens 0.4 e 4.9 continuam valendo nesses arquivos). O item **0.4 continua aberto**: `FretePrevistoService:create()` ainda grava `des-observacao = numeroNota` (ver `extensions/dvv.md`).
> - A regressão **5.1 não pode ser executada**: `Utils\test\` está vazia (os `testRegressao*.p` foram removidos e não estavam versionados).
> - Decisões ainda abertas: **2.6**, **3.7**, **4.9**, **4.10**.

---

## Fase 0 — Correção de bugs ✅ CONCLUÍDA (2026-07-25, thl-coding — pendente compilação/regressão 5.1)

| # | Item | Arquivo/Método | Compl. | Risco | Status |
|---|---|---|---|---|---|
| 0.1 | `getEnvironmentIntegerCapped` corrigido: `maxValue` como default quando env var vazia e teto via `min()`; visibilidade `public` → `protected` | `NotaFiscalService.cls` | S | Validar em TST (comportamento SEFAZ muda: retry passa a executar de fato) | ☑ |
| 0.2 | `error` inicializado no construtor de `BusinessObject` (`new ErrorHandler(TypeName)`) — `throwRowErrorsIfAny` continua reinstanciando com método/etapa | `erp/core/BusinessObject.cls` | S | Baixo | ☑ |
| 0.3 | Textos corrigidos: LPCO/Documento/Embarque com nome da própria entidade; ações do Embarque ajustadas (`'criacao'`→`'criado'`, `'delete'`→`'excluido'`) | `LpcoService`, `EmbarqueService`, `DocumentoService` | S | Resposta externa mudou — avisar consumidores que parseiam `message` | ☑ |
| 0.4 | **REABERTO** (estado do working copy em 2026-07-25): `create` voltou a gravar `des-observacao = numeroNota` e sem `do transaction`; `using` de `AuditLogService`/`LogUtil` presentes novamente. Confirmar com Lopes se a reversão é intencional (ex.: auditoria será implementada) antes de reaplicar. `[DECIDIR: auditoria]` | `FretePrevistoService.cls` | S | Baixo | ☐ |
| 0.5 | `'loogai'` eliminado: novo `resolveIntegrationUser(payload)` — env var `usuario.integracao` → fallback `codigoUsuario` do payload → erro se ambos ausentes. **⚠️ Provisionar `usuario.integracao` em PRD/TST/HOM antes do deploy** (sem ela e sem `codigoUsuario` no payload, o create passa a falhar controladamente) | `EmbarqueService.cls` | S | Médio — alinhar valor da env var por ambiente | ☑ |
| 0.6 | `do transaction` explícito em `update` e `delete` | `LpcoService.cls` | S | Baixo | ☑ |
| 0.7 | `printOption` com default 1 quando `'opcao'` ausente (igual ao irmão NF direta) | `NotaFiscalPorEmbarqueService.cls` | S | Baixo | ☑ |

## Fase 1 — Centralização da resposta ✅ CONCLUÍDA (2026-07-25, thl-coding — pendente compilação/regressão 5.1)

| # | Item | Compl. | Status |
|---|---|---|---|
| 1.1 | `thl-lib.erp.core.ServiceResponse` criado: `success(entidade, acao)` estático + sobrecarga `success(entidade, acao, referenceCode)` (campo só entra se informado) + `failure(code, message)`. Os 5 `buildSuccessPayload` removidos; 9 pontos de retorno migrados (Lpco ×3, FretePrevisto ×3, Embarque ×2, Usuario ×1, Documento ×1). De quebra: `outPayload` órfão de `FretePrevistoService` eliminado (property havia sido removida manualmente, usos pendentes concluídos aqui); ações normalizadas em minúsculas (`'criado'`, `'cancelado'`) | M | ☑ |
| 1.2 | Enriquecimento da resposta: sobrecarga com `referenceCode` já disponível em `ServiceResponse` (opt-in, contrato atual preservado). Campos adicionais (situação, ref. externa, dados) continuam `[DECIDIR: mudam contrato externo — alinhar com consumidores antes de usar]` | M | ◐ |
| 1.3 | Verificado: `Message:setSuccessPayload` já produz o mesmo shape `{success, code, message}` — alinhado sem mudança de código; `messaging` permanece sem dependência de `erp.core` (correto) | S | ☑ |

## Fase 2 — Fluxo comum das Messages (Template Method) ✅ CONCLUÍDA (2026-07-25, thl-coding — pendente compilação/regressão 5.1)

| # | Item | Compl. | Status |
|---|---|---|---|
| 2.1 | `executeAndRegister(action, operation, payload)` implementado em `InboundMessage`: chama `createService():execute()` + seta payload + `loadExternalReference` + `appendItem()`. Substitui o `registerResult` anterior (que não era chamado). **Rastreabilidade THL resolvida para todas as Messages** | S | ☑ |
| 2.2 | `thl-lib.erp.core.IErpService` criada (renomeada de ICrudService); implementada por **todos os 7 Services** (incluindo NF direta e NF por embarque, migrados em 2026-07-26). Interface única com dispatcher `execute(action, operation, context, output referenceCode): JsonObject`. Actions não suportadas lançam `ThlAppError` no `otherwise` | M | ☑ |
| 2.3 | Smart defaults em `InboundMessage`: `createService(): IErpService` (**abstract**), `getRequiredFields()` (**abstract**), `methodPost/Patch/Delete` default via `executeAndRegister`. Properties `routePath`/`routeOperation` populadas em `dispatchInbound`. Migradas: **todas** as 7 Messages — viraram pura configuração (`createService()` + hooks). Frete usa `routeOperation` para selecionar modalidade; NF usa `routePath` para selecionar Service | M | ☑ |
| 2.4 | `loadExternalReference` deixou de ser abstract — default dirigido por `getExternalReferenceField()` (`'referenciaID'`); overrides de campo: Embarque `'viagem'`, Lpco `'numeroLpco'`, NF/Documento `''`. Overrides triviais de Usuario/Frete removidos | S | ☑ |
| 2.5 | Factory Method unificado: `createService(): IErpService` (abstract na base, override em cada Message). `NotaFiscalMessage` seleciona por `routePath` dentro de `createService()` (sem factories separadas). `FreteMessage` seleciona por `routeOperation`. `LoogAiDocumentoMessage` atualizada para o novo tipo de retorno `IErpService` | S | ☑ |
| 2.6 | Referência externa de NF e Documento: `getExternalReferenceField()` retorna `''` com comentário apontando este item — `[DECIDIR com negócio]` qual campo do payload usar | S | ☐ |

## Fase 3 — Par NotaFiscal ✅ CONCLUÍDA em 2026-07-25 (exceto decisões pendentes — compilação/regressão 5.1 obrigatória: fase de maior risco)

| # | Item | Compl. | Status |
|---|---|---|---|
| 3.1 | `NotaFiscalBaseService` criada (`abstract inherits BusinessObject`): 6 temp-tables, buffer `b-nota-fiscal`, `inPayload`/`outPayload`, `initializeExecution`, `exportNfeXml` (ft0910rp), `runSefazAuthorization` (núcleo retry ft0915a/bodi135na), `printInvoiceDocument` (esft1932i), `addInvoicePayload` (com hooks de chave), `getEnvironmentIntegerCapped` (movido da concreta), `LoadReferenceCode` abstract. `tt-nota-gerada.rw-b-nota-fiscal` (por embarque) unificado como `rw-nota-fiscal`. ~250 linhas duplicadas eliminadas | L | ☑ |
| 3.2 | Defaults SEFAZ unificados na base: `getSefazMaxAttempts()` (=capped `sefaz.tentativa`, 3) e `getSefazPauseSeconds()` (=capped `sefaz.pausa`, 5). **⚠️ Mudança de comportamento para NF por embarque:** fallbacks eram 1 tentativa/0s — agora 3/5 quando env vars ausentes | S | ☑ |
| 3.3 | Chaves de resposta **preservadas por hooks** (`getStatusMessageKey`/`getValidFileKey`: base `'mensagem'`/`'valido'`; por embarque sobrescreve `'sefaz'`/`'arquivoValido'`). Unificação real continua `[DECIDIR com integrador]` — quando aprovada, basta apagar os 2 overrides | M | ◐ |
| 3.4 | **Redesenhado em 2026-07-26:** dispatcher `execute(action, operation, context, output referenceCode): JsonObject` implementado nos dois Services NF (IErpService). O `case` de operação vive **dentro dos Services** (não mais na Message). `NotaFiscalMessage` simplificada a `createService()` que seleciona Service por `routePath`. Métodos de domínio (`createInvoice`, `generateNfeXmlWorker`, etc.) agora privados. Localização do embarque movida para `initializeExecution` override | L | ☑ |
| 3.5 | Estado de instância **centralizado e documentado** na base (invariante: toda operação pública inicia por `initializeExecution`) — eliminação total não aplicada: o encadeamento (`process`, buffer compartilhado entre etapas) depende dele por design. Residual aceito | M | ◐ |
| 3.6 | `process` (transação única + `pause`) mantido — restrição de plataforma (TSS síncrono), nota arquitetural preservada no código. Evolução futura: fluxo de reprocessamento assíncrono (padrão thl1986) | L | ☑ (registrado, sem ação) |
| 3.7 | Sequencial de embarque via `find last ... no-wait` — continua `[DECIDIR: sequência dedicada vs retry interno]` | M | ☐ |

## Fase 4 — Limpezas e padronizações ✅ CONCLUÍDA (2026-07-25, thl-coding — pendente compilação/regressão 5.1)

| # | Item | Compl. | Status |
|---|---|---|---|
| 4.1 | Remover código morto: `EmbarqueService:loadReferenceCode` removido, bloco comentado `updateShipmentApproval` e chamada comentada removidos. Itens já limpos em fases anteriores: `FreteMessage:createService(operation)` (Fase 2), buffers órfãos (Fase 2), `pi-setaNota/pi-nfe` (Fase 3). `using` órfãos de `AuditLogService`/`LogUtil` em FretePrevisto: mantidos — item 0.4 `[DECIDIR]` pendente | S | ☑ |
| 4.2 | Cabeçalhos corrigidos: `BusinessObject` (era "BoService"), `ApplicationProgrammingInterface` (era "ApiService"), `FretePrevistoService` (era "FreteService"). `UsuarioService`/`DocumentoService` Notes atualizadas (referências a nomes antigos). Itens já corrigidos em Fase 3: `NotaFiscalMessage`, `NotaFiscalService`. `UsuarioMessage:35` não existe mais (removido na Fase 2) | S | ☑ |
| 4.3 | `mapFields( jsonSetter )` privado extraído em `LpcoService` — 15 `SetValue` agora em ponto único, chamado por `create` e `update` | S | ☑ |
| 4.4 | Casing padronizado: `loadReferenceCode` (camelCase) em todos: `NotaFiscalBaseService` (abstract), `NotaFiscalService`, `NotaFiscalPorEmbarqueService` (override), `UsuarioService`, `DocumentoService`, `LpcoService`, `FretePrevistoService` (private). `EmbarqueService` removido em 4.1. `this-object:` adicionado em todas as chamadas | S | ☑ |
| 4.5 | Revisado: `getEnvironmentIntegerCapped` já `protected` (Fase 0.1→3.1); `buildSuccessPayload` já removido (Fase 1.1). Demais `public` são contratos IErpService ou métodos P3 consumidos por Messages — sem alteração necessária | S | ☑ |
| 4.6 | Convenção documentada em erp-services.md (seção 4.12). Nomes atuais mantidos: `inPayload`/`outPayload` (NF Services, necessários para encadeamento — item 3.5), `payload` (parâmetro de entrada em CRUD Services). Sem refatoração — o estado de instância é intencional nos NF, e nos CRUD o payload é local por design | M | ☑ |
| 4.7 | Convenção definida: `this-object:` sempre em chamadas de método e escrita de properties. Aplicado: `LpcoService` (4×), `FretePrevistoService` (3×), `NotaFiscalService` (6×), `NotaFiscalPorEmbarqueService` (5×), `UsuarioService` (1×), `DocumentoService` (1×). Seção registrada em erp-services.md | S | ☑ |
| 4.8 | Tabela de convenção de handles registrada em erp-services.md: `delete procedure` (BOFs fnbo/dibo), `run destroy in` (boin*), `run pi-finalizar in` (APIs eqapi*/ut-acomp), `run finalizaBOS in` (bodi317in sub-handles) | S | ☑ |
| 4.9 | `LpcoService:get` expõe `referenceCode` (chave interna THL) no JSON externo — `[DECIDIR]` com negócio se é contrato intencional | S | ☐ |
| 4.10 | `UsuarioService:create`: universo (`bofn169`) usa apenas `companiesUser:GetJsonObject(1)` — `[DECIDIR]` com negócio se é intencional (só a primeira empresa) | M | ☐ |
| 4.11 | Constantes nomeadas aplicadas: `EmbarqueService` (`OPER_INCLUSAO=1`, `OPER_ELIMINACAO_EMBARQ=3`, `OPER_ELIMINACAO_PED=2`, `SITUACAO_ATIVA=1`), `FretePrevistoService` (`SITUACAO_ATIVO=1`, `SITUACAO_CANCELADO=2`). Literais dos NF Services (`destino=2`, `tipo-nota=1`, `programa=9999`, `'mgs'`) mantidos inline: uso único em contexto BOF-específico, comentários existentes são suficientes | S | ☑ |
| 4.12 | Tabela de classificação de parâmetros registrada em erp-services.md: requisição (payload), derivados (Service), fixos funcionais (constantes 4.11), por ambiente (EnvironmentResource), técnicos de execução (Message/MessageRepository) | S | ☑ |

## Fase 5 — Regressão e documentação ✅ CONCLUÍDA (2026-07-25, thl-coding — pendente execução dos .p no ambiente OpenEdge)

| # | Item | Status |
|---|---|---|
| 5.1 | 6 procedures de regressão gerados em `Utils/test/`: `testRegressaoLpco.p` (CRUD completo + idempotência, 5 testes), `testRegressaoFretePrevisto.p` (POST/PUT/DELETE + duplicidade, 4 testes), `testRegressaoEmbarque.p` (POST/DELETE, 2 testes), `testRegressaoUsuario.p` (POST + duplicidade, 2 testes), `testRegressaoDocumento.p` (POST, 1 teste), `testRegressaoNotaFiscal.p` (NF direta geracao/processamento + NF por embarque geracao, 3 testes) | ☑ |
| 5.2 | `testRegressaoMensagem.p` valida fluxo thl-mensagem completo: criação, payload gravado, thl-mensagem-item (referenceCode/ExternalReferenceCode), histórico de status, reprocessamento/idempotência — 5 testes | ☑ |
| 5.3 | INDEX.md atualizado com changelog sessão 2g (Fase 5). Backlog marcado como concluído. Riscos transversais sem alteração (itens `[DECIDIR]` preservados) | ☑ |

---

## Ordem de execução e dependências

```
Fase 0 (bugs)  →  1.1/1.3  →  2.1  →  2.2/2.3 (piloto Lpco)  →  2.4/2.5  →  Fase 4 (paralelo a partir daqui)
                                                       ↘  3.1 → 3.2 → 3.4 → 3.5   (3.3 e decisões [DECIDIR] podem bloquear — destravar com Lopes/integrador antes)
```

- **Piloto:** par `LpcoMessage`/`LpcoService`.
- **Decisões pendentes com o usuário/integrador** (bloqueiam o item, não a fase): 0.4 (auditoria), 1.2 (campos extras da resposta), 2.2 (interface única vs fatiada), 2.6 (ref. externa de NF), 3.3 (unificação de contrato NF), 3.7 (sequencial de embarque), 4.9 (referenceCode no GET), 4.10 (universo 1ª empresa).
- Execução de código: skill **thl-coding**; validação: **thl-qa**; este backlog: manutenção pela **thl-architect**.

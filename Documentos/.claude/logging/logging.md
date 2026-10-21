---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, log, auditoria]
updated: 2026-10-13
---

# Pacote: logging

> **Visão do módulo de auditoria** (gravação, consulta, cadastro, expurgo, achados e plano de desempenho): [auditoria.md](auditoria.md).
>
> **Sincronizado em 2026-10-02** (assinaturas de `writeChange`/`deleteRecord`, achados da análise). Em 2026-09-24: `hasChangedMonitoredTable` não existe mais; `hasChangedMonitoredField` recebe `databaseName` e considera `ind-audit-tabela` (tabela inteira). Usuários gravados corrigidos (`usuario` = Datasul, `usuario-so` = SO). Tabelas e índices: [data/schema.md](../data/schema.md).

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| LogUtil | Wrapper estático para `log-manager:write-message` — escreve apenas se log file estiver configurado | Nenhum | StringUtil | ConnectorService, MessageRepository, OutboundMessageService, SchedulingService, AuditLogService, e outros |
| AuditLogService | Persiste auditoria orientada a configuração em `thl-audit-registro` + `thl-audit-registro-detalhe`. Compara buffers, filtra campos monitorados e grava snapshots JSON completos | Service | ContextService, JsonWriter, AuditOperationEnum, AuditSnapshotEnum | Programas de negócio que precisam de rastreabilidade |
| AuditOperationEnum | Enum de tipo de operação: `Criacao=1`, `Atualizacao=2`, `Delecao=3` | Enum | — | AuditLogService |
| AuditSnapshotEnum | Enum de snapshot: `Atual=1` (buffer new), `Anterior=2` (buffer old) | Enum | — | AuditLogService |

---

## LogUtil

**Caminho:** `thl-lib\logging\LogUtil.cls`

**Namespace ABL:** `thl-lib.logging.LogUtil`

**Responsabilidade:** Utilitário estático para escrita no log do OpenEdge (`log-manager`). Todo método verifica se `log-manager:logfile-name` está configurado antes de escrever — nunca lança exceção se o log não estiver ativo. A sobrecarga com `guardObject` só escreve se o objeto for válido.

**Padrão de projeto:** Nenhum (utilitário estático). Declarado `serializable`.

**Dependências diretas THL:** `StringUtil`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final void write( textMessage as character, context as character )` | Escreve mensagem no log se logfile configurado. |
| `method public static final void write( guardObject as Progress.Lang.Object, textMessage as character, context as character )` | Escreve apenas se `guardObject` for válido e logfile configurado. |
| `method public static final void printLog( valueLog as logical, labelLog as character )` | Debug: escreve `"- Got here, labelLog = value"` para `logical`. |
| `method public static final void printLog( valueLog as decimal, labelLog as character )` | Debug: idem para `decimal`. |
| `method public static final void printLog( valueLog as integer, labelLog as character )` | Debug: idem para `integer`. |
| `method public static final void printLog( valueLog as date, labelLog as character )` | Debug: idem para `date`. |

---

## AuditOperationEnum

**Caminho:** `thl-lib\logging\audit\enum\AuditOperationEnum.cls`

**Namespace ABL:** `thl-lib.logging.audit.enum.AuditOperationEnum`

**Valores:** `Criacao=1`, `Atualizacao=2`, `Delecao=3` — gravados em `thl-audit-registro.tipo`.

---

## AuditSnapshotEnum

**Caminho:** `thl-lib\logging\audit\enum\AuditSnapshotEnum.cls`

**Namespace ABL:** `thl-lib.logging.audit.enum.AuditSnapshotEnum`

**Valores:** `Atual=1` (estado após a operação — buffer new), `Anterior=2` (estado antes — buffer old) — gravados em `thl-audit-registro-detalhe.tipo`.

---

## AuditLogService

**Caminho:** `thl-lib\logging\audit\AuditLogService.cls`

**Namespace ABL:** `thl-lib.logging.audit.AuditLogService`

**Responsabilidade:** Auditoria orientada a configuração. Verifica quais tabelas e campos estão monitorados (`thl-audit-tabela`, `thl-audit-tabela-campo`), compara dois buffers (before/after) e persiste snapshots JSON completos em `thl-audit-registro` + `thl-audit-registro-detalhe`.

**Padrão de projeto:** Service. Declarado `serializable`.

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `ContextService`, `JsonWriter`, `AuditOperationEnum`, `AuditSnapshotEnum`.

**Tabelas acessadas:**
- `thl-audit-tabela` — configuração por `banco` (DBNAME do buffer) + `tabela` (`pk-tabela`): `ind-ativo-create`/`-update`/`-delete`, `ind-audit-tabela` (todos os campos) e `pk` (array JSON com os campos da chave) — read-only, `find first`
- `thl-audit-tabela-campo` — campos monitorados (`ind-ativo`) quando a tabela não é auditada inteira — read-only, `can-find` (índice `idx-ativo`)
- `thl-audit-registro` — cabeçalho (create): `id-registro` (GUID), `banco` = `'sh'` + nome do banco, `tabela`, `referencia`, `tipo` (`AuditOperationEnum`), `data-criacao`, `campos` (`'Todos'` em inclusão/exclusão), `usuario` = `ContextService:getErpUser()` (Datasul), `usuario-so` = `getUser()` (SO), `programa-executado` = `getProgramsCaller()`
- `thl-audit-registro-detalhe` — snapshots JSON antes/depois (create)

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public final void writeChange( newRecord as logical, changedFields as character, bufferNew as handle, bufferOld as handle )` | Ponto de entrada principal. Localiza a configuração por `bufferNew:dbname` + `bufferNew:table`. Se `newRecord=true` → INSERT; se `false` e algum campo monitorado mudou → UPDATE. Retorna sem gravar se a tabela não estiver configurada. A referência é montada internamente por `buildReference` (não é mais parâmetro). |
| `method public final void deleteRecord( bufferDelete as handle )` | Grava snapshot do registro antes da exclusão (operação DELETE). Localiza a configuração por `bufferDelete:dbname` + `bufferDelete:table`; a referência vem de `buildReference`. |

**Métodos privados:**

| Assinatura | Descrição |
|---|---|
| `method private void insertRecord( reference as character, bufferRecord as handle )` | Grava cabeçalho + snapshot `Atual` em transação. |
| `method private void updateRecord( reference as character, changedFields as character, bufferNew as handle, bufferOld as handle )` | Grava cabeçalho + snapshots `Atual` e `Anterior` em transação. |
| `method private character logRecord( reference, dataBaseName, tableName, operationType )` | Overload sem `changedFields` — usa `'Todos'`. Cria registro em `thl-audit-registro`, retorna GUID. |
| `method private character logRecord( reference, dataBaseName, tableName, changedFields, operationType )` | Cria registro em `thl-audit-registro` com GUID gerado, retorna GUID. |
| `method private void logRecordDetail( id, snapshotType, bufferRecord )` | Serializa buffer via `JsonWriter:toJsonFromBuffer` e persiste em `thl-audit-registro-detalhe`. |
| `method private character buildReference( bufferRecord as handle, keyFields as longchar )` | Monta a referência do registro: faz o parse de `keyFields` (`thl-audit-tabela.pk`, array JSON de nomes de campo) e junta os valores com `|`. Devolve `''` se o buffer for inválido, `pk` vazio ou JSON inválido. |
| `method private logical hasChangedMonitoredField( databaseName as character, tableName as character, changedFields as character )` | `true` se a tabela é auditada inteira (`b-thl-audit-tabela.ind-audit-tabela`) **ou** se algum campo alterado está ativo em `thl-audit-tabela-campo` (via `matches`). |

**Observações:**
- `writeChange` e `deleteRecord` não têm callers externos em `thl/` ou `thl-extensions/` — suas assinaturas podem ser alteradas sem impacto externo. (`FretePrevistoService` tem o `using`, mas não chama.)
- ⚠️ A classe **não tem** `block-level on error undo, throw`.
- ⚠️ **Inclusão gravada como alteração** (`writeChange`, linhas 40-49): com `ind-ativo-create = no`, `ind-ativo-update = yes` e `ind-audit-tabela = yes`, um registro novo cai no `else` e é gravado como `Atualizacao` com `campos` vazio. Falta retornar quando `newRecord` é verdadeiro e a inclusão não está habilitada.
- O chamador entrega buffer de banco; a temp-table dinâmica é criada dentro do `JsonWriter` porque o `write-json` só existe para temp-table/ProDataSet.
- A configuração é resolvida **a cada gravação** pelo handle do buffer (`dbname` + `table`), sem cache: um `find` em `thl-audit-tabela` por registro gravado, mais o parse do JSON de `pk`. O nome do banco é o nome lógico da conexão — depende de como o ambiente conecta.
- `Utils\example\exampleAuditTriggerDelete.p` está comentado e ainda usa a assinatura antiga (com `reference`).
- O código grava `b-thl-audit-registro.id` / `-detalhe.id`; o campo no `.df` é `id-registro` (funciona por abreviação de nome de campo do ABL — quebra com `-require-full-names` ou se surgir outro campo iniciado por `id`).
- O GUID é gerado via `guid(generate-uuid)` — único por registro.
- Snapshots JSON são serializados via `JsonWriter:toJsonFromBuffer(bufferRecord)`.
- Regras de gravação: inclusão só com `ind-ativo-create`; alteração só com `ind-ativo-update` **e** campo monitorado alterado; exclusão só com `ind-ativo-delete`.
- ⚠️ `hasChangedMonitoredField` usa `changedFields matches '*<campo>*'`: um campo cadastrado `cod` também casa com `cod-estab` (falso positivo). Comparar com `lookup(campo, changedFields) > 0` resolveria.
- Até 2026-09-24 `usuario` e `usuario-so` eram gravados trocados; registros anteriores têm `usuario` = usuário do SO.

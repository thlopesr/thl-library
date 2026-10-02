# Extensão: dvv

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| FreteMessage | Mensagem inbound de manutenção de frete; seleciona o Service pela modalidade da rota (`previsto`; `realizado` ainda não implementado) | Template Method + Factory Method | InboundMessage, FretePrevistoService, MethodTypeEnum | InboundMessageService (via `thl-objeto.classe-objeto`) |
| FretePrevistoService | Serviço de domínio do frete previsto (`nit-frete-prev`): criação com validação da NF, atualização de valor/observação e cancelamento lógico | Service (Template Method via `Service`) | Service, SituacaoFreteEnum, ThlError | FreteMessage |
| SituacaoFreteEnum | Situação do registro `nit-frete-prev` (`idi-situacao`) | Enum | — | FretePrevistoService |

> **Criada em 2026-09-24.** As 3 classes saíram de `thl-lib` (`…messaging.inbound.message`, `erp.service`, `erp.enum`) porque dependem do schema do cliente (`nit-frete-prev`). ⚠️ O registro de `thl-objeto.classe-objeto` da `FreteMessage` precisa apontar para o novo nome completo.

---

## FreteMessage

**Caminho:** `thl-extensions\integration\dvv\messaging\inbound\message\FreteMessage.cls`

**Namespace ABL:** `thl-extensions.integration.dvv.messaging.inbound.message.FreteMessage`

**Responsabilidade:** Contrato inbound do frete. Não tem lógica de negócio: os verbos POST, PATCH e DELETE usam os defaults de `InboundMessage` (`executeService` → `createService():execute(...)`).

**Padrão de projeto:** Template Method (subclasse de `InboundMessage`) + Factory Method (`createService()` por modalidade).

**INHERITS / IMPLEMENTS:** `inherits InboundMessage`

**Dependências diretas THL:** `InboundMessage`, `InboundObjectContext`, `FretePrevistoService`, `Service`, `ActionEnum`, `MethodTypeEnum`.

**Construtor:** `constructor public FreteMessage( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode )` — repassa ao `super`. Instanciada por `MessageFactory` via `dynamic-new` com o nome em `thl-objeto.classe-objeto`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override Service createService()` | `case context:operation`: `'previsto'` → `new FretePrevistoService()`; `'realizado'` → `errorHandler:throwError` ("Modalidade frete/realizado ainda nao implementada."); outro valor → erro "Modalidade de frete nao reconhecida". |
| `method protected override character getRequiredFields()` | DELETE: `'Estabelecimento,Serie,NrNota,TipoFrete'`; demais: `'Estabelecimento,Serie,NrNota,TipoFrete,ValorFrete'`. |

**Contrato JSON:** `Estabelecimento` (**CNPJ** do estabelecimento — convertido para `cod-estabel`), `Serie`, `NrNota`, `TipoFrete` (inteiro), `ValorFrete` (decimal), `Observacao` (opcional). Chave do registro: estabelecimento + série + nota + tipo de frete.

**Observações:**
- Não há `methodGet` — o frete não tem consulta pela API.
- A modalidade `realizado` é um stub reservado na rota (não quebra o contrato público quando for implementada).

---

## FretePrevistoService

**Caminho:** `thl-extensions\erp\dvv\service\FretePrevistoService.cls`

**Namespace ABL:** `thl-extensions.erp.dvv.service.FretePrevistoService`

**Responsabilidade:** Manutenção de `nit-frete-prev`: criação de frete ativo, atualização e cancelamento lógico.

**Padrão de projeto:** Service, com Template Method herdado de `thl-lib.erp.core.Service` (`execute()` → `initialize()` → `create()`/`update()`/`delete()` → `loadReferenceCode()` → `buildResponse()`).

**INHERITS / IMPLEMENTS:** `inherits Service`

**Dependências diretas THL:** `Service`, `SituacaoFreteEnum`, `ThlError`. (Os `USING` de `AuditLogService` e `LogUtil` existem, mas **não são usados** no corpo.)

**Tabelas acessadas:** `nit-frete-prev` (escrita), `nota-fiscal`, `estabelec` (leitura).

**Propriedades privadas:** `estabelecimento`, `serie`, `numeroNota`, `tipoFrete`, `valorFrete`, `observacao` — preenchidas em `initialize()` a partir do `inContext`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method protected override character getEntityName()` | `'Frete previsto'`. |
| `method protected override void initialize()` | `setValue()`: lê `Serie`, `NrNota`, `TipoFrete`, `ValorFrete`, `Observacao` (opcional) e resolve `Estabelecimento` (CNPJ) → `estabelec.cod-estabel`; lança `ThlError` se o estabelecimento não existir. |
| `method protected override void create()` | Valida a NF de origem em `nota-fiscal`; rejeita se já existir frete **ativo** para a chave; cria o registro com `idi-situacao = ATIVO`. |
| `method protected override void update()` | Localiza o frete ativo (`exclusive-lock`) e altera só `val-frete` e `des-observacao` — a chave é imutável. |
| `method protected override void delete()` | **Cancelamento lógico:** `idi-situacao = CANCELADO`; nunca `delete` físico, para manter o histórico. |
| `method protected override character loadReferenceCode()` | `cod-estabel#serie#nr-nota-fis#idi-tipo-frete`. |

**Tratamento de erro:** `ThlError` para NF não localizada, frete ativo duplicado, frete não encontrado ou já cancelado, e estabelecimento não localizado.

**Observações:**
- ⚠️ **Possível bug em `create()`:** grava `des-observacao = numeroNota` (e não `observacao`); o `update()` usa `observacao`. Confirmar a intenção.
- O cabeçalho de `create()` fala em "auditoria no mesmo escopo", mas não há chamada a `AuditLogService` no código atual.
- Mensagem de erro com erro de digitação: `'Estabelecimentonao localizada.'`.

---

## SituacaoFreteEnum

**Caminho:** `thl-extensions\erp\dvv\enum\SituacaoFreteEnum.cls`

**Namespace ABL:** `thl-extensions.erp.dvv.enum.SituacaoFreteEnum`

**Valores:** `ATIVO = 1`, `CANCELADO = 2` — espelham `nit-frete-prev.idi-situacao`.

**Usado por:** `FretePrevistoService` (`SituacaoFreteEnum:ATIVO:GetValue()`, `SituacaoFreteEnum:GetEnum('Ativo')`, `SituacaoFreteEnum:CANCELADO:GetValue()`).

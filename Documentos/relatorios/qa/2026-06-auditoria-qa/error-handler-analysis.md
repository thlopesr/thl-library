# Análise de Padrões de Lançamento de Erro — THL-Library

> **Data:** 2026-06-13  
> **Analisado por:** thl-qa skill (Claude)  
> **Escopo:** todos os `.cls` de `Fontes/thl-lib/` e `Fontes/thl-extensions/`  
> **Nenhum arquivo foi modificado nesta análise.**

---

## FASE 1 — Inventário

### 1.1 — Ocorrências de `undo, throw new Progress.Lang.AppError`

16 ocorrências em 10 arquivos.

| # | Arquivo | Classe | Método | Linha | Código | Mensagem | Contexto |
|---|---------|--------|--------|-------|--------|----------|----------|
| 1 | `thl-lib/core/environment/EnvironmentContext.cls` | `EnvironmentContext` | `setEnvirommentParameter()` | 41 | 17006 | `'Parameter code not found in thl-ambiente-param-prog for current execution context.'` | Após loop de busca em `program-name()`, método **STATIC** |
| 2 | `thl-lib/core/environment/EnvironmentResource.cls` | `EnvironmentResource` | `getEnvironmentVariable(variableCode)` | 33 | 17006 | `'Environment not initialized. Call EnvironmentResource:initialize() before getEnvironmentVariable(variableCode).'` | Guarda de pré-condição, método **STATIC** |
| 3 | `thl-lib/core/environment/EnvironmentResource.cls` | `EnvironmentResource` | `resolveParameterCode(objectName)` | 63 | 17006 | `'Parameter code not found for object: ' + objectName` | Pós-busca no DB, método **STATIC** |
| 4 | `thl-lib/util/file/FileUtil.cls` | `FileUtil` | `getRequiredFullPathName()` | 47 | 17006 | `'Arquivo nao informado.'` | Guarda de parâmetro nulo, método **STATIC private** |
| 5 | `thl-lib/util/file/FileUtil.cls` | `FileUtil` | `getRequiredFullPathName()` | 52 | 17006 | `SUBSTITUTE('Arquivo &1 nao encontrado.', filePath)` | Pós-busca de arquivo, método **STATIC private** |
| 6 | `thl-lib/core/environment/repository/EnvironmentRepository.cls` | `EnvironmentRepository` | `findEnvironmentCodeByPropath()` | 27 | 17006 | `'Environment not identified.'` | Pós-loop de busca em `thl-ambiente`, sem bloco ON ERROR |
| 7 | `thl-lib/util/json/JsonSetter.cls` | `JsonSetter` | `setPayload()` | 26 | 17006 | `'JsonSetter: payload was not informed.'` | Guarda de objeto nulo no construtor/setter |
| 8 | `thl-lib/integration/messaging/inbound/route/InboundRouteResolver.cls` | `InboundRouteResolver` | `Resolve()` (private) | 39 | 17006 | `'Rota inbound invalida.'` | Guarda de `pathParameters` nulo, chamado pelo constructor |
| 9 | `thl-lib/integration/messaging/inbound/message/LpcoMessage.cls` | `LpcoMessage` (inbound) | `methodPost()` | 76 | 17006 | `'LpcoMessage: LPCO ja existe.'` | Verificação de duplicidade pré-create; herda `InboundMessage → Message` |
| 10 | `thl-lib/integration/messaging/inbound/message/LpcoMessage.cls` | `LpcoMessage` (inbound) | `methodDelete()` | 120 | 17006 | `'LpcoMessage: LPCO nao localizado.'` | Pós-find para delete; herda `InboundMessage → Message` |
| 11 | `thl-extensions/integration/automatizador/messaging/outbound/message/LpcoMessage.cls` | `LpcoMessage` (outbound automatizador) | `getEntityKey()` | 76 | 17006 | `'LPCO nao encontrado'` | Pós-find sem-lock; herda `OutboundMessage → Message` |
| 12 | `thl-extensions/integration/ninahub/messaging/outbound/message/ChamadoMessage.cls` | `ChamadoMessage` | `getEntityKey()` | 70 | 17006 | `'Embarque nao encontrado'` | Pós-find sem-lock; herda `OutboundMessage → Message` |
| 13 | `thl-extensions/integration/loogai/messaging/outbound/message/EntregaPedidoMessage.cls` | `EntregaPedidoMessage` | `getEntityKey()` | 237 | 17006 | `'Entraga pedido de venda nao encontrado.'` | Pós-find sem-lock; herda `OutboundMessage → Message` |
| 14 | `thl-extensions/integration/loogai/messaging/outbound/message/NotaFiscalMessage.cls` | `NotaFiscalMessage` | `getEntityKey()` | 72 | 17006 | `'Nota Fiscal nao encontrado'` | Pós-find sem-lock; herda `OutboundMessage → Message` |
| 15 | `thl-extensions/integration/mmcm/messaging/outbound/message/PedidoMessage.cls` | `PedidoMessage` | `getEntityKey()` | 90 | 17006 | `'Nota fiscal nao encontrado'` | Pós-find sem-lock; herda `OutboundMessage → Message` |
| 16 | `thl-extensions/integration/mmcm/messaging/outbound/message/PrePedidoMessage.cls` | `PrePedidoMessage` | `getEntityKey()` | 97 | 17006 | `'Embarque nao encontrado'` | Pós-find sem-lock; herda `OutboundMessage → Message` |

---

### 1.2 — Ocorrências de `this-object:errorHandler:throwError`

20 chamadas diretas + 3 via `addError` + `throwIfHasErrors`, em 5 arquivos.

| Arquivo | Classe | Método | Linha | Assinatura da chamada |
|---------|--------|--------|-------|-----------------------|
| `thl-lib/integration/messaging/inbound/message/LpcoMessage.cls` | `LpcoMessage` (inbound) | `methodPatch()` | 46 | `throwError( 17006, 'LPCO nao localizado.' )` |
| `thl-lib/integration/messaging/inbound/message/NotaFiscalPorEmbarqueMessage.cls` | `NotaFiscalPorEmbarqueMessage` | `methodPost()` | 46 | `throwError( 17006, 'NotaFiscalPorEmbarqueMessage: Embarque nao localizado.' )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `buildShipment()` | 117 | `throwError( 17006, 'Estabelecimento nao localizado.' )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `appendCreatedShipmentItem()` | 176 | `throwError( 17006, 'Embarque nao localizado.' )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `processDelivery()` | 246 | `throwError( 17006, SUBSTITUTE('Pedido de venda nao localizado no index &1.', deliveryIndex) )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `processDelivery()` | 260 | `throwError( 17006, SUBSTITUTE('Entrega do pedido nao localizada no index &1.', deliveryIndex) )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `validateApiErrors()` | 331 | `addError( tt-erro.cd-erro, SUBSTITUTE('&1 - &2', stepDescription, tt-erro.mensagem) )` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `validateApiErrors()` | 334 | `throwIfHasErrors()` |
| `thl-lib/integration/messaging/inbound/message/EmbarqueMessage.cls` | `EmbarqueMessage` | `validateShipmentPayload()` | 340 | `throwError( 17006, 'Nenhuma entrega informada para geracao do embarque.' )` |
| `thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | `InboundMessage` (base) | `validateRequiredFields()` | 154 | `addError( 17006, SUBSTITUTE('InboundMessage: campo obrigatorio &1 nao foi informado.', fieldName) )` |
| `thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | `InboundMessage` (base) | `validateRequiredFields()` | 158 | `throwIfHasErrors()` |
| `thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | `InboundMessage` (base) | `handleError()` | 209–214 | `getErrorStatusCode()` / `getErrorMessage()` / `getErrorJsonText()` (resposta REST) |
| `thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | `InboundMessage` (base) | `handleRowErrors()` | 223 | `addError( RowErrors.ErrorNumber, ... )` |
| `thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | `InboundMessage` (base) | `handleRowErrors()` | 231, 236 | `throwIfHasErrors()` |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 47 | `throwError( 17006, 'Estabelecimento nao localizado' )` |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 53 | `throwError( 17006, 'Transportadora nao localizada' )` |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 59 | `throwError( 17006, 'Cond. pagamento nao localizado' )` |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 91, 137 | `throwError( 17006, 'Municipio origem nao localizado' )` (2×) |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 104, 145 | `throwError( 17006, 'Nota Fiscal nao localizada' )` (2×) |
| `thl-extensions/integration/loogai/messaging/inbound/message/LoogAiDocumentoMessage.cls` | `LoogAiDocumentoMessage` | `buildDocument()` | 173 | `throwError( 17006, 'Municipio Destino nao localizado' )` |

> **Achado adicional:** `DocumentoMessage.cls:155` contém uma chamada comentada:  
> `//this-object:errorHandler:throwError( 17006, string( cFile ) ).`  
> Isso indica debug temporário nunca removido. Recomenda-se remover o comentário.

---

### 1.3 — Ocorrências de `RETURN ERROR`

**Nenhuma ocorrência encontrada** em nenhum `.cls` do projeto.

---

## FASE 2 — Análise de Viabilidade de Padronização

### 2.1 — Hierarquia de herança relevante

```
Progress.Lang.Object
  └── thl-lib.integration.messaging.core.Message  (abstract)
          ├── define protected property errorHandler as ErrorHandler  ← ponto-chave
          ├── thl-lib.integration.messaging.outbound.core.OutboundMessage
          │       ├── thl-extensions.*.automatizador.LpcoMessage       (outbound)
          │       ├── thl-extensions.*.ninahub.ChamadoMessage
          │       ├── thl-extensions.*.loogai.EntregaPedidoMessage
          │       ├── thl-extensions.*.loogai.NotaFiscalMessage
          │       ├── thl-extensions.*.mmcm.PedidoMessage
          │       └── thl-extensions.*.mmcm.PrePedidoMessage
          └── thl-lib.integration.messaging.inbound.core.InboundMessage
                  ├── thl-lib.*.inbound.message.LpcoMessage
                  ├── thl-lib.*.inbound.message.EmbarqueMessage         (já usa errorHandler)
                  ├── thl-lib.*.inbound.message.NotaFiscalPorEmbarqueMessage
                  ├── thl-lib.*.inbound.message.DocumentoMessage
                  │       └── thl-extensions.*.loogai.LoogAiDocumentoMessage (já usa errorHandler)
                  └── thl-lib.*.inbound.message.UsuarioMessage

Classes SEM herança de Message (NÃO têm errorHandler):
  ├── thl-lib.core.environment.EnvironmentContext        (STATIC)
  ├── thl-lib.core.environment.EnvironmentResource       (STATIC)
  ├── thl-lib.util.file.FileUtil                         (STATIC)
  ├── thl-lib.core.environment.repository.EnvironmentRepository
  ├── thl-lib.util.json.JsonSetter
  └── thl-lib.integration.messaging.inbound.route.InboundRouteResolver
```

### 2.2 — Tabela de viabilidade por ocorrência

| Arquivo | Método | Linha | Viável? | Motivo |
|---------|--------|-------|---------|--------|
| `EnvironmentContext.cls` | `setEnvirommentParameter()` | 41 | **Não** | Método `STATIC` — `this-object` não existe |
| `EnvironmentResource.cls` | `getEnvironmentVariable(variableCode)` | 33 | **Não** | Método `STATIC` |
| `EnvironmentResource.cls` | `resolveParameterCode()` | 63 | **Não** | Método `STATIC` |
| `FileUtil.cls` | `getRequiredFullPathName()` | 47, 52 | **Não** | Método `STATIC private` |
| `EnvironmentRepository.cls` | `findEnvironmentCodeByPropath()` | 27 | **Não** | Classe de repositório sem herança de `Message`; criar `errorHandler` aqui violaria o padrão de camada |
| `JsonSetter.cls` | `setPayload()` | 26 | **Não** | Utilitário sem herança de `Message`; a semântica aqui é de pré-condição imediata no construtor — `undo, throw` é o padrão correto |
| `InboundRouteResolver.cls` | `Resolve()` | 39 | **Não** | Classe auxiliar sem herança de `Message`; lançada no construtor — `undo, throw` é necessário para propagar antes da instância estar pronta |
| `thl-lib/inbound/LpcoMessage.cls` | `methodPost()` | 76 | **Sim** | Herda `InboundMessage → Message`; `errorHandler` disponível; padrão `undo, throw` já foi substituído por `errorHandler` em `methodPatch()` da mesma classe — inconsistência interna a corrigir |
| `thl-lib/inbound/LpcoMessage.cls` | `methodDelete()` | 120 | **Sim** | Mesma classe acima; inconsistência idêntica |
| `thl-extensions/automatizador/LpcoMessage.cls` | `getEntityKey()` | 76 | **Sim** | Herda `OutboundMessage → Message`; `errorHandler` disponível |
| `thl-extensions/ninahub/ChamadoMessage.cls` | `getEntityKey()` | 70 | **Sim** | Herda `OutboundMessage → Message` |
| `thl-extensions/loogai/EntregaPedidoMessage.cls` | `getEntityKey()` | 237 | **Sim** | Herda `OutboundMessage → Message` |
| `thl-extensions/loogai/NotaFiscalMessage.cls` | `getEntityKey()` | 72 | **Sim** | Herda `OutboundMessage → Message` |
| `thl-extensions/mmcm/PedidoMessage.cls` | `getEntityKey()` | 90 | **Sim** | Herda `OutboundMessage → Message` |
| `thl-extensions/mmcm/PrePedidoMessage.cls` | `getEntityKey()` | 97 | **Sim** | Herda `OutboundMessage → Message` |

**Resumo:** 8 ocorrências viáveis (todas em subclasses de `Message`), 8 não-viáveis (STATIC ou fora da hierarquia).

### 2.3 — Consistência do `errorHandler` existente

**O que o `ErrorHandler` faz:**
- Acumula erros em `temp-table ttError` (suporte a múltiplos erros via `addError`)
- `throwError(code, msg)` → limpa + adiciona + lança `AppError` em uma chamada
- `throwIfHasErrors()` → lança somente se houver erros acumulados (padrão para validações em loop)
- Converte para JSON REST (`getErrorJson`, `getErrorJsonText`) — usado pela resposta PASOE
- **Não faz logging nem auditoria** — apenas encapsula o lançamento

**Assinatura atual de `throwError`:**
```abl
method public void throwError( errorNumber  as integer,
                               errorMessage as character ).
```
Apenas dois parâmetros. **Não recebe** classe nem método de origem.

**Perdas funcionais ao migrar:**
- Nenhuma perda de stack trace: `throwError` internamente faz `undo, throw getError()` que cria `AppError` — o stack trace do PASOE é equivalente ao `undo, throw new AppError(...)` direto.
- Sem integração com RPW ou PASOE response diferenciada: o `ErrorHandler` já é o mecanismo usado pelo `InboundMessage` para construir a resposta JSON do PASOE — a migração mantém essa integração.

---

## FASE 3 — Proposta de Padrão de Mensagem

### 3.1 — Padrão atual

| Dimensão | Observação |
|----------|-----------|
| **Código numérico predominante** | 17006 em 100% das ocorrências |
| **Idioma** | Misto: mensagens de infra em inglês (`'Environment not initialized'`, `'Environment not identified'`); mensagens de negócio em português (`'LPCO nao encontrado'`, `'Embarque nao encontrado'`) |
| **Classe/método embutidos** | Parcial: algumas mensagens incluem o nome da classe como prefixo manual (`'LpcoMessage: LPCO ja existe.'`, `'JsonSetter: payload was not informed.'`, `'NotaFiscalPorEmbarqueMessage: Embarque nao localizado.'`); a maioria não inclui |
| **Mensagens genéricas** | `'Embarque nao encontrado'` aparece 2× em classes distintas (ChamadoMessage e PrePedidoMessage) sem diferenciação de contexto. `'Nota Fiscal nao encontrado'` aparece 2× (NotaFiscalMessage e PedidoMessage). Mensagens duplicadas dificultam diagnóstico em produção |
| **Erro tipográfico** | `'Entraga pedido de venda nao encontrado.'` (EntregaPedidoMessage:237) — "Entraga" deveria ser "Entrega" |
| **Inconsistência intra-classe** | `thl-lib/inbound/LpcoMessage.cls` usa `errorHandler:throwError` em `methodPatch()` (L46) mas `undo, throw new AppError` em `methodPost()` (L76) e `methodDelete()` (L120) |

### 3.2 — Proposta de padrão unificado

#### Template de chamada

```abl
this-object:errorHandler:throwError(
    17006,
    SUBSTITUTE( '[&1.&2] &3', this-object:GetClass():TypeName, 'NomeDoMetodo', 'Descricao do erro em portugues.' )
).
```

#### Justificativas

1. **`this-object:GetClass():TypeName`** retorna o nome completo da classe em runtime (ex: `thl-extensions.integration.mmcm.messaging.outbound.message.PedidoMessage`). É suficiente — não há necessidade de string literal para a classe.

2. **Nome do método como string literal** é necessário porque ABL não fornece reflexão de método em runtime. Convenção proposta: usar o nome exato do método ABL como string, sem parênteses.

3. **Formato `[Classe.Metodo] Descrição`** alinha com o prefixo manual já adotado parcialmente (`'LpcoMessage: LPCO ja existe.'`) e facilita grep em logs de produção.

4. **Português** para todas as mensagens de negócio. Mensagens de infra (EnvironmentResource, FileUtil) podem permanecer em inglês pois são consumidas por desenvolvedores.

#### Exemplos de aplicação do template

**Antes** (getEntityKey em PedidoMessage):
```abl
undo, throw new Progress.Lang.AppError( 'Nota fiscal nao encontrado', 17006).
```

**Depois:**
```abl
this-object:errorHandler:throwError(
    17006,
    SUBSTITUTE( '[&1.&2] Nota fiscal nao encontrada para geracao da chave.', this-object:GetClass():TypeName, 'getEntityKey' )
).
```

---

**Criar `buildErrorMessage()` na classe base?**

Sim, faz sentido. Proposta de adição em `Message.cls`:

```abl
method protected final character buildErrorMessage( input methodName   as character,
                                                    input errorMessage as character ).
    return SUBSTITUTE( '[&1.&2] &3',
                       this-object:GetClass():TypeName,
                       methodName,
                       errorMessage ).
end method.
```

Uso resultante:
```abl
this-object:errorHandler:throwError( 17006, buildErrorMessage( 'getEntityKey', 'Nota fiscal nao encontrada.' ) ).
```

Vantagens:
- Elimina o `SUBSTITUTE` repetido em todas as subclasses
- O formato do prefixo fica centralizado — se mudar, muda em um só lugar
- Menor risco de erro de digitação no template

---

## FASE 4 — Plano de Refatoração Priorizado

### 4.1 — Classes prioritárias para migrar

Ordenadas por impacto e consistência interna:

| Prioridade | Arquivo | Ocorrências | Critério |
|-----------|---------|-------------|---------|
| 🔴 1 | `thl-lib/inbound/LpcoMessage.cls` | 2 | **Inconsistência intra-classe crítica**: mesma classe usa os dois padrões em métodos diferentes (PATCH usa `errorHandler`, POST e DELETE usam `undo, throw`) |
| 🔴 2 | `thl-extensions/automatizador/LpcoMessage.cls` | 1 | Padrão oposto ao seu análogo inbound; risco de diagnóstico confuso |
| 🔴 3 | `thl-extensions/ninahub/ChamadoMessage.cls` | 1 | Mensagem genérica sem contexto (`'Embarque nao encontrado'`) |
| 🔴 4 | `thl-extensions/mmcm/PrePedidoMessage.cls` | 1 | Mensagem idêntica à de ChamadoMessage — indistinguível em log |
| 🟡 5 | `thl-extensions/loogai/NotaFiscalMessage.cls` | 1 | Mensagem genérica (`'Nota Fiscal nao encontrado'`) sem gênero correto |
| 🟡 6 | `thl-extensions/mmcm/PedidoMessage.cls` | 1 | Mensagem genérica idêntica à de NotaFiscalMessage |
| 🟡 7 | `thl-extensions/loogai/EntregaPedidoMessage.cls` | 1 | Erro tipográfico na mensagem (`'Entraga'`) + sem contexto de classe |

### 4.2 — Classes que NÃO devem ser migradas

| Arquivo | Motivo |
|---------|--------|
| `EnvironmentContext.cls` | Método `STATIC` — `this-object` inexiste |
| `EnvironmentResource.cls` | Todos os métodos são `STATIC` |
| `FileUtil.cls` | Todos os métodos são `STATIC` |
| `EnvironmentRepository.cls` | Repositório de infraestrutura sem herança de `Message`; introduzir `ErrorHandler` aqui criaria acoplamento inadequado entre camadas |
| `JsonSetter.cls` | Utilitário genérico; o `undo, throw` no construtor é o mecanismo correto — falha imediata de pré-condição |
| `InboundRouteResolver.cls` | Lançamento no construtor, antes da instância estar completa; `undo, throw` é obrigatório neste contexto |

### 4.3 — Checklist de pré-condições antes de iniciar a refatoração

- [ ] **Adicionar `buildErrorMessage()` à classe `Message.cls`** (método `protected final`) — deve ser feito antes de qualquer migração para não repetir `SUBSTITUTE` nas subclasses
- [ ] **Verificar visibilidade de `errorHandler`**: a propriedade está declarada como `protected get. private set.` — subclasses podem ler (`this-object:errorHandler:throwError`), confirmado como viável
- [ ] **Testes de regressão**: executar `testInbound.p` e `testJsonSetter.p` após cada classe migrada
- [ ] **Teste de smoke manual** no `thl1986` (monitor outbound) para validar que erros de `getEntityKey()` migrados continuam aparecendo corretamente na tela de histórico
- [ ] **Remover linha comentada** em `DocumentoMessage.cls:155` (`//this-object:errorHandler:throwError(...)`)

### 4.4 — Exemplo before/after para o caso mais comum (`getEntityKey` em OutboundMessage)

**BEFORE** — `thl-extensions/integration/mmcm/messaging/outbound/message/PedidoMessage.cls:90`
```abl
if not available b-nota-fiscal then
    undo, throw new Progress.Lang.AppError( 'Nota fiscal nao encontrado', 17006).
```

**AFTER** — após adicionar `buildErrorMessage` em `Message.cls`
```abl
if not available b-nota-fiscal then
    this-object:errorHandler:throwError( 17006, buildErrorMessage( 'getEntityKey', 'Nota fiscal nao encontrada.' ) ).
```

**BEFORE** — `thl-lib/integration/messaging/inbound/message/LpcoMessage.cls:76` (inconsistência intra-classe)
```abl
if can-find( first b-nit-lpco ... ) then
    undo, throw new Progress.Lang.AppError( 'LpcoMessage: LPCO ja existe.' , 17006).
```

**AFTER**
```abl
if can-find( first b-nit-lpco ... ) then
    this-object:errorHandler:throwError( 17006, buildErrorMessage( 'methodPost', 'LPCO ja existe.' ) ).
```

---

## Achados Adicionais

| Tipo | Arquivo | Linha | Descrição |
|------|---------|-------|-----------|
| Debug não removido | `DocumentoMessage.cls` | 155 | Chamada `this-object:errorHandler:throwError(...)` comentada no meio de um bloco de processamento — parece debug temporário; remover |
| Erro tipográfico | `EntregaPedidoMessage.cls` | 237 | Mensagem `'Entraga pedido de venda nao encontrado.'` — "Entraga" deve ser "Entrega" |
| Inconsistência de gênero | `NotaFiscalMessage.cls` / `PedidoMessage.cls` | 72 / 90 | `'nao encontrado'` para "Nota Fiscal" (feminino) — corrigir para `'nao encontrada'` |
| Mensagem sem contexto | `ChamadoMessage.cls` / `PrePedidoMessage.cls` | 70 / 97 | Mesma string `'Embarque nao encontrado'` em classes distintas — indistinguível em log de produção |
| Idioma misto | `EnvironmentContext.cls` / `EnvironmentResource.cls` / `EnvironmentRepository.cls` | Vários | Mensagens em inglês enquanto o restante do projeto usa português — aceitável para mensagens de infra/desenvolvedor, mas vale documentar como decisão intencional |

---

## RISK SCORE

🔴 **Alto**

O projeto apresenta dois padrões de erro coexistentes sem critério explícito, incluindo **inconsistência dentro da mesma classe** (`LpcoMessage` inbound). Mensagens genéricas duplicadas em classes distintas tornam o diagnóstico em produção ambíguo. A migração é de baixa complexidade técnica, mas deve ser precedida pela adição de `buildErrorMessage()` na classe base para evitar regressão de consistência durante a transição.

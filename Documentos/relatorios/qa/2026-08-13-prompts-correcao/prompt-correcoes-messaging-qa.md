# Prompt — Correcoes QA Estatico `messaging`

Aplique todas as correcoes abaixo no pacote `thl-lib\integration\messaging`.
Cada correcao esta classificada por categoria e prioridade.
**Regra geral:** nao altere contratos publicos consumidos por `thl-extensions`
sem verificar impacto. As correcoes abaixo ja foram verificadas quanto a
callers — siga as instrucoes de impacto em cada item.

---

## 1. HEADERS — Copy-paste nos cabecalhos de arquivo

Quatro arquivos possuem o campo `File` do header ABL incorreto (residuo de
copy-paste do MessageRepository). Corrija o valor do campo `File :` no
comentario de cabecalho para refletir o nome real da classe.

| # | Arquivo | Linha | Valor atual | Valor correto |
|---|---------|-------|-------------|---------------|
| 1.1 | `Fontes/thl-lib/integration/messaging/factory/MessageFactory.cls` | 3 | `message_Repository` | `MessageFactory` |
| 1.2 | `Fontes/thl-lib/integration/messaging/outbound/strategy/SingleMessageStructure.cls` | 3 | `MessageRepository` | `SingleMessageStructure` |
| 1.3 | `Fontes/thl-lib/integration/messaging/outbound/strategy/MultipleMessageStructure.cls` | 3 | `MessageRepository` | `MultipleMessageStructure` |
| 1.4 | `Fontes/thl-lib/integration/messaging/repository/MessageConfigLoader.cls` | 3 | `MessageRepository` | `MessageConfigLoader` |

**Impacto:** zero — comentario, nao afeta compilacao nem comportamento.

---

## 2. COMENTARIO COPY-PASTE — EmitenteMessage

**Arquivo:** `Fontes/thl-lib/integration/messaging/inbound/message/EmitenteMessage.cls`
**Linha:** 41

**Atual:**
```abl
// Nao usado: ItemService nao implementa IService.
```

**Correto:**
```abl
// Nao usado: EmitenteService nao implementa IService.
```

**Impacto:** zero — comentario.

---

## 3. STATEMENT VAZIO — EmitenteMessage

**Arquivo:** `Fontes/thl-lib/integration/messaging/inbound/message/EmitenteMessage.cls`
**Linha:** 70

Remover o statement vazio `assign .` que nao tem efeito. Residuo de edicao.

**Atual:**
```abl
        assign .
    end method.
```

**Correto:**
```abl
    end method.
```

**Impacto:** zero — statement sem efeito.

---

## 4. TYPO — InboundRouteResolver `aplication`

**Arquivo:** `Fontes/thl-lib/integration/messaging/inbound/route/InboundRouteResolver.cls`

A variavel privada `aplication` (linha ~24) e o getter publico
`GetAplication()` (linha ~77) possuem typo — falta um `p`.

### Correcoes:
1. Renomear a variavel `aplication` → `application` (PRIVATE, sem impacto externo)
2. Renomear o metodo `GetAplication()` → `GetApplication()`

### Callers a atualizar:
- `Fontes/thl/integration/api/v1/resourcen.p` linha 73:
  `routeResolver:GetAplication()` → `routeResolver:GetApplication()`

### Verificacao de impacto:
- `GetAplication()` tem apenas 1 caller no projeto inteiro (resourcen.p).
- Nenhum caller em `thl-extensions`. Seguro renomear.

---

## 5. NAMING — `ExternalReferenceCode` PascalCase

**Arquivo:** `Fontes/thl-lib/integration/messaging/core/Message.cls`
**Linha:** 33

A propriedade `ExternalReferenceCode` usa PascalCase enquanto todas as demais
propriedades da classe usam camelCase (`referenceCode`, `objectName`, etc.).
A propriedade correspondente no MessageRepository (`externalReferenceCode`
linha 31) ja usa camelCase.

### Correcao:
Renomear `ExternalReferenceCode` → `externalReferenceCode` em:

| # | Arquivo | Linha |
|---|---------|-------|
| 5.1 | `Fontes/thl-lib/integration/messaging/core/Message.cls` | 33 (declaracao) |
| 5.2 | `Fontes/thl-lib/integration/messaging/inbound/core/InboundMessage.cls` | 76 |
| 5.3 | `Fontes/thl-lib/integration/messaging/inbound/message/EmitenteMessage.cls` | 76 |
| 5.4 | `Fontes/thl-lib/integration/messaging/inbound/message/ItemMessage.cls` | 50 |
| 5.5 | `Fontes/thl-lib/integration/messaging/inbound/message/LpcoMessage.cls` | 77 |

### Callers em testes (atualizar tambem):
| # | Arquivo | Linhas |
|---|---------|--------|
| 5.6 | `Utils/test/testRegressaoMensagem.p` | 122, 125 |
| 5.7 | `Utils/test/testRegressaoLpco.p` | 113 |

### Verificacao de impacto:
- Propriedade e PROTECTED — nao acessivel fora da hierarquia Message.
- Nenhum acesso em `thl-extensions` (subclasses thl-extensions acessam via
  `loadExternalReference()`, nao pela propriedade diretamente).
- Testes usam o nome em strings de mensagem de erro, nao como acesso a
  propriedade — atualizar os textos de assert.

---

## 6. VISIBILIDADE — `LpcoMessage.createService()` PUBLIC → PROTECTED

**Arquivo:** `Fontes/thl-lib/integration/messaging/inbound/message/LpcoMessage.cls`
**Linha:** 39

**Atual:**
```abl
method public override Service createService().
```

**Correto:**
```abl
method protected override Service createService().
```

### Justificativa:
- O metodo base `InboundMessage:createService()` e declarado `protected abstract`.
- Todas as outras 10 subclasses (DocumentoMessage, EmbarqueMessage, FreteMessage,
  NotaFiscalMessage, UsuarioMessage, EmitenteMessage, ItemMessage,
  NinaNotaFiscalMessage, LoogAiDocumentoMessage, LoogAiEmbarqueMessage)
  usam `protected override`.
- LpcoMessage e a unica com `public override` — alargamento acidental.
- Nenhum caller externo chama `createService()` diretamente em LpcoMessage.

**Impacto:** nenhum caller externo. Seguro restringir.

---

## 7. VISIBILIDADE — `OutboundMessageService.configuration` PUBLIC → PRIVATE

**Arquivo:** `Fontes/thl-lib/integration/messaging/outbound/service/OutboundMessageService.cls`

Localizar a declaracao da propriedade `configuration` e alterar de:
```abl
define public property configuration as MessageConfig no-undo get. set.
```
para:
```abl
define private property configuration as MessageConfig no-undo get. private set.
```

### Justificativa:
- Atribuida no construtor; lida apenas internamente (process, processOnline,
  scheduleProcessing). Nenhum consumidor externo le ou escreve.
- OutboundMessageService nao possui subclasses.

**Impacto:** verificado — nenhum acesso externo. Seguro restringir.

---

## 8. VISIBILIDADE — `InboundMessageService.configuration` PUBLIC → PRIVATE

**Arquivo:** `Fontes/thl-lib/integration/messaging/inbound/service/InboundMessageService.cls`

Mesma correcao do item 7: localizar a declaracao `configuration` e alterar
de PUBLIC para PRIVATE get/set.

### Justificativa:
- Atribuida nos construtores; lida internamente em receive(),
  processScheduled(), scheduleProcessing().
- Nenhum consumidor externo. Nenhuma subclasse.

**Impacto:** verificado — nenhum acesso externo. Seguro restringir.

---

## 9. VISIBILIDADE — `MessageFactory.message_` PROTECTED → PRIVATE set

**Arquivo:** `Fontes/thl-lib/integration/messaging/factory/MessageFactory.cls`

Alterar o set de PROTECTED para PRIVATE:

**Atual:**
```abl
define protected property message_ as Message no-undo get. protected set.
```

**Correto:**
```abl
define protected property message_ as Message no-undo get. private set.
```

### Justificativa:
- MessageFactory nao possui subclasses.
- O get pode permanecer PROTECTED (nao quebra nada), mas o set e usado
  apenas no construtor (interno).

**Impacto:** sem subclasses. Seguro restringir o set.

---

## 10. DEAD CODE — `MessageConfig.queryProgram` (ORFAO)

**Arquivo:** `Fontes/thl-lib/integration/messaging/core/MessageConfig.cls`

A propriedade `queryProgram` e atribuida no construtor via
`thl-objeto.programa-consulta`, mas **nunca lida por nenhum consumidor** em
todo o projeto (thl-lib, thl-extensions, telas .w/.p).

### Correcao:
1. Remover a declaracao da propriedade `queryProgram`
2. Remover a atribuicao no construtor (`queryProgram = ...`)

### Justificativa:
- Grep por `queryProgram` retorna zero hits fora da propria declaracao e
  atribuicao no construtor.
- O campo `thl-objeto.programa-consulta` continua existindo no banco — a
  propriedade e que nao tem consumidor.

**Impacto:** propriedade nunca lida. Remocao segura.

---

## 11. DEAD CODE — `OutboundObjectContext.setAdditionalData()` PRIVATE

**Arquivo:** `Fontes/thl-lib/integration/messaging/outbound/core/OutboundObjectContext.cls`
**Linha:** 49

O metodo `setAdditionalData()` e PUBLIC mas chamado apenas internamente por
`addAdditionalData()` na linha 80. Nenhum caller externo em thl-lib ou
thl-extensions.

### Correcao:
Alterar de `method public` para `method private`.

**Impacto:** verificado — nenhum caller externo. Seguro restringir.

---

## 12. DEAD CODE — `OutboundObjectContext.hasRecordId()` e `hasReferenceCode()`

**Arquivo:** `Fontes/thl-lib/integration/messaging/outbound/core/OutboundObjectContext.cls`
**Linhas:** 56-61

Ambos os metodos sao PUBLIC mas nunca chamados por nenhuma classe em thl-lib
ou thl-extensions. Provavelmente planejados para uso futuro que nunca se
concretizou.

### Opcoes (escolha uma):
**A) Remover** — se nao ha plano de uso futuro
**B) Manter mas marcar** — adicionar comentario `//TODO: avaliar remocao — nao utilizado`

**Impacto:** nenhum caller. Remocao segura.

---

## 13. DEAD CODE — `OutboundMessage.appendMessageItemByReference()`

**Arquivo:** `Fontes/thl-lib/integration/messaging/outbound/core/OutboundMessage.cls`
**Linha:** ~103

Metodo PROTECTED declarado na base OutboundMessage mas nunca invocado por
nenhuma subclasse outbound — verificado em thl-lib e thl-extensions.

### Opcoes (escolha uma):
**A) Remover** — metodo orfao
**B) Manter mas marcar** — `//TODO: avaliar remocao — nao utilizado`

**Impacto:** nenhum caller. Remocao segura.

---

## 14. BODY COMENTADO — `MessageRepository.ensureReferenceCode()`

**Arquivo:** `Fontes/thl-lib/integration/messaging/repository/MessageRepository.cls`
**Linhas:** 215-219

O metodo `ensureReferenceCode()` tem o corpo inteiro comentado — e chamado por
`createItemMessage()` (linha 132) e `loadMessageItemByReference()` (linha 154),
criando a ilusao de validacao sem efeito.

**ATENCAO:** existe um teste em `Utils/test/testMessageRepository.p` (linhas 52-63)
que valida `ensureReferenceCode sem referencia -> AppError`. Com o corpo
comentado, esse teste deveria estar falhando. Verificar antes de decidir.

### Opcoes:
**A) Descomentar o corpo** — restaurar a validacao original:
```abl
method protected void ensureReferenceCode().
    if not StringUtil:hasValue( this-object:referenceCode         ) and
       not StringUtil:hasValue( this-object:externalReferenceCode ) then
        undo, throw new ThlAppError( this-object:GetClass():TypeName, 'ensureReferenceCode', 'Codigo de referencia nao informado.' ).
end method.
```

**B) Remover o metodo e as chamadas** — se a validacao foi intencionalmente
relaxada, remover o metodo e as 2 chamadas em createItemMessage/loadMessageItemByReference.

**Recomendacao:** Opcao A (descomentar), pois o teste ja espera o AppError e o
padrao `ensureMessageCode()` na linha 210 segue exatamente esse modelo.

---

## Checklist de execucao

Apos aplicar todas as correcoes, rodar os testes de regressao:

```
run Utils/test/testRegressaoMensagem.p.
run Utils/test/testRegressaoLpco.p.
run Utils/test/testMessageRepository.p.
```

Verificar compilacao de todas as classes alteradas.

---

## Resumo

| # | Categoria | Arquivo principal | Risco |
|---|-----------|-------------------|-------|
| 1 | HEADER | MessageFactory, SingleMessage, MultipleMessage, ConfigLoader | Nenhum |
| 2 | COMMENT | EmitenteMessage | Nenhum |
| 3 | DEAD STMT | EmitenteMessage | Nenhum |
| 4 | TYPO | InboundRouteResolver + resourcen.p | Baixo |
| 5 | NAMING | Message.ExternalReferenceCode (6 arquivos) | Baixo |
| 6 | VISIB | LpcoMessage.createService | Nenhum |
| 7 | VISIB | OutboundMessageService.configuration | Nenhum |
| 8 | VISIB | InboundMessageService.configuration | Nenhum |
| 9 | VISIB | MessageFactory.message_ | Nenhum |
| 10 | DEAD CODE | MessageConfig.queryProgram | Nenhum |
| 11 | VISIB | OutboundObjectContext.setAdditionalData | Nenhum |
| 12 | DEAD CODE | OutboundObjectContext.hasRecordId/hasReferenceCode | Nenhum |
| 13 | DEAD CODE | OutboundMessage.appendMessageItemByReference | Nenhum |
| 14 | DEAD BODY | MessageRepository.ensureReferenceCode | Baixo |

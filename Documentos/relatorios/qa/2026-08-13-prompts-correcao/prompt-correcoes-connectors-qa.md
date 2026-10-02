# Prompt — Correcoes QA Estatico `connectors`

Aplique todas as correcoes abaixo no pacote `thl-lib\integration\connectors`
e na extensao `thl-extensions\integration\mmcm\connectors`.
Cada correcao esta classificada por categoria e prioridade.

---

## 1. HEADERS — Copy-paste nos cabecalhos de arquivo

9 arquivos possuem o campo `File` do header ABL incorreto (copy-paste).
Corrija o valor do campo `File :` no comentario de cabecalho para refletir
o nome real da classe.

| # | Arquivo | Linha | Valor atual | Valor correto |
|---|---------|-------|-------------|---------------|
| 1.1 | `Fontes/thl-lib/integration/connectors/core/ConnectorConfig.cls` | 3 | `ConnectorService` | `ConnectorConfig` |
| 1.2 | `Fontes/thl-lib/integration/connectors/core/ConnectorRequest.cls` | 3 | `ConnectorService` | `ConnectorRequest` |
| 1.3 | `Fontes/thl-lib/integration/connectors/core/ConnectorResponse.cls` | 3 | `ConnectorService` | `ConnectorResponse` |
| 1.4 | `Fontes/thl-lib/integration/connectors/factory/ConnectorFactory.cls` | 3 | `ConnectorService` | `ConnectorFactory` |
| 1.5 | `Fontes/thl-lib/integration/connectors/auth/interfaces/ITokenProvider.cls` | 3 | `ConnectorService` | `ITokenProvider` |
| 1.6 | `Fontes/thl-lib/integration/connectors/auth/factory/TokenProviderFactory.cls` | 3 | `ConnectorService` | `TokenProviderFactory` |
| 1.7 | `Fontes/thl-extensions/integration/mmcm/connectors/auth/TokenProvider.cls` | 3 | `ConnectorService` | `TokenProvider` |
| 1.8 | `Fontes/thl-lib/integration/connectors/enum/ConnectorTypeEnum.cls` | 3 | `ExecutionMode` | `ConnectorTypeEnum` |
| 1.9 | `Fontes/thl-lib/integration/connectors/enum/MethodTypeEnum.cls` | 3 | `MethodType` | `MethodTypeEnum` |

**Impacto:** zero — comentario, nao afeta compilacao nem comportamento.

---

## 2. TYPO — RestConnector `headersParamter`

**Arquivo:** `Fontes/thl-lib/integration/connectors/types/RestConnector.cls`
**Linha:** 232

Parametro do metodo PROTECTED `setHeader()` com typo.

**Atual:**
```abl
method protected void setHeader ( input request         as HttpWebRequest,
                                  input headersParamter as character     ).
```

**Correto:**
```abl
method protected void setHeader ( input request          as HttpWebRequest,
                                  input headersParameter as character     ).
```

Renomear tambem as 2 referencias internas ao parametro (linhas 237 e 239):
- `headersParamter` → `headersParameter`

**Impacto:** parametro local de metodo PROTECTED. Nenhum caller externo.
RestConnector nao possui subclasses. Seguro renomear.

---

## 3. DEAD CODE — IntegrationConnector `connectorResponse` (variavel orfa)

**Arquivo:** `Fontes/thl-lib/integration/connectors/types/IntegrationConnector.cls`
**Linha:** 17

Remover a variavel de instancia:
```abl
define variable connectorResponse as ConnectorResponse no-undo.
```

### Justificativa:
- Declarada na classe abstrata base, nunca lida nem escrita.
- A unica subclasse (`RestConnector`) cria sua propria variavel local
  `connectorResponse` dentro de `execute()` (linha 35).
- A variavel da superclasse e dead code puro.

**Impacto:** nenhum — variavel nunca referenciada. Seguro remover.

---

## 4. DEAD CODE — AuthenticationConfig `tokenMethod` (propriedade orfa)

**Arquivo:** `Fontes/thl-lib/integration/connectors/auth/core/AuthenticationConfig.cls`
**Linha:** 22

Remover a propriedade:
```abl
define public property tokenMethod as character no-undo get. set.
```

E remover o parametro + atribuicao correspondente no metodo `initialize()`:

**No metodo `initialize()` (linha 101-102):** remover o parametro `tokenMethod as character` da
assinatura e a linha de atribuicao `this-object:tokenMethod = tokenMethod` (linha 119).

**Nos construtores que chamam `initialize()`:**
- Construtor default (linha 44-61): remover o 2o argumento `''`
- Construtor com connectionCode (linha 79-93): remover o argumento `'POST'` (linha 80)

### Justificativa:
- Atribuida como `'POST'` no initialize(), nunca lida por nenhum consumidor.
- `RestConnector:executeTokenRequest()` define `tokenRequest:methodType = MethodTypeEnum:POST:getValue()`
  diretamente (linha 147), ignorando `tokenMethod`.
- Propriedade orfa — residuo de design inicial.

**Impacto:** propriedade nunca lida. Remocao segura.

---

## 5. USING MORTO — AuthenticationConfig → AuthenticationRepository

**Arquivo:** `Fontes/thl-lib/integration/connectors/auth/core/AuthenticationConfig.cls`
**Linha:** 13

Remover a linha:
```abl
using thl-lib.integration.connectors.auth.repository.AuthenticationRepository.
```

### Justificativa:
- `AuthenticationRepository` nunca e instanciada no corpo de `AuthenticationConfig`.
- Import residual de refatoracao anterior onde `saveToken()` chamava
  `new AuthenticationRepository():persistToken(...)`.
- Apos a refatoracao, `saveToken()` apenas atribui em memoria.

**Impacto:** zero — import nao utilizado. Remocao segura.

---

## 6. SCOPE — ConnectorConfig `environmentResource` (propriedade → local)

**Arquivo:** `Fontes/thl-lib/integration/connectors/core/ConnectorConfig.cls`

Converter a propriedade de instancia em variavel local do construtor:

**Remover (linha 31):**
```abl
define private property environmentResource as EnvironmentResource  no-undo get. set.
```

**No construtor (linhas 41-45), converter para variavel local:**
```abl
constructor public ConnectorConfig ( programName        as character ,
                                     parameterCode      as character ,
                                     routeParameterCode as character ).

    define variable pathCode             as character           no-undo.
    define variable environmentResource  as EnvironmentResource no-undo.

    assign environmentResource        = new EnvironmentResource( programName )
           this-object:connectionCode = environmentResource:getEnvironmentVariable( parameterCode      )
           pathCode                   = environmentResource:getEnvironmentVariable( routeParameterCode ).
```

### Justificativa:
- `environmentResource` e criado no construtor, usado em 2 linhas (44-45),
  e depois mantido vivo como propriedade sem necessidade.
- Apos o construtor, nenhum metodo acessa a propriedade.
- Converter para variavel local permite GC imediato.

**Impacto:** sem impacto externo — propriedade era PRIVATE. O segundo
construtor (linha 79) nao usa `environmentResource`.

---

## 7. VISIBILIDADE — ConnectorConfig `connectionCode` PUBLIC → PRIVATE get

**Arquivo:** `Fontes/thl-lib/integration/connectors/core/ConnectorConfig.cls`
**Linha:** 23

**Atual:**
```abl
define public property connectionCode as character no-undo get. set.
```

**Correto:**
```abl
define private property connectionCode as character no-undo get. private set.
```

### Justificativa:
- Atribuido no construtor; lido apenas internamente (find, erros, new AuthenticationConfig).
- Nenhum consumidor externo le `connectorConfig:connectionCode`.
- Verificado em thl-lib e thl-extensions: zero hits.

**Impacto:** verificado — nenhum acesso externo. Seguro restringir.

---

## 8. VISIBILIDADE — AuthenticationConfig `connectionCode` PUBLIC → PRIVATE get

**Arquivo:** `Fontes/thl-lib/integration/connectors/auth/core/AuthenticationConfig.cls`
**Linha:** 40

**Atual:**
```abl
define public property connectionCode as character no-undo get. set.
```

**Correto:**
```abl
define private property connectionCode as character no-undo get. private set.
```

### Justificativa:
- Atribuido no construtor; lido apenas internamente (find, guard, erros).
- Anteriormente era lido externamente por `RestConnector:executeTokenRequest()`
  via `authentication:connectionCode` para chamar
  `AuthenticationRepository:persistToken()` — mas essa chamada foi removida
  na refatoracao.
- Nenhum consumidor externo atual.

**Impacto:** verificado — nenhum acesso externo. Seguro restringir.

---

## 9. PADRAO — RestConnector `routine-level` → `block-level`

**Arquivo:** `Fontes/thl-lib/integration/connectors/types/RestConnector.cls`
**Linha:** 29

**Atual:**
```abl
routine-level on error undo, throw.
```

**Correto:**
```abl
block-level on error undo, throw.
```

### Justificativa:
- Todas as demais 12 classes do pacote (e do projeto THL-Library como um todo)
  usam `block-level on error undo, throw`.
- `routine-level` tem semantica de undo mais ampla — qualquer erro em
  qualquer bloco dentro da rotina faz undo de toda a rotina.
- `block-level` e mais granular e e o padrao do framework.
- **Atencao:** `RestConnector:execute()` tem um `catch` intencional (linhas 57-65)
  que captura erros e retorna `connectorResponse` com erro. Verifique que
  a mudanca para `block-level` nao altera o comportamento do catch.
  Na pratica, o `catch` dentro de `execute()` continuara funcionando
  identicamente porque ele ja esta no escopo do metodo.

**Impacto:** baixo — semanticamente equivalente neste caso. Testar.

---

## 10. PADRAO — TokenProvider (mmcm) `AppError` → `ThlAppError`

**Arquivo:** `Fontes/thl-extensions/integration/mmcm/connectors/auth/TokenProvider.cls`

Converter as 5 ocorrencias de `new AppError(msg, code)` para o padrao
THL-Library `new ThlAppError(className, methodName, msg)`.

**Linhas a alterar:** 27-29, 34-38, 40-44, 48-52, 54-58

Adicionar o USING:
```abl
using thl-lib.core.error.ThlAppError.
```

Exemplo de conversao (linha 27-29):

**Atual:**
```abl
undo, throw new AppError(
    'TokenProvider: Resposta de autenticacao nao contem o node data.',
    17006
).
```

**Correto:**
```abl
undo, throw new ThlAppError(
    this-object:GetClass():TypeName,
    'parsingToken',
    'Resposta de autenticacao nao contem o node data.'
).
```

Repetir para as demais 4 ocorrencias, todas dentro do metodo `parsingToken`.

**Impacto:** muda formato da mensagem de erro (adiciona prefixo TypeName:method).
Nao altera fluxo de controle.

---

## 11. DECISAO — AuthenticationRepository (classe sem uso em producao)

**Arquivo:** `Fontes/thl-lib/integration/connectors/auth/repository/AuthenticationRepository.cls`

`AuthenticationRepository` nunca e instanciada em codigo de producao — apenas
em testes (`testConnectorAuth.p`). O metodo `persistToken()` persiste o token
no banco (`thl-conexao-rest-autenticacao`), mas na versao atual do codigo o
token e persistido apenas em memoria via `AuthenticationConfig:saveToken()`.

### Opcoes:
**A) Manter** — util para futuro cenario onde persistencia em DB seja
reativada apos execucao do token request.
**B) Remover** — se a decisao e que o token nunca sera persistido em DB
pelo fluxo automatico. Atualizar `testConnectorAuth.p` (remover testes 7 e 8).

**Recomendacao:** Manter (opcao A) — a classe e funcional, testada, e pode
ser reintegrada ao fluxo principal quando necessario (ex: multiserver cache).

---

## Checklist de execucao

Apos aplicar todas as correcoes, rodar os testes:

```
run Utils/test/testConn.p.
run Utils/test/testConnectorAuth.p.
```

Verificar compilacao de todas as classes alteradas.

---

## Resumo

| # | Categoria | Arquivo principal | Risco |
|---|-----------|-------------------|-------|
| 1 | HEADER | 9 arquivos | Nenhum |
| 2 | TYPO | RestConnector (headersParamter) | Nenhum |
| 3 | DEAD CODE | IntegrationConnector.connectorResponse | Nenhum |
| 4 | DEAD CODE | AuthenticationConfig.tokenMethod | Nenhum |
| 5 | IMPORT | AuthenticationConfig USING morto | Nenhum |
| 6 | SCOPE | ConnectorConfig.environmentResource | Nenhum |
| 7 | VISIB | ConnectorConfig.connectionCode | Nenhum |
| 8 | VISIB | AuthenticationConfig.connectionCode | Nenhum |
| 9 | PADRAO | RestConnector routine-level | Baixo |
| 10 | PADRAO | TokenProvider AppError | Nenhum |
| 11 | DECISAO | AuthenticationRepository | Manter |

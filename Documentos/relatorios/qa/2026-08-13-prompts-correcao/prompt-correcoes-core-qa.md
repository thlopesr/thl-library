# Prompt — Correcoes QA Estatico `core`

Aplique todas as correcoes abaixo no pacote `thl-lib\core`.
Cada correcao esta classificada por categoria e prioridade.
**Regra geral:** nao altere contratos publicos consumidos por `thl-extensions`
sem verificar impacto. As correcoes abaixo ja foram verificadas quanto a
callers — siga as instrucoes de impacto em cada item.

---

## 1. RENAME — ThlAppError → ThlError

**Arquivo principal:** `Fontes/thl-lib/core/error/ThlAppError.cls`

Renomear a classe `ThlAppError` para `ThlError`:

### 1.1 — Renomear o arquivo

Renomear `ThlAppError.cls` → `ThlError.cls`

### 1.2 — Alterar a declaracao da classe

**Linha 15 (class statement):**

**Atual:**
```abl
class thl-lib.core.error.ThlAppError inherits Progress.Lang.AppError:
```

**Correto:**
```abl
class thl-lib.core.error.ThlError inherits Progress.Lang.AppError:
```

### 1.3 — Alterar os 4 construtores

Renomear `ThlAppError` → `ThlError` no nome de cada construtor.

### 1.4 — Alterar USANDO e instanciacoes em todos os callers

Fazer find-replace global em todo o projeto:

| Busca | Substituicao |
|-------|--------------|
| `using thl-lib.core.error.ThlAppError.` | `using thl-lib.core.error.ThlError.` |
| `new ThlAppError(` | `new ThlError(` |
| `thl-lib.core.error.ThlAppError` (TYPE-NAME qualificado) | `thl-lib.core.error.ThlError` |

### Escopo de impacto verificado:

- **124 instanciacoes** (`new ThlAppError(`) em **44 arquivos**
- **~44 linhas** `using thl-lib.core.error.ThlAppError`
- Pacotes afetados: `thl-lib` (41 arquivos), `thl-extensions` (3 arquivos), `Utils/test` (2 arquivos)
- Nenhuma logica muda — renomeacao puramente mecanica

### Justificativa:
- O nome `ThlAppError` combina dois prefixos: `Thl` (framework) + `App` (herdado de Progress.Lang.AppError)
- `App` e confuso: o leitor interpreta "erro de aplicacao" quando e "erro padronizado do framework"
- `ThlError` mantem a identidade THL (importante para distinguir de erros Progress nativos) e elimina a confusao

**Impacto:** alto em volume, zero em risco — renomeacao mecanica. Exige compilacao completa apos aplicacao.

---

## 2. TYPO — ErrorHandler `isValideErrorObject`

**Arquivo:** `Fontes/thl-lib/core/error/ErrorHandler.cls`
**Linha:** 146

Parametro do metodo PUBLIC com typo: `isValide` deveria ser `isValid`.

**Atual:**
```abl
method public logical isValideErrorObject ( errorObject as Error).
```

**Correto:**
```abl
method public logical isValidErrorObject ( errorObject as Error).
```

Renomear tambem as 2 chamadas internas (linhas 134 e 163):
- `isValideErrorObject(errorObject)` → `isValidErrorObject(errorObject)`

### Verificacao de impacto:
- Metodo PUBLIC mas usado apenas internamente (linhas 134 e 163 da propria classe)
- Zero callers externos em thl-lib e thl-extensions — seguro renomear

**Impacto:** nenhum caller externo. Seguro renomear.

---

## 3. DEAD CODE — ErrorHandler `createError()` e `clearErrors()`

**Arquivo:** `Fontes/thl-lib/core/error/ErrorHandler.cls`

### 3.1 — Remover `createError()` (linha 45)

```abl
method public void createError().
    this-object:clearErrors().
end method.
```

### Justificativa:
- Metodo publico que apenas chama `clearErrors()`
- Nunca chamado por nenhuma classe — nem interna nem externamente
- Semantica confusa: "createError" sugere criacao de erro mas limpa erros
- Vestigio de design anterior

### 3.2 — Remover `clearErrors()` (linha 41)

```abl
method public void clearErrors().
    empty temp-table ttError no-error.
end method.
```

### Justificativa:
- Unico caller era `createError()` (tambem orfao)
- Nenhum caller externo em todo o projeto
- Com remocao de `createError()`, `clearErrors()` perde seu unico caller

**Impacto:** nenhum caller. Remocao segura.

---

## 4. VISIBILIDADE — ErrorHandler `getErrorJson()` PUBLIC → PRIVATE

**Arquivo:** `Fontes/thl-lib/core/error/ErrorHandler.cls`
**Linha:** 150

**Atual:**
```abl
method public JsonObject getErrorJson(input errorObject as Error).
```

**Correto:**
```abl
method private JsonObject getErrorJson(input errorObject as Error).
```

### Justificativa:
- Chamado apenas internamente por `getErrorJsonText()` (linha 199)
- Nenhum caller externo le o `JsonObject` diretamente — todos usam `getErrorJsonText()`
- Verificado em thl-lib e thl-extensions: zero hits para `getErrorJson(` fora desta classe

**Impacto:** nenhum caller externo. Seguro restringir.

---

## 5. DEAD CODE — EnvironmentUtil `reset()`

**Arquivo:** `Fontes/thl-lib/core/environment/EnvironmentUtil.cls`
**Linha:** 32

Remover o metodo:

```abl
method public static final void reset().
    assign environment = ''.
end method.
```

### Justificativa:
- Metodo que limpa o cache de ambiente
- Nunca chamado por nenhum arquivo do projeto (thl-lib, thl-extensions, Utils, telas)
- Provavel utilitario de debug/teste que nunca foi integrado

**Impacto:** nenhum caller. Remocao segura.

---

## 6. PADRAO — ContextService `routine-level` → `block-level`

**Arquivo:** `Fontes/thl-lib/core/context/ContextService.cls`
**Linha:** 11

**Atual:**
```abl
routine-level on error undo, throw.
```

**Correto:**
```abl
block-level on error undo, throw.
```

### Justificativa:
- 5 das 7 classes do pacote core usam `block-level`
- `routine-level` tem semantica de undo mais ampla
- `block-level` e o padrao do framework THL-Library
- ContextService tem apenas 2 metodos static simples — a mudanca e semanticamente neutra

**Impacto:** baixo — semanticamente equivalente neste caso. Testar.

---

## 7. PADRAO — EnvironmentUtil `routine-level` → `block-level`

**Arquivo:** `Fontes/thl-lib/core/environment/EnvironmentUtil.cls`
**Linha:** 12

**Atual:**
```abl
routine-level on error undo, throw.
```

**Correto:**
```abl
block-level on error undo, throw.
```

### Justificativa:
- Mesma inconsistencia do item 6
- EnvironmentUtil tem apenas 2 metodos static simples — mudanca semanticamente neutra

**Impacto:** baixo — semanticamente equivalente neste caso. Testar.

---

## 8. DECISAO — ErrorHandler herda `Progress.Lang.AppError` (heranca desnecessaria)

**Arquivo:** `Fontes/thl-lib/core/error/ErrorHandler.cls`
**Linha:** 16

`ErrorHandler` herda de `AppError` mas nunca e lancado como excecao:
- Nenhum `undo, throw new ErrorHandler(...)` em todo o projeto
- Nenhum `catch errorHandler as ErrorHandler` em todo o projeto
- Nenhum `type-of(x, ErrorHandler)` em todo o projeto
- Ele usa `ThlAppError` internamente para criar erros lancaveis (via `getError()`)
- A heranca de `AppError` nao contribui funcionalidade — `ErrorHandler` e um acumulador, nao uma excecao

### Opcoes:
**A) Manter** — nenhum bug causado pela heranca. Refatoracao futura quando
o ErrorHandler for revisado (requer atualizar callers de `getErrorStatusCode`
e `getErrorMessage` que recebem `Error`, nao `ErrorHandler`).

**B) Remover heranca** — alterar para:
```abl
class thl-lib.core.error.ErrorHandler:
```
Verificar se alguma funcionalidade herdada de `AppError` e usada internamente
(nenhuma detectada — todos os metodos trabalham com o parametro `errorObject`
externo, nao com `this-object` como AppError).

**Recomendacao:** Manter (opcao A) — refatoracao de baixa prioridade.
A heranca nao causa bugs, e a remocao exigiria testes adicionais para
garantir que nenhum comportamento implicito de `AppError` seja quebrado.

---

## Checklist de execucao

Apos aplicar as correcoes 1-7:

1. Compilar todas as classes do pacote `core`:
   - `thl-lib/core/error/ThlError.cls` (renomeada)
   - `thl-lib/core/error/ErrorHandler.cls`
   - `thl-lib/core/context/ContextService.cls`
   - `thl-lib/core/environment/EnvironmentUtil.cls`

2. Compilar todas as classes que referenciam `ThlAppError` (agora `ThlError`):
   - 44 arquivos em thl-lib + 3 em thl-extensions

3. Rodar testes existentes:
```
run Utils/test/testConn.p.
run Utils/test/testConnectorAuth.p.
run Utils/test/testRegressaoMensagem.p.
run Utils/test/testRegressaoLpco.p.
```

---

## Resumo

| # | Categoria | Arquivo principal | Risco |
|---|-----------|-------------------|-------|
| 1 | RENAME | ThlAppError → ThlError (44 arquivos) | Baixo (volume alto, mecanico) |
| 2 | TYPO | ErrorHandler.isValideErrorObject | Nenhum |
| 3 | DEAD CODE | ErrorHandler.createError() + clearErrors() | Nenhum |
| 4 | VISIB | ErrorHandler.getErrorJson() | Nenhum |
| 5 | DEAD CODE | EnvironmentUtil.reset() | Nenhum |
| 6 | PADRAO | ContextService routine-level | Baixo |
| 7 | PADRAO | EnvironmentUtil routine-level | Baixo |
| 8 | DECISAO | ErrorHandler inherits AppError | Manter |

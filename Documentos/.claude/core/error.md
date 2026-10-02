# Pacote: core/error

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| ThlError | Subclasse de `AppError` que formata a mensagem como `descricao [Classe.metodo]`; 4 construtores incluindo wrapping de inner error | Nenhum | `Progress.Lang.AppError` | Praticamente todas as classes da biblioteca |
| ErrorHandler | Acumula erros e permite lançá-los como `AppError` ou serializar em JSON; herda `AppError` | Nenhum | `Progress.Lang.*`, `Progress.Json.ObjectModel.*`, `ThlError` | Message, InboundMessage, OutboundMessageService, ConnectorService, e outros |

---

## ThlError

**Caminho:** `thl-lib\core\error\ThlError.cls`

**Namespace ABL:** `thl-lib.core.error.ThlError`

**Responsabilidade:** Padroniza o formato da mensagem de erro em `descricao [NomeClasse.nomeMetodo]`, tornando as exceções rastreáveis sem necessidade de logs adicionais. Herda de `Progress.Lang.AppError`. Quatro construtores cobrem os cenários: erro formatado padrão, código explícito, mensagem direta (usado pelo `ErrorHandler`) e wrapping de inner error para preservação de stack.

**Padrão de projeto:** Nenhum (subclasse de infraestrutura).

**INHERITS / IMPLEMENTS:** `inherits Progress.Lang.AppError`

**Dependências diretas THL:** Nenhuma.

**Propriedades públicas:** Nenhuma (herdadas de `AppError`).

**Métodos públicos (construtores):**

| Assinatura | Descrição |
|---|---|
| `constructor public ThlError( className as character, methodName as character, textMessage as character )` | Formata `textMessage [className.methodName]` com errorNumber padrão `17006`. |
| `constructor public ThlError( errorMessage as character, errorNumber as integer )` | Mensagem já formatada (sem substituição); usado pelo `ErrorHandler` internamente. |
| `constructor public ThlError( className as character, methodName as character, textMessage as character, errorNumber as integer )` | Mesmo formato, com errorNumber explícito. |
| `constructor public ThlError( className as character, methodName as character, innerError as Progress.Lang.Error )` | Formata `Erro em [className.methodName]` e replica todas as mensagens do `innerError` via `AddMessage` — preserva a stack da exceção original. |

**Observações:**
- Código de erro padrão `17006` é o código Totvs genérico para erros de aplicação.
- O formato da mensagem é `textMessage [className.methodName]` (mensagem na frente, contexto no sufixo) — invertido em relação ao padrão antigo `[Classe.metodo] msg`.
- Nome da classe foi alterado de `ThlAppError` para `ThlError` — todos os `USING` e `new ThlAppError(...)` devem ser migrados para `ThlError`.

---

## ErrorHandler

**Caminho:** `thl-lib\core\error\ErrorHandler.cls`

**Namespace ABL:** `thl-lib.core.error.ErrorHandler`

**Responsabilidade:** Acumula múltiplos erros numa temp-table interna e permite lançá-los coletivamente como `AppError`, verificar existência de erros, e serializar para JSON. Herda de `Progress.Lang.AppError`. Instanciar com `className` (e opcionalmente `methodName`/`stepName`) para que `addError` produza mensagens formatadas automaticamente.

**Padrão de projeto:** Nenhum (acumulador de erros).

**INHERITS / IMPLEMENTS:** `inherits Progress.Lang.AppError`

**Dependências diretas THL:** `ThlError`.

**Propriedades públicas:** Nenhuma (propriedades `className`, `methodName`, `stepName` são privadas).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public ErrorHandler()` | Construtor sem nome de classe. |
| `constructor public ErrorHandler( className as character )` | Construtor com nome de classe para formatação de mensagens. |
| `constructor public ErrorHandler( className as character, methodName as character, stepName as character )` | Construtor completo com classe, método e etapa para formatação detalhada. |
| `method public void addError( errorNumber as integer, errorMessage as character )` | Adiciona um erro à temp-table, formatando a mensagem via `createErrorMessage`. |
| `method public logical hasErrors()` | Retorna `true` se há registros na temp-table. |
| `method public AppError getError()` | Constrói e retorna um `ThlError` com todas as mensagens acumuladas. Retorna `?` se sem erros. |
| `method public void throwIfHasErrors()` | Lança o `AppError` acumulado se `hasErrors()`. |
| `method public void throwError( errorNumber as integer, errorMessage as character )` | Adiciona um erro e lança imediatamente via `throwIfHasErrors`. |
| `method public void throwError( methodName as character, errorMessage as character )` | Formata `[className.methodName] msg` com código `17006` e lança. |
| `method public void throwError( errorNumber as integer, methodName as character, errorMessage as character )` | Formata `[className.methodName] msg` com errorNumber explícito e lança. |
| `method public integer getErrorStatusCode( input errorObject as Error )` | Retorna `GetMessageNum(1)` do erro ou `500` se inválido. |
| `method public character getErrorMessage( errorObject as Error )` | Concatena todas as mensagens do erro (limitado a 200 caracteres). |
| `method public logical isValidErrorObject( errorObject as Error )` | Retorna `true` se o objeto de erro é válido e tem mensagens. |
| `method public longchar getErrorJsonText( input errorObject as Error )` | Retorna o JSON de erro `{ "success": false, "errors": [...] }` como `longchar` UTF-8. |

**Métodos privados relevantes:**

| Assinatura | Descrição |
|---|---|
| `method private character createErrorMessage( errorMessage as character )` | Formata mensagem usando `methodName`/`stepName` da instância. |
| `method private character createErrorMessage( errorMessage as character, methodName as character, stepName as character )` | Formata `msg [className.methodName]` ou `msg [stepName][className.methodName]` quando `stepName` não vazio. |
| `method private JsonObject getErrorJson( input errorObject as Error )` | Serializa o erro em JSON — **privado** (acesso somente via `getErrorJsonText`). |

**Removidos (vs versão anterior):**
- `clearErrors()` — removido
- `createError()` — removido (era alias de `clearErrors`)

**Tratamento de erro:** Não captura erros internamente. `getErrorJsonText` retorna JSON com mensagem genérica quando o objeto de erro é inválido.

**Observações:**
- `getErrorJson` é **privado** — use `getErrorJsonText` para obter a serialização.
- A mensagem em `getErrorMessage` é truncada a 200 caracteres — mensagens muito longas podem perder informação.
- `addError` agora formata a mensagem automaticamente via `createErrorMessage` — ao contrário da versão anterior onde a mensagem era gravada sem formatação.

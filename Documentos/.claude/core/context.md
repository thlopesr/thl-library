# Pacote: core/context

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| ContextService | Utilitários estáticos de contexto de execução: usuário do SO, usuário logado no Datasul e call stack formatado | Nenhum | `thl/api/geterpuser.p` (ponte para `c-seg-usuario`) | AuditLogService, AuditoriaService, MensageriaService |

---

## ContextService

**Caminho:** `thl-lib\core\context\ContextService.cls`

**Namespace ABL:** `thl-lib.core.context.ContextService`

**Responsabilidade:** Fornece utilitários estáticos sobre o contexto de execução atual: o nome do usuário do sistema operacional (variável `USERNAME`), o usuário logado no Datasul (`c-seg-usuario`) e a pilha de programas chamadores formatada para diagnóstico.

**Padrão de projeto:** Nenhum identificado (utilitário estático puro).

**INHERITS / IMPLEMENTS:** Nenhum. Declarado como `serializable`.

**Dependências diretas THL:** Nenhuma classe. Depende do procedure `thl/api/geterpuser.p` (camada `Fontes\thl`), chamado por caminho literal via `RUN`, portanto relativo ao PROPATH.

**Propriedades públicas:** Nenhuma.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final character getUser()` | Retorna o valor da variável de ambiente `USERNAME` do sistema operacional. |
| `method public static final character getErpUser()` | Retorna o usuário logado no Datasul (`c-seg-usuario`). Executa `run thl/api/geterpuser.p.` e devolve o `return-value`. |
| `method public static final character getProgramsCaller()` | Percorre `program-name(level)` de 1 até `?` e retorna a stack formatada como `"1 - nome \| 2 - nome \| ..."`. |

**Ponte `thl/api/geterpuser.p`:** a variável `c-seg-usuario` é `NEW GLOBAL SHARED`, e uma classe OO não consegue declarar variáveis compartilhadas. Por isso a leitura é delegada a um procedure, que declara `define new global shared variable c-seg-usuario as character format 'x(12)' no-undo.` e faz `return c-seg-usuario.`

- Com `NEW GLOBAL`, se a sessão ainda não tiver criado a variável, o procedure a cria vazia, e `getErpUser()` devolve `''`, sem erro. Fora de uma sessão Datasul logada (batch, PASOE sem login Datasul, testes), o resultado é string vazia.
- O `RUN` usa caminho literal: `Fontes` (ou a raiz equivalente no servidor) precisa estar no PROPATH para `thl/api/geterpuser.p` ser encontrado. Se o arquivo não for encontrado, o erro aparece só em tempo de execução (293); a compilação da classe não acusa.

**Tratamento de erro:** Nenhum `CATCH` nem uso de `ErrorHandler`. Não lança exceções explícitas; uma falha no `RUN` propaga via `block-level on error undo, throw`.

**Pontos de extensão:** Nenhum.

**Observações:**
- `getUser()` (usuário do SO) e `getErpUser()` (usuário do ERP) **não são intercambiáveis**. `AuditLogService` grava `getErpUser()` em `thl-audit-registro.usuario`, `getUser()` em `usuario-so` e `getProgramsCaller()` em `programa-executado`; `AuditoriaService` e `MensageriaService` usam `getErpUser()`. (Até 2026-09-24 o `AuditLogService` gravava os dois usuários trocados — registros antigos têm `usuario` = usuário do SO.)
- Histórico: `getDatasulUser()` foi criado em 2026-09-15 com a ponte em `thl-lib\core\context\getdatasuluser.p`. Em 2026-09-24 a ponte foi movida e renomeada para `Fontes\thl\api\geterpuser.p`, e o `RUN` foi atualizado. Com isso, thl-lib passa a depender da camada `Fontes\thl` também aqui, além de `thl0220z.p` (`SchedulingService`, `InboundSchedulingService`). Depois foi renomeado para `getErpUser()` (callers atualizados: `AuditoriaService`, `MensageriaService`, `AuditLogService`).

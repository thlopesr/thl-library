---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, core, environment]
updated: 2026-10-13
---

# Pacote: core/environment

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| EnvironmentUtil | Cache estático do código de ambiente resolvido via propath | Nenhum | EnvironmentRepository, StringUtil | EnvironmentResource, EnvironmentContext |
| EnvironmentContext | Resolve o código de parâmetro ativo percorrendo o call stack | Nenhum | EnvironmentRepository, ThlError | EnvironmentResource |
| EnvironmentResource | Fachada de instância para leitura de variáveis de ambiente por parâmetro | Fachada (Facade) | EnvironmentUtil, EnvironmentContext, EnvironmentRepository, StringUtil, ThlError | ConnectorConfig, EmailMessageFactory, e qualquer classe que precise de variáveis de ambiente |
| EnvironmentRepository | Acesso direto às tabelas `thl-ambiente*` do banco | Repository | ThlError | EnvironmentUtil, EnvironmentContext, EnvironmentResource |

---

## EnvironmentUtil

**Caminho:** `thl-lib\core\environment\EnvironmentUtil.cls`

**Namespace ABL:** `thl-lib.core.environment.EnvironmentUtil`

**Responsabilidade:** Mantém em memória o código do ambiente corrente (resolvido uma única vez via `propath` na primeira chamada).

**Padrão de projeto:** Nenhum (propriedade estática como cache simples).

**INHERITS / IMPLEMENTS:** Nenhum. Declarado como `serializable`.

**Dependências diretas THL:** `EnvironmentRepository`, `StringUtil`.

**Propriedades públicas:** Nenhuma pública (a propriedade `environment` é `private static`).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final character getEnvironment()` | Retorna o código de ambiente (usa cache; resolve via `EnvironmentRepository:findEnvironmentCodeByPropath` na primeira chamada). |

**Tratamento de erro:** Delega a `EnvironmentRepository`; se não encontrar ambiente, a exceção sobe de lá.

**Observações:** Método `reset()` foi removido.

**Pontos de extensão:** Nenhum.

---

## EnvironmentContext

**Caminho:** `thl-lib\core\environment\EnvironmentContext.cls`

**Namespace ABL:** `thl-lib.core.environment.EnvironmentContext`

**Responsabilidade:** Gerencia o contexto de execução do módulo de ambiente: percorre o call stack procurando o primeiro programa que possua um código de parâmetro cadastrado na tabela `thl-ambiente-param-prog`. Armazena `environmentParameter` e `programName` como propriedades estáticas para reuso na sessão.

**Padrão de projeto:** Nenhum.

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `EnvironmentRepository`, `ThlError`.

**Propriedades públicas:**

| Nome | Tipo | Acesso set |
|---|---|---|
| `environmentParameter` | `character` | `private set` |
| `programName` | `character` | `private set` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final character setParameterCode()` | Percorre o call stack via `program-name(level)`, normaliza cada nome e consulta `EnvironmentRepository:findParameterCodeByProgram`. Retorna o código quando encontrado; lança `ThlError` se nenhum programa do stack possuir cadastro. |
| `method public static final character normalizeProgramName( input program as character )` | Remove path e extensão do nome de programa, retornando apenas o identificador (ex: `"dbo/ft4001a.p"` → `"ft4001a"`). |

**Tratamento de erro:** Lança `ThlError` quando nenhum programa no call stack possuir código de parâmetro cadastrado.

**Pontos de extensão:** Nenhum.

---

## EnvironmentResource

**Caminho:** `thl-lib\core\environment\EnvironmentResource.cls`

**Namespace ABL:** `thl-lib.core.environment.EnvironmentResource`

**Responsabilidade:** Fachada de instância que resolve `environment` e `parameterCode` no construtor e oferece métodos de leitura de variáveis de ambiente. Suporta dois construtores: com nome de programa explícito e sem (resolve automaticamente pelo call stack via `EnvironmentContext`). Também oferece overloads estáticos para consulta direta sem instância.

**Padrão de projeto:** Fachada (Facade) — encapsula a coordenação entre `EnvironmentUtil`, `EnvironmentContext` e `EnvironmentRepository`.

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `EnvironmentContext`, `EnvironmentUtil`, `EnvironmentRepository`, `StringUtil`, `ThlError`.

**Propriedades públicas:** Nenhuma (propriedades `environment` e `parameterCode` são privadas).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public EnvironmentResource( programName as character )` | Resolve ambiente e parâmetro pelo nome de programa informado. Lança `ThlError` se parâmetro não encontrado. |
| `constructor public EnvironmentResource()` | Resolve parâmetro automaticamente pelo call stack via `EnvironmentContext:setParameterCode()`. |
| `method public character getEnvironmentVariable()` | Retorna o valor da variável padrão do parâmetro (variableCode = ''). |
| `method public character getEnvironmentVariable( variableCode as character )` | Retorna o valor de uma variável específica do parâmetro. |
| `method public character getRequiredEnvironmentVariable( variableCode as character )` | Variável obrigatória: valor sem espaços nas pontas; ausente ou em branco lança `ThlError` (17006) dizendo a variável, o parâmetro e o ambiente a configurar no thl0002. A validação é `StringUtil:requireValue` (versão com classe e método): o erro sai com origem `EnvironmentResource.getRequiredEnvironmentVariable`. |
| `method public character getRequiredEnvironmentVariable( variable as Progress.Lang.Enum )` | Mesma regra, com o código vindo do membro do enum (`StringUtil:enumToCode`). |
| `method public static character getEnvironmentVariable( codeParameter as character, variableCode as character )` | Consulta direta sem instância, para o ambiente corrente. |
| `method public static character getEnvironmentVariable( environment as character, codeParameter as character, variableCode as character )` | Consulta direta com ambiente, parâmetro e variável explícitos. |

**Tratamento de erro:** Lança `ThlError` no construtor se parâmetro não encontrado.

**Pontos de extensão:** Nenhum.

---

## EnvironmentRepository

**Caminho:** `thl-lib\core\environment\repository\EnvironmentRepository.cls`

**Namespace ABL:** `thl-lib.core.environment.repository.EnvironmentRepository`

**Responsabilidade:** Acesso direto às tabelas de ambiente do banco Datasul (`thl-ambiente`, `thl-ambiente-param-prog`, `thl-ambiente-param-variavel`). Todos os métodos são estáticos e de leitura (no-lock), com fallback para `'*'` no `findVariableValue`.

**Padrão de projeto:** Repository.

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `ThlError`.

**Tabelas acessadas:** `thl-ambiente`, `thl-ambiente-param-prog`, `thl-ambiente-param-variavel`.

**Propriedades públicas:** Nenhuma.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final character findEnvironmentCodeByPropath( input propathValue as character )` | Busca ambiente pelo campo `ip` no propath (`for each` com `index( propathValue, ip ) > 0`; o primeiro que casar vence). Se nenhum casar, lança `ThlError` "Ambiente nao identificado." — o `if available` após o laço não devolve fallback (⚠️ leitura estática; confirmar em execução). |
| `method public static final character findParameterCodeByProgram( input programName as character )` | Busca o código de parâmetro de ambiente associado ao programa. Retorna `''` se não encontrado (não lança erro). |
| `method public static final character findVariableValue( input environmentCode as character, input parameterCode as character, input variableCode as character )` | Busca o valor da variável para ambiente/parâmetro/variável específicos. Aplica fallback para `cod-ambiente = '*'`. Retorna `''` se não encontrado. |

**Tratamento de erro:** `findEnvironmentCodeByPropath` lança `ThlError`. Os demais retornam `''` quando não encontram.

**Observações:** Usa `release` no bloco `finally` para liberar buffers estáticos após cada consulta.

# Módulo de Variáveis de Ambiente — THL-Lib

**Módulo:** `thl-lib.core.environment`  
**Versão:** 1.0  
**Autor:** Thiago Lopes  
**Data:** 2025  
**Status:** Ativo

---

## 1. Objetivo

Eliminar valores fixos (hardcoded) no código-fonte, permitindo que configurações sensíveis ao ambiente — como grupos de e-mail, URLs de API, credenciais e parâmetros operacionais — sejam armazenadas no banco de dados e recuperadas dinamicamente em tempo de execução.

O principal benefício é a **separação entre código e configuração**: ao copiar um banco de dados de produção para homologação (ou vice-versa), os valores das variáveis já estão cadastrados por ambiente e não exigem alteração manual no código ou nos programas.

**Exemplos de uso típico:**
- Grupo de e-mail de notificação (diferente em homologação e produção)
- URL base de uma API externa por ambiente
- Código de destinatário padrão para abertura de chamados
- Parâmetros de integração que variam entre clientes ou ambientes

---

## 2. Escopo

Este documento cobre a arquitetura interna do módulo `thl-lib.core.environment`, incluindo:

- Estrutura de classes e responsabilidades
- Tabelas de banco de dados envolvidas
- Fluxo de execução para leitura de variáveis
- Regras de negócio e validações
- Exemplos de uso para consumidores do módulo

---

## 3. Arquitetura

### 3.1 Visão Geral das Classes

```
Programa consumidor (ex: programa .p do ERP)
        │
        │  using thl-lib.core.environment.EnvironmentResource.
        │  EnvironmentResource:getEnvironmentVariable('nomeVariavel')
        ▼
┌─────────────────────────────┐
│     EnvironmentResource     │  ← Fachada pública (entry point)
│   (thl-lib.core.environment)│
└────────────┬────────────────┘
             │ usa
     ┌───────┴────────┐
     ▼                ▼
┌─────────────┐  ┌──────────────────┐
│ EnvironmentUtil│  │  ContextService  │
│ (identifica  │  │ (contexto de     │
│  o ambiente) │  │  execução)       │
└──────┬───────┘  └────────┬─────────┘
       │                   │
       └────────┬───────────┘
                ▼
   ┌────────────────────────┐
   │  EnvironmentRepository │  ← Acesso ao banco de dados
   │  (consultas ao BD)     │
   └────────────────────────┘
                │
        ┌───────┴────────┐
        ▼                ▼
  thl-ambiente    thl-ambiente-param-*
```

### 3.2 Descrição das Classes

#### `EnvironmentResource`
**Pacote:** `thl-lib.core.environment`  
**Papel:** Fachada estática — único ponto de entrada para consumidores do módulo.

| Método | Assinatura | Descrição |
|--------|-----------|-----------|
| `getEnvironmentVariable` | `() → character` | Inicializa o contexto automaticamente e retorna o valor da variável principal (variableCode vazio). Uso quando o programa tem apenas uma variável. |
| `getEnvironmentVariable` | `(variableCode as character) → character` | Retorna o valor de uma variável específica pelo seu código. Exige contexto já inicializado via `getEnvironmentVariable()` ou `initializeEnvironmentParameter()`. |
| `getEnvironmentVariable` | `(codeParameter, variableCode) → character` | Permite informar o código do parâmetro explicitamente. |
| `getEnvironmentVariable` | `(environment, codeParameter, variableCode) → character` | Sobrecarga completa — ambiente, parâmetro e variável informados explicitamente. |
| `initializeEnvironmentParameter` | `() → void` | Reseta o contexto e resolve o parâmetro a partir da pilha de chamadas. |
| `validateEnvirommentParameter` | `() → void` | Lança `AppError` se o parâmetro não estiver inicializado. |
| `getEnvirommentParameter` | `() → character` | Retorna o código do parâmetro do contexto atual. |
| `getProgramName` | `() → character` | Retorna o nome do programa resolvido no contexto. |

---

#### `EnvironmentUtil`
**Pacote:** `thl-lib.core.environment`  
**Papel:** Identifica o ambiente corrente com base no `PROPATH` da sessão OpenEdge.

O ambiente é determinado uma única vez por sessão e armazenado em propriedade estática privada (cache). A identificação é feita consultando a tabela `thl-ambiente` pelo fragmento de caminho (`ip`) presente no `PROPATH`.

| Método | Descrição |
|--------|-----------|
| `getEnvironment() → character` | Retorna o código do ambiente. Na primeira chamada consulta o BD; nas seguintes retorna o valor em cache. |
| `reset() → void` | Limpa o cache (útil em testes ou reinicializações). |

---

#### `ContextService`
**Pacote:** `thl-lib.core.context`  
**Papel:** Gerencia o contexto da execução corrente — qual parâmetro de ambiente está ativo e qual programa foi identificado na pilha.

O método `setEnvirommentParameter()` percorre a pilha de chamadas (`program-name(level)`) normalizando cada nome de programa e consultando `thl-ambiente-param-prog` até encontrar um vínculo cadastrado.

| Propriedade / Método | Descrição |
|----------------------|-----------|
| `envirommentParameter` (static) | Código do parâmetro de ambiente resolvido. |
| `programName` (static) | Nome do programa identificado na pilha. |
| `setEnvirommentParameter() → void` | Percorre a pilha e define o parâmetro a partir de `thl-ambiente-param-prog`. Lança erro se nenhum programa for encontrado. |
| `reset() → void` | Limpa `envirommentParameter`. |
| `getUser() → character` | Retorna o usuário do sistema operacional (`USERNAME`). |
| `getProgramsCaller() → character` | Retorna a pilha de chamadas formatada para diagnóstico. |

---

#### `EnvironmentRepository`
**Pacote:** `thl-lib.core.environment.repository`  
**Papel:** Único ponto de acesso ao banco de dados para o módulo. Encapsula todas as consultas às tabelas de ambiente.

| Método | Tabela consultada | Descrição |
|--------|------------------|-----------|
| `findEnvironmentCodeByPropath(propath)` | `thl-ambiente` | Localiza o ambiente pelo fragmento de caminho no PROPATH. Lança erro se não encontrado. |
| `findParameterCodeByProgram(programName)` | `thl-ambiente-param-prog` | Localiza o código do parâmetro associado ao programa. Retorna `''` se não encontrado. |
| `findVariableValue(environment, parameterCode, variableCode)` | `thl-ambiente-param-variavel` | Retorna o valor da variável. Retorna `''` se não encontrada. |

---

## 4. Tabelas de Banco de Dados

### `thl-ambiente`
Cadastro dos ambientes reconhecidos pelo sistema (ex: homologação, produção, desenvolvimento).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cod-ambiente` | character | Código único do ambiente (chave). |
| `ip` | character | Fragmento de caminho que identifica o ambiente no PROPATH da sessão OpenEdge. |

> **Exemplo:** Para o ambiente de produção, `ip` pode conter `\producao\` ou outro fragmento exclusivo do servidor de produção.

---

### `thl-ambiente-param`
Cadastro de grupos de parâmetros. Agrupa variáveis relacionadas a uma funcionalidade ou módulo.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cod-param-ambiente` | character | Código do grupo de parâmetro (chave). |
| *(demais campos)* | — | Descrição, status e outros metadados do parâmetro. |

---

### `thl-ambiente-param-prog`
Vínculo entre programas do ERP e grupos de parâmetros. Permite que o módulo identifique automaticamente qual parâmetro usar a partir da pilha de execução.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cod-prog-dtsul` | character | Nome do programa ERP (sem extensão e sem caminho). |
| `cod-param-ambiente` | character | Código do parâmetro associado ao programa. |

---

### `thl-ambiente-param-variavel`
Armazena os valores das variáveis por combinação de ambiente + parâmetro + código de variável.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cod-ambiente` | character | Código do ambiente. |
| `cod-param-ambiente` | character | Código do grupo de parâmetro. |
| `cod-variavel` | character | Código da variável (pode ser `''` para programas com uma única variável). |
| `valor-variavel` | character | Valor da variável naquele ambiente. |

---

## 5. Fluxo de Execução

### 5.1 Cenário: programa com uma única variável

```
1. Programa consumidor chama:
      EnvironmentResource:getEnvironmentVariable()

2. EnvironmentResource chama initializeEnvironmentParameter():
   2a. ContextService:reset()  → limpa envirommentParameter
   2b. ContextService:setEnvirommentParameter():
       - Percorre a pilha de chamadas (program-name(1), program-name(2), ...)
       - Normaliza cada nome: remove caminho e extensão
       - Consulta thl-ambiente-param-prog com o nome normalizado
       - Ao encontrar vínculo: armazena cod-param-ambiente em envirommentParameter
       - Se nenhum programa estiver cadastrado: lança AppError

3. EnvironmentResource chama EnvironmentUtil:getEnvironment():
   - Se ambiente em cache: retorna cache
   - Caso contrário: consulta thl-ambiente pelo PROPATH da sessão → armazena em cache

4. EnvironmentResource chama EnvironmentRepository:findVariableValue(
       environment, envirommentParameter, '' ):
   - Consulta thl-ambiente-param-variavel com os três parâmetros
   - Retorna valor-variavel (ou '' se não cadastrado)

5. Valor retornado ao programa consumidor.
```

### 5.2 Cenário: programa com múltiplas variáveis

Na primeira chamada, o programa deve inicializar o contexto:

```
1. EnvironmentResource:getEnvironmentVariable()      ← inicializa e retorna variável principal
2. EnvironmentResource:getEnvironmentVariable('var2') ← reutiliza contexto, busca variável 'var2'
3. EnvironmentResource:getEnvironmentVariable('var3') ← reutiliza contexto, busca variável 'var3'
```

> O contexto (`envirommentParameter`) é estático e persiste durante a sessão. A segunda chamada em diante apenas consulta o banco para o novo código de variável, sem re-percorrer a pilha.

---

## 6. Regras de Negócio

1. **Identificação de ambiente obrigatória:** Se o PROPATH da sessão não corresponder a nenhum registro em `thl-ambiente`, um `AppError` é lançado com código `17006`.

2. **Vínculo de programa obrigatório:** Se nenhum programa da pilha de execução estiver cadastrado em `thl-ambiente-param-prog`, um `AppError` é lançado com código `17006`.

3. **Variável não encontrada retorna vazio:** Se a combinação ambiente + parâmetro + variável não existir em `thl-ambiente-param-variavel`, o método retorna `''` sem lançar erro. Cabe ao programa consumidor tratar o valor vazio.

4. **Cache de ambiente por sessão:** O código do ambiente é resolvido uma única vez por sessão OpenEdge e armazenado em memória estática (`EnvironmentUtil.environment`). Para forçar reavaliação, chame `EnvironmentUtil:reset()`.

5. **Normalização de nome de programa:** O `ContextService` remove o caminho completo e a extensão do nome do programa antes de consultar `thl-ambiente-param-prog`. Ex: `C:\totvs\meu-prog.p` → `meu-prog`.

---

## 7. Exemplos de Uso

### 7.1 Programa com uma única variável

```openedge
using thl-lib.core.environment.EnvironmentResource.

define variable cEmailGroup as character no-undo.

assign cEmailGroup = EnvironmentResource:getEnvironmentVariable().

/* cEmailGroup conterá o valor cadastrado para o ambiente corrente */
```

### 7.2 Programa com múltiplas variáveis

```openedge
using thl-lib.core.environment.EnvironmentResource.

define variable cEmailGroup     as character no-undo.
define variable cInfoAbertura   as character no-undo.
define variable cUrlApi         as character no-undo.

/* Primeira chamada: inicializa o contexto automaticamente */
assign cEmailGroup   = EnvironmentResource:getEnvironmentVariable().

/* Chamadas seguintes: reutilizam o contexto já inicializado */
assign cInfoAbertura = EnvironmentResource:getEnvironmentVariable('infoAberturaChamado').
assign cUrlApi       = EnvironmentResource:getEnvironmentVariable('urlApiExterna').
```

### 7.3 Pré-requisito: cadastro nas tabelas

Para que o módulo funcione, os seguintes registros devem estar cadastrados:

```
thl-ambiente:
  cod-ambiente = 'PROD'
  ip           = '\producao\'   ← fragmento exclusivo do PROPATH de produção

thl-ambiente:
  cod-ambiente = 'HOM'
  ip           = '\homologacao\' ← fragmento exclusivo do PROPATH de homologação

thl-ambiente-param:
  cod-param-ambiente = 'EMAIL-NOTIFICACAO'

thl-ambiente-param-prog:
  cod-prog-dtsul     = 'meu-prog'   ← nome do programa sem extensão
  cod-param-ambiente = 'EMAIL-NOTIFICACAO'

thl-ambiente-param-variavel:
  cod-ambiente       = 'PROD'
  cod-param-ambiente = 'EMAIL-NOTIFICACAO'
  cod-variavel       = ''            ← vazio para variável única
  valor-variavel     = 'ti@empresa.com.br'

thl-ambiente-param-variavel:
  cod-ambiente       = 'HOM'
  cod-param-ambiente = 'EMAIL-NOTIFICACAO'
  cod-variavel       = ''
  valor-variavel     = 'ti-hom@empresa.com.br'
```

---

## 8. Pontos de Atenção

- **Ausência de cadastro:** Se o programa que chama `getEnvironmentVariable()` não estiver cadastrado em `thl-ambiente-param-prog`, a execução será interrompida com erro. Certifique-se de cadastrar o programa (ou um de seus chamadores na pilha) antes de usar o módulo.

- **Variável vazia vs. erro:** O módulo não lança erro quando a variável não está cadastrada — retorna `''`. Implemente validação no programa consumidor se o valor vazio não for aceitável.

- **Cache em sessões longas (batch/RPW):** O ambiente é cacheado por sessão. Em processos RPW ou batch de longa duração, o ambiente é resolvido na primeira chamada e não é reavaliado. Isso é o comportamento esperado, mas deve ser considerado em cenários de teste ou execução local.

- **Execução interativa vs. batch:** O mecanismo de identificação do programa (`program-name(level)`) funciona tanto em execução interativa (GUI/Datasul) quanto em batch (RPW, PASOE). A pilha de chamadas pode ser diferente nos dois contextos — garanta que o programa correto esteja cadastrado para cada modo de execução.

---

## 9. Classes e Programas Envolvidos

| Arquivo | Tipo | Responsabilidade |
|---------|------|-----------------|
| `thl-lib/core/environment/EnvironmentResource.cls` | Classe ABL | Fachada pública — entry point para consumidores |
| `thl-lib/core/environment/EnvironmentUtil.cls` | Classe ABL | Identificação e cache do ambiente pelo PROPATH |
| `thl-lib/core/environment/repository/EnvironmentRepository.cls` | Classe ABL | Acesso ao banco de dados (consultas às tabelas) |
| `thl-lib/core/context/ContextService.cls` | Classe ABL | Gerenciamento do contexto de execução (pilha + parâmetro) |

---

## 10. Próximos Passos

- [ ] Criar tela de cadastro para `thl-ambiente`, `thl-ambiente-param` e `thl-ambiente-param-prog`
- [ ] Implementar suporte a variáveis do tipo lógico e inteiro (atualmente todas são `character`)
- [ ] Adicionar log/auditoria de leituras de variável para rastreabilidade
- [ ] Documentar o processo de cadastro de novos ambientes e programas para a equipe
- [ ] Avaliar suporte a herança de valores entre ambientes (ex: variável não cadastrada em HOM cai para um valor padrão)

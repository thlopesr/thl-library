---
tipo: guia
camada: ambos
status: vigente
tags: [fluxo, ambiente]
updated: 2026-10-13
---

# Fluxo — parâmetros e variáveis de ambiente

> Como o THL resolve configuração por ambiente. É a base do destino da mensagem de saída ([fluxo-saida.md](fluxo-saida.md)) e da escolha do parâmetro de e-mail ([fluxo-email.md](fluxo-email.md)). Referência por classe em [core/environment.md](../core/environment.md).
>
> Verificado por leitura do código em 2026-10-09. Nada executado contra PASOE.

## Cadeia de chamadas

```text
EnvironmentResource( programName )          ou  EnvironmentResource()
  ├─ environment   = EnvironmentUtil:getEnvironment()
  │                   └─ findEnvironmentCodeByPropath( propath )   [cacheado na sessão]
  └─ parameterCode = findParameterCodeByProgram( programName )     [nome informado]
                     ou EnvironmentContext:setParameterCode()      [sobe o call stack]

getEnvironmentVariable( variableCode )
  └─ findVariableValue( environment, parameterCode, variableCode )
       1. cod-ambiente = <ambiente>   → valor
       2. cod-ambiente = '*'          → valor comum
       3. nenhum                      → '' (não lança erro)
```

## Resolução do ambiente

`findEnvironmentCodeByPropath` percorre `thl-ambiente` com `ip <> ''` e testa `index( propathValue, thl-ambiente.ip ) > 0` — o campo `ip` é **procurado como substring do PROPATH**, não comparado com o IP da máquina.

- Primeiro que casar vence; **a ordem do `for each` decide** em caso de ambiguidade.
- Nenhum casando (inclusive sem ambiente com `ip` preenchido): `ThlError` "Ambiente nao identificado". O `if available` após o laço não deve devolver fallback, porque o buffer fica sem registro ao fim do `for each` (⚠️ leitura estática; confirmar em execução).
- `EnvironmentUtil` **cacheia** o valor na variável estática: alterar o cadastro exige nova sessão.

> Consequência prática: identificador curto demais casa por acidente com o PROPATH de outro ambiente, e identificador ausente do PROPATH nunca é reconhecido.

## Resolução do parâmetro

| Construtor | Como descobre |
|---|---|
| `EnvironmentResource( programName )` | `findParameterCodeByProgram( programName )` direto. Lança `ThlError` se vazio |
| `EnvironmentResource()` | `EnvironmentContext:setParameterCode()` sobe o call stack com `program-name(level)`, normaliza e consulta cada um; usa o primeiro com vínculo. Esgotando a pilha, lança erro **listando os programas tentados** |

`thl-ambiente-param-prog` é **funcional, não documental**: sem a linha, não há parâmetro e o fluxo para.

Em integração de saída, o `programName` é **`APLICACAO.OBJETO`** (montado em `MessageExecutionService`), não um nome de programa Datasul.

## Resolução do valor

`findVariableValue` faz duas buscas em `thl-ambiente-param-variavel`: pelo ambiente e, não achando, por `cod-ambiente = '*'`. **Retorna `''` em vez de lançar erro** — o erro aparece em quem consumiu o vazio, geralmente com outra mensagem.

Use `'*'` para o que não varia entre ambientes: reduz linhas e o risco de esquecer uma na promoção.

## Cadastro que governa cada etapa

| Etapa | Tabela · campo | Efeito |
|---|---|---|
| Ambiente | `thl-ambiente.ip` | Substring procurada no PROPATH |
| Parâmetro | `thl-ambiente-param-prog.cod-prog-dtsul` | Vínculo programa → parâmetro; obrigatório |
| Valor | `thl-ambiente-param-variavel.cod-ambiente` | Ambiente, ou `'*'` para todos |
| | `.cod-variavel` | Nome pedido pelo código |
| | `.valor-variavel` | Em integração, costuma ser **código de outro cadastro**, não a URL |

## Valores sensíveis

Leitura pela API/tela devolve mascarado (`saveContentByType` nas Messages de cadastro). Regravar o valor mascarado mantém o original; substituir por texto novo altera de verdade.

## Armadilhas

- O campo do objeto chamado **"Parâmetro de ambiente"** é, na verdade, o **nome da variável**. Erro de leitura comum.
- Variável ausente devolve `''` silenciosamente: o sintoma aparece longe da causa.
- Ambiente cacheado por sessão mascara correção de cadastro.
- `findParameterCodeByProgram` retorna `''` sem erro; quem lança é o construtor de `EnvironmentResource`.

## Versão para pessoas

[Notion — 3. Parâmetros e variáveis de ambiente](https://app.notion.com/p/3f4d3a2b48158155b979fbba648d0ecc), com roteiro de montagem em quatro passos.

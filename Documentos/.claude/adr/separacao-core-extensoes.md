---
tipo: adr
modulo: thl
status: aceita
updated: 2026-10-13
camada: ambos
tags: [adr, thl]
---

# ADR — Separação `thl-lib` (core) × `thl-extensions` (sistema externo)

**Decisores:** Thiago Lopes (responsável pelo projeto)
**Escopo:** ambos
**Relacionados:** [../convencoes.md](../convencoes.md) §3, [inbound-message-processor-service.md](inbound-message-processor-service.md), [../arquitetura.md](../arquitetura.md), [../INDEX.md](../INDEX.md)

> ADR **retroativa** (2026-10-13): registra uma regra que já vale e está aplicada no código. Aprovação não comprova compilação nem implantação.

## Contexto

A THL-Library atende vários sistemas externos (automatizador, dvv, gestaoepi, iacompras, loogai, mmcm, ninahub, powerautomate) e o próprio THL. O framework genérico (mensageria, conectores, ambiente, erro, log, e-mail, utilitários) é reutilizado por todos; mensagens, conectores e regras de um sistema só servem àquele sistema. Misturar os dois faz o core depender de tabelas e nomes de cliente (`nit-*`, `es_*`) e obriga a compilar e publicar o core a cada mudança de um cliente.

## Decisão

1. **Genérico e reutilizável** fica em `Fontes\thl-lib\` (pacote `thl-lib.*`).
2. **Específico de um sistema externo** fica em `Fontes\thl-extensions\`:
   - `erp\<sistema>\` — Services e enums;
   - `integration\<sistema>\` — mensagens e conectores.
3. **Nunca** referenciar tabela de cliente (`nit-*`, `es_*`) em `thl-lib`.
4. O core não conhece as extensões: a ligação é por cadastro (`thl-objeto.classe-objeto`, `classe-processor`, `classe-service`; `thl-conexao-rest-autenticacao.classe-parser-token`; `thl-conexao-rest-header.classe-parser`) e `dynamic-new` com o nome completo da classe. Por isso **mover ou renomear uma classe exige atualizar esses cadastros**.
5. Contratos públicos do core (`Message`, `InboundMessage`, `OutboundMessage`, `Service`, `ITokenProvider`, `IHeaderProvider`) não mudam de assinatura sem pedido explícito.

## Evidência no código

- `LpcoMessage` (outbound) e `NotaFiscalMessage` saíram de `thl-lib.integration.messaging.outbound.message` para `thl-extensions.integration.automatizador` e `…loogai` (renomeações no Git).
- Busca por texto em `Fontes\thl-lib\**\*.cls` (2026-10-13): nenhuma referência a `nit-*`, `es_*` ou `thl-extensions`. Cada extensão tem uma nota em [../extensions/](../extensions/).
- Contagem em 2026-10-13: 94 classes em `thl-lib` e 51 em `thl-extensions` (arquivos `.cls`).

## Opções consideradas

### Opção A: tudo no core (descartada)

Menos pastas; o core passa a depender de cliente e a cada mudança de cliente o core é recompilado e republicado.

### Opção B: core + extensões por sistema (adotada)

| Dimensão | Avaliação |
|---|---|
| Complexidade | Média: exige o cadastro com nome de classe e `dynamic-new` |
| Impacto core × extensões | Mudança de cliente não toca o core |
| Runtime PASOE | Classes carregadas sob demanda pelo nome gravado no banco |
| Transação/triggers | Sem efeito |
| Oracle | Sem efeito |
| Familiaridade equipe | Alta: reflete a organização atual |

**Prós:** isolamento por cliente; core estável. **Contras:** nome de classe no banco é um acoplamento invisível ao compilador.

## Consequências

- Fica mais fácil: publicar uma extensão sem recompilar o core; revisar o que é genérico.
- Fica mais difícil: renomear ou mover classe (atualizar cadastros, avisar o usuário).
- Revisitar: ferramenta que valide os nomes de classe dos cadastros contra o código.

## Ações

1. [x] Aplicado em `Fontes\` (sem compilação neste registro).
2. [ ] Validação do nome das classes dos cadastros → `/thl-qa`.
3. [x] Registrada em [../INDEX.md](../INDEX.md).

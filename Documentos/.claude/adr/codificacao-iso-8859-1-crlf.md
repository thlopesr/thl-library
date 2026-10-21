---
tipo: adr
modulo: util
status: aceita
updated: 2026-10-13
camada: ambos
tags: [adr, util]
---

# ADR — Codificação ISO-8859-1 e fim de linha CRLF nos fontes ABL

**Decisores:** Thiago Lopes (responsável pelo projeto)
**Escopo:** ambos (e `Fontes\thl`, `Utils\`)
**Relacionados:** [../convencoes.md](../convencoes.md) §1, [renumeracao-cadastros-depara.md](renumeracao-cadastros-depara.md), `AGENTS.md` (raiz), `.gitattributes`

> ADR **retroativa** (2026-10-13): registra decisões do responsável de 2026-09-24, 2026-09-25 e 2026-10-08, já aplicadas.

## Contexto

Os fontes do Datasul 12 são compilados no PDSOE com a página de código do ambiente (Latin-1). Os templates TOTVS vinham em CP850 e os arquivos misturavam codificações (diagnóstico de 2026-09-25 em `convencoes.md` §1: parte dos fontes estava em UTF-8 e parte com acentos já perdidos). Fonte em UTF-8 ou com BOM arrisca corromper comentários e strings na compilação; esse risco não foi medido aqui.

## Decisão

1. Fontes ABL (`.cls .p .w .i .df`) são **ISO-8859-1**, nunca UTF-8 e nunca com BOM. Edições preservam os bytes fora do trecho alterado.
2. Fim de linha no disco: **CRLF** para ABL, config do PDSOE e scripts Windows; no repositório o Git guarda LF (`.gitattributes`, que **não** converte codificação).
3. Exceções: front-end web (`.ts .html .scss .json`) e documentação `.md` são **UTF-8 com LF**.
4. `Fontes\thl` (telas e programas Datasul): texto em **ASCII**, sem acentuação (decisão de 2026-10-08).
5. Em 2026-09-25 os trechos CP850 dos templates em `Fontes\thl` foram convertidos palavra a palavra (1.279 ocorrências em 126 arquivos).

## Opções consideradas

### Opção A: UTF-8 em todo o repositório (descartada)

| Dimensão | Avaliação |
|---|---|
| Complexidade | Baixa no Git; alta no PDSOE (ambiente Latin-1) |
| Runtime PASOE | Risco de string corrompida em tempo de execução |

### Opção B: ISO-8859-1/CRLF para ABL, UTF-8/LF para web e `.md` (adotada)

Segue a ferramenta de cada lado; o custo é cuidar de edição byte a byte.

## Consequências

- Fica mais fácil: compilar no PDSOE sem conversão.
- Fica mais difícil: editar ABL (só com leitura e gravação explícitas em Latin-1) e revisar diff com acentos.
- Pendência registrada em `convencoes.md` §1: fontes de `thl-lib`/`thl-extensions` e `Utils` ainda em UTF-8 (a lista muda a cada sessão; confirmar com `file` antes de afirmar).
- Revisitar: verificação automática de codificação no fluxo de revisão.

## Ações

1. [x] Aplicado (sem compilação neste registro).
2. [ ] Verificação automática de codificação → `/thl-qa`.
3. [x] Registrada em [../INDEX.md](../INDEX.md).

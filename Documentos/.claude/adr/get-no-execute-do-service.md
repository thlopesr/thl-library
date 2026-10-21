---
tipo: adr
modulo: erp
status: aceita
updated: 2026-10-03
camada: ambos
tags: [adr, erp]
---

# ADR — GET agrupado no `execute` do Service

> ⚠️ **2026-10-04 — Message → Processor → Service.** Parcialmente substituída por [inbound-message-processor-service.md](inbound-message-processor-service.md): o GET continua no mesmo caminho dos outros verbos e o `consult()` continua no Service, mas o `execute` passou para o `Processor`.

> **Aceita em 2026-10-03** (decisão do responsável). Aplicada na base (`thl-lib`) e no sistema `thl` inteiro; **não compilada nem testada**. As consultas de `thl-lib` e das demais extensões ainda usam o `methodGet` da Message e migram numa segunda rodada.
>
> Contexto: [arquitetura/Service.md](../arquitetura/Service.md) · [arquitetura/InboundMessage.md](../arquitetura/InboundMessage.md) · [erp/erp-services.md](../erp/erp-services.md) · [extensions/thl.md](../extensions/thl.md)

## 1. Contexto

POST, PATCH e DELETE passavam pelo contrato de `Service` (`execute`); o GET não. Cada Message conhecia a assinatura do `get` de cada Service, com `cast`, leitura de filtros e, nas Messages de agregado, um `case` por rota. A leitura não tinha contrato comum.

Entendimento de papéis firmado na mesma discussão:

- **Message** — protocolo: verbo, rota, operação, registro da mensagem, máscara do conteúdo. Só **pega** as referências.
- **Service** — entidade: regra, acesso ao ERP, transação e o JSON da entidade nos dois sentidos (lê os nomes do payload na escrita e os da query na leitura).
- Escolher **quem atende** (qual Service) é da Message; escolher **o que fazer** dentro da entidade (operação) é do Service.

## 2. Decisão

O GET passa pelo mesmo `execute`, **sem mudar a assinatura**:

- `ActionEnum` ganha `Consultado` (4).
- `Service:execute( action, operation, context, output referenceCode )`: com `Consultado`, o `context` são os **parâmetros da query** (o JSON que o `resourcen.p` já monta), o `initialize()` **não** é chamado (ele prepara a escrita: chave e registro posicionado) e o resultado vem de `consult()`.
- `Service:consult()` (protegido, novo): cada Service sobrescreve, lê os próprios filtros e devolve a lista (`JsonArray`) ou um objeto (`JsonObject`). O desvio por operação (`metricas`, `conteudo`) fica aqui. Padrão: "Acao nao suportada".
- `Service:queryParameters` (protegido, novo): `thl-lib.erp.core.QueryParameters` sobre o contexto — `getText`, `getInteger`, `getDate` (só data), `getDateTime` (`yyyy-MM-ddTHH:mm`), `getPager`. Fica em `erp.core` para o Service não depender da mensageria.
- `Service:buildQueryResponse()`: lista vira `{ "items": [...], "hasNext": false }` — o formato que o cliente já recebia; objeto único segue como veio.
- `InboundMessage:methodGet()` ganha padrão: `createService():execute( ActionEnum:CONSULTADO, context:operation, context:queryParameters, referenceCode )`. Em seguida grava um item da mensagem para cada resultado que traga `referenceCode` (o que as Messages de cadastro já faziam). Message que sobrescreve `methodGet` continua valendo.

## 3. Aplicação (2026-10-03)

- **Base:** `ActionEnum`, `Service`, `QueryParameters` (novo), `InboundMessage`.
- **Sistema `thl`:** os 24 Services com consulta ganharam `consult()` (21 cadastros + `MensageriaService`, `EmailService`, `AuditoriaService`); as 13 Messages perderam `methodGet` e `appendItems`. Nas 5 Messages de agregado restou só o `createService()` por rota (mais a máscara, em duas). As 3 Messages de consulta passaram a devolver o Service em `createService()` (antes `?`).
- **Não migrado:** consultas de `thl-lib` (centro de custo, emitente, item, transporte, usuário…) e das outras extensões. Seguem funcionando pelo `methodGet` próprio.

## 4. Consequências

- **A favor:** contrato único para os quatro verbos; Messages de cadastro reduzidas a `createService()`; um `.p` ou RPW chama a mesma consulta com `execute( ActionEnum:CONSULTADO, operação, json, ref )`; `hasNext` e `total` reais passam a ser possíveis, porque quem monta o objeto é o Service.
- **Contra / riscos:**
  - A resposta de lista deixa de ser embrulhada pelo `resourcen.p` (`JsonAPIResponseBuilder:ok( JsonArray, false )`) e passa pelo ramo de objeto (`ok( JsonObject, 200 )`), o mesmo de `mensageria/conteudo`. Deve chegar igual ao front; **confirmar no primeiro teste**.
  - `Service` é contrato público: a mudança é aditiva (valor de enum, dois métodos protegidos, uma propriedade), mas mexe na base de todos os Services.
  - Nas Messages de consulta, POST/PATCH/DELETE passam a dar "Acao nao suportada" (antes falhavam por Service inválido).
  - Os nomes e padrões dos filtros saíram da Message e foram para o Service.
  - `hasNext` continua sempre falso e `total` não existe (mantido de propósito nesta rodada).

## 5. Em aberto

1. Segunda rodada: migrar as consultas de `thl-lib` e das outras extensões.
2. `hasNext` real e `total`.
3. Item da mensagem no GET (um por registro devolvido): manter ou deixar de gravar.
4. Orquestrador como Service de processo para casos 1 para N (nota fiscal) — discutido, não decidido.
5. `InboundObjectContext` tem leituras parecidas com as de `QueryParameters`; pode passar a delegar.

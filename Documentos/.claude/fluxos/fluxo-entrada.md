---
tipo: guia
camada: ambos
status: vigente
tags: [fluxo, entrada]
updated: 2026-10-13
---

# Fluxo — mensagem de entrada (inbound REST)

> Visão de ponta a ponta, atravessando pacotes: do endpoint REST ao Service, e o cadastro que governa cada etapa. As referências por classe ficam em [messaging-inbound.md](../integration/messaging-inbound.md), [messaging-core.md](../integration/messaging-core.md) e [arquitetura.md](../arquitetura.md).
>
> Verificado por leitura do código em 2026-10-09. Nada executado contra PASOE.

## Cadeia de chamadas

```text
resourcen.p (piPrincipal)
  ├─ InboundObjectContext      payload, queryParameters, pathParameters
  ├─ InboundRouteResolver      pathParams → application, objectCode, operation, routePath
  ├─ MethodTypeEnum:GetEnum( request.method )
  └─ InboundMessageService( application, object, method, operation ):receive( context )
       ├─ InboundConfigLoader   posiciona thl-objeto + thl-objeto-parametro + extensão REST
       ├─ accept()              createMessage + saveContentByType( INBOUND )
       ├─ executionMode = SCHEDULE → InboundSchedulingService:schedule() (RPW thl0220z.p)
       └─ processOnline()
            InboundMessage:processInbound → dispatchInbound()
              POST        → validate → methodPost   → executeService( CRIADO )
              PATCH/PUT   → validate → methodPatch  → executeService( ATUALIZADO )
              DELETE      → validate → methodDelete → executeService( DELETADO )
              GET         → methodGet (sem validate)
            finalize() → payload default {200} se vazio → saveContent → saveInboundSuccess
       catch → saveInboundError( routePath, erro ) e relança
```

## Resolução da rota (`InboundRouteResolver`)

| Segmentos | Resultado |
|---|---|
| 1 | O segmento é a `routePath`; sem operação |
| >1 | O último é a `operation`; os anteriores, unidos por `/`, formam a `routePath` |

Com a `routePath`, procura `thl-objeto-rota` por `rota-publica` + `ind-ativo`.

1. **Rota exata.** Não achando, `findRouteByPrefix()` tenta os primeiros segmentos, do mais longo para o mais curto: `notafiscal/embarque/geracao` casa a rota `notafiscal` e o resto vira operação.
2. **Sem rota**, assume `objectCode = replace(routePath, '/', '')` e `application = 'TOTVS'` — por isso URL errada falha adiante como objeto inexistente, não como 404.
3. `thl-objeto-rota.inicio-operacao >= 2` → `composeOperation()`: a operação vai do segmento informado até o último. Zero = só o último segmento.

> ⚠️ A nota [messaging-inbound.md](../integration/messaging-inbound.md) descrevia a busca em `thl-inbound-rota`, tabela substituída por `thl-objeto-rota` em 2026-10-06, e não mencionava o prefixo nem `inicio-operacao`. Corrigido em 2026-10-09.

## Posicionamento da configuração (`InboundConfigLoader`)

O `metodo` da requisição **faz parte da chave** de `thl-objeto-parametro`. Ordem de busca:

1. `operacao` da URL + `metodo`;
2. `operacao` em branco + `metodo` — a **linha do pai**, obrigatória.

Sem nenhuma das duas, `ThlError` nomeando aplicação, objeto, método e operação. **Não há fallback para a primeira linha do método nem busca pelo nome do verbo.** Objeto ou linha inativos → erro próprio.

As classes (`message`, `processor`, `service`) vêm **da linha**, não de `thl-objeto`: nascem copiadas na criação (thl0022, API `objeto/parametro`, cargas) e as três precisam estar preenchidas.

## Situações

`MessageRepository` grava as três fases em `PENDING` na criação. No encerramento, cada `success*` vira `SUCCESS`, `ERROR` ou — quando `?` — `NOT_APPLICABLE`. `qtd-tentativas` incrementa a cada gravação de resposta.

## Cadastro que governa cada etapa

| Etapa | Tabela · campo | Efeito |
|---|---|---|
| Resolução da rota | `thl-objeto-rota.rota-publica` | Qual URL atinge o objeto; única entre todas |
| | `thl-objeto-rota.ind-ativo` | Rota inativa não é encontrada |
| | `thl-objeto-rota.inicio-operacao` | Onde a operação começa em URL multinível |
| Configuração | `thl-objeto-parametro.operacao` + `.metodo` | Qual linha atende — e portanto quais classes rodam |
| | `thl-objeto-parametro.ind-inativo` | Suspende o método específico |
| Execução | `.forma-execucao` | Online, agendada (RPW) ou batch |
| Conteúdo | `.tipo-grava-conteudo` | Sempre · Somente em erro · Nunca |
| Histórico | `thl-objeto.ind-gera-historico` | Grava `thl-mensagem-historico` por tentativa |
| Métricas | `thl-aplicacao.ind-interna` | Oculta o tráfego do próprio THL por padrão |

## Armadilhas

- **Agendar muda o contrato HTTP**: o chamador recebe o aceite, não o resultado. Erro de negócio só aparece no monitor.
- **GET não valida payload** — é o único verbo que pula `validate()`. O default de `methodGet()` lança "Metodo GET nao implementado" quando a Message do objeto não o implementa.
- A mensagem é **registrada antes** do processamento: conteúdo de entrada existe mesmo quando tudo falha depois.
- Mover ou renomear a classe exige atualizar o cadastro — carregamento por `dynamic-new` pelo nome gravado.

## Versão para pessoas

[Notion — 1. Mensagem de entrada](https://app.notion.com/p/3f4d3a2b481581fc927cecb27aad161e), em linguagem de negócio, com diagrama e exemplo GET.

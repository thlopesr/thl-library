---
tipo: guia
camada: ambos
status: vigente
tags: [web, po-ui, poui-licoes]
updated: 2026-10-13
---

# PO UI 21 — armadilhas verificadas no projeto

Comportamentos do PO UI que custaram tempo ou geraram defeito no `Fontes\web`, **todos confirmados rodando**, não deduzidos da documentação. Catálogo genérico do PO UI em [poui/INDEX.md](../poui/INDEX.md); o que o app faz com isso em [app-web.md](app-web.md) e [motor-cadastro.md](motor-cadastro.md).

## `po-table`

**`PoTableColumnLabel`: `value` casa com o dado, `label` é o texto exibido.** Invertê-los não quebra nada — a cor e o ícone saem certos e a célula mostra o conteúdo do `label`. Os três monitores ficaram mostrando `1`, `2`, `3` no lugar de Sucesso, Erro e Pendente (corrigido em 2026-10-02; rótulos agora em `shared\domain\status-labels.ts`). O mesmo `type: 'label'` **esconde a célula inteira** quando o valor não está no domínio: em 19/10/2026 o e-mail com `logEnvio = 'Pendente'` aparecia com a coluna Status vazia, idêntica à de um valor inválido, porque `STATUS_EMAIL_LABELS` só listava `Sucesso` e `Erro`. Reproduzido no navegador com quatro linhas injetadas. Todo domínio de `label` precisa cobrir **todos** os valores que o backend emite.

**`type: 'label'` deixa a célula vazia quando o valor não está na lista.** Dado fora do domínio some da tela em vez de aparecer errado — pior, porque esconde inconsistência. O motor acrescenta os valores inesperados como tag neutra (`completarTags`).

**`type` (semântico) sobrepõe cor e ícone.** Com `type: 'info'`, o ícone informado é trocado pelo ícone padrão do tipo. Para manter um ícone próprio (a seta de Entrada/Saída), use `color` do tema (`color-01`…`color-12`) e não `type`.

**Um `po-table` criado dentro de `po-tab` oculto fica em branco** até receber um evento de mouse. O `po-tab` renderiza todas as abas e só esconde as inativas. Solução: o pai guarda a aba ativa pelo `(p-click)` do `po-tab` e a aba só renderiza a tabela quando visível.

**`p-container` é string, não boolean** — `[p-container]="true"` não compila.

**A coluna de ações nativa (`p-actions`) não aceita título.** Para ter a coluna "Ação" com cabeçalho, use `type: 'cellTemplate'` com o `thl-row-actions`.

**`width` de coluna aceita px, mas ignora porcentagem** (medido em 15/10/2026 na auditoria, com as linhas injetadas pelo `ng.getComponent`). Trocar `width` por `'5%'` ou `'20%'` deu **exatamente a mesma largura** de antes, enquanto `'110px'` foi obedecido na hora. Para uma coluna crescer com a janela, o caminho é o inverso: deixá-la **sem `width`** — as colunas sem largura dividem a sobra. Foi assim que Campos saiu de 200px fixos para 701px elásticos.

**O menu da coluna de ações abre por cima do "⋯" das linhas de baixo** na posição padrão (`bottom-left`). Medido em 15/10/2026: com o menu da linha 1 aberto, `document.elementFromPoint` sobre o "⋯" da linha 2 devolvia um item de menu da linha 1 — o clique disparava a ação da **outra linha** ou só fechava o menu, o que o usuário sentia como "preciso clicar duas vezes". `p-position="right-bottom"` no `po-popup` resolve: o menu passa a cobrir células de dados, nunca outro "⋯".

## `po-icon`

**Para mudar o tamanho de um ícone dentro de `po-icon`, o pai precisa de `::ng-deep`.** Quem desenha é o `<i class="an an-...">` que o `po-icon` cria, e ele carrega o atributo de encapsulamento **daquele** componente, não o de quem o usou. Medido em 16/10/2026 no cartão de métrica: a regra `.thl-metric__etiqueta [class*='an-'] { font-size: 15px }` não teve efeito nenhum (o ícone continuou em 11px), enquanto `::ng-deep .po-icon` funcionou. É a mesma armadilha do `[innerHTML]`, por outro caminho — vale para qualquer conteúdo renderizado por um componente filho.

Ícone escrito direto no próprio template (`<span class="an an-heartbeat">`) não tem esse problema.

## Angular **zoneless** (vale para todo o app)

**O projeto roda sem `zone.js`** — não há polyfill no `angular.json` nem `provideZoneChangeDetection`. Consequência prática: **o que muda dentro de `setTimeout`, de um callback de biblioteca ou de um listener fora do Angular não agenda detecção de mudanças**. Com `OnPush`, a tela simplesmente não redesenha.

Foi assim que nasceu o "precisa clicar duas vezes" da mensageria e do e-mail, diagnosticado em 16/10/2026: o `open()` do modal de detalhe fazia `setTimeout(() => this.modal.open())`. Medido depois do primeiro clique: a ação **rodava** (`modal.open` chamado), o `po-modal` se dava por aberto (`isHidden: false`) e o `<po-modal>` ficava **vazio no DOM**. O segundo clique só servia para disparar a detecção que faltava. A correção é um `markForCheck()` **dentro** do `setTimeout`, depois do `open()` — um `markForCheck()` antes não vale, porque o que precisa ser detectado acontece depois.

Regra para o projeto: **todo `setTimeout`, `requestAnimationFrame` ou callback de API do navegador que mexe no estado de um componente termina com `markForCheck()`**.


## `po-menu`

**O tooltip do menu recolhido fica preso na tela.** Reproduzido em 15/10/2026 numa página recém-carregada: passar o mouse por um item cria o tooltip e **tirar o mouse não o remove**. O elemento fica em `<body>` com `visibility: visible` e `opacity: 0.9`, e eles **acumulam** — um por item visitado —, sobrevivendo inclusive à troca de rota, por morarem fora da árvore do componente.

O `mouseleave` **chega** ao item (instrumentei: `mouseover → mouseenter → mouseout → mouseleave`, no mesmo nó, sem re-render), e mesmo assim o tooltip permanece. Mas um `mouseleave` **disparado por código** no item remove o tooltip na hora (1 → 0) — provavelmente uma corrida com o guarda `if (!this.displayTooltip)` do `PoTooltipDirective`. Causa exata **não confirmada**.

**Sair pelo lado é o caso que avisar não resolve.** Movendo o ponteiro para a direita, ele entra no próprio tooltip (`mouseout` com `relatedTarget` = `po-tooltip-content`). Medido nesse estado: a diretiva do item fica com `tooltipContent: undefined` e o nó continua no `body` **sem nenhuma diretiva apontando para ele** — órfão de verdade, que a biblioteca nunca mais vai tocar. O `removeTooltipAction` do PO UI só remove `if (this.appendInBody && this.tooltipContent)`, e a referência já se foi.

Contorno no projeto: `thlMenuTooltipFix` (`shared/directives/`), aplicado ao `<po-menu>` — que é o shell dos dois apps. Faz duas coisas: (1) dispara `mouseleave` nos itens, o caminho limpo, pela própria diretiva do PO UI; (2) **varre os órfãos**, capturando a lista de `body > .po-tooltip` **no instante do evento** e removendo só aqueles num `setTimeout`. Capturar antes é o que protege o tooltip novo: ao andar de um item para outro, o `mouseover` chega antes de o PO UI criar o próximo, então o que nasce depois não está na lista. Casar por texto **não serve** — o tooltip usa o `shortLabel` do item e o DOM só expõe o `aria-label` (o `label`), e foi assim que "Mét. E-mail" escapou na primeira tentativa. Remover é seguro: o `removeChild` do Angular é `oldChild.remove()`, que não reclama de nó já solto.

## Ícones Animalia

**O `an-calendar` tem "12" desenhado dentro do glifo** (verificado renderizando a 40px em 15/10/2026). Não existe variante numerada, e número de fonte não se troca por CSS: ícone com valor dentro (1, 7, 21) só desenhando em **SVG inline**, com `currentColor` para acompanhar a cor do botão. Os vazios são `an-calendar-blank` e `an-calendar-dots`; `an-calendar-gear` é o de configuração.

## `po-datetimepicker` / `po-calendar`

**Não dá para acrescentar nada ao rodapé do calendário.** O "Limpar | Hoje" é o `po-calendar-footer`, componente **interno**, com entradas fixas (`p-label-clear`, `p-label-today`, `p-hide-today-button`) e **sem `<ng-content>`** — verificado no fonte do pacote em 15/10/2026. Atalhos de período (Hoje, 7 dias, Mês…) ficam **fora** do calendário, encostados no campo: foi o que o `thl-date-shortcuts` faz.

**O modelo volta com fuso.** Entregando `2026-09-01T00:00`, o componente grava `2026-09-01T00:00-03:00`. Comparações entre o que foi escrito e o que está no modelo têm de normalizar (os 16 primeiros caracteres) — é o que o `mesmaDataHora()` faz.

## `po-dynamic-form`

**Só renderiza os tipos do `PoDynamicFieldType`**: boolean, currency, decimal, date, datetime, time, number, string, upload. **Não** renderiza `po-email`, `po-url` nem `po-rich-text`, por mais que esses componentes existam. Campo que precise deles sai do formulário dinâmico e é renderizado à parte (foi o caminho do `richText`).

**Repassa `icon`, `placeholder` e `clean`** aos componentes internos — dá para ter o visual dos exemplos de `po-input` sem escrever formulário reativo à mão.

**Nem todo componente aceita cada propriedade:**

| Propriedade | Aceita | Não aceita |
|---|---|---|
| `icon` | `po-input`, `po-combo` | `po-select`, `po-number`, `po-textarea`, `po-password` |
| `readonly` | `po-input`, `po-combo`, `po-textarea`, `po-rich-text` | `po-select`, `po-number`, `po-password` |
| `placeholder` | todos | — |

Por isso o Detalhar converte **todo** campo em texto `readonly` com o valor já traduzido, em vez de desabilitar os campos do formulário.

**Com até 3 opções o formulário usa botões de rádio.** Para combo, `forceOptionsComponentType: ForceOptionComponentEnum.select`.

**`po-password` já traz um cadeado à esquerda** por conta própria — o PO UI também só usa ícone onde ele diz o tipo do campo.

## `po-rich-text`

**Propaga o modelo no `keyup`, no blur e nos comandos da barra** — não a cada caractere. Automação que insere texto via CDP não dispara `keyup`, e o valor parece não ser salvo; com teclado real funciona.

**Com `p-readonly` a barra de ferramentas continua visível.** Para sumir com ela, esconder todas as ações (`p-hide-toolbar-actions` com todos os valores de `PoRichTextToolbarActions`) — aí o componente omite a barra inteira e sobra só a moldura, que é o que o Detalhar usa.

**Texto puro vira uma linha só** no editor: as quebras precisam virar `<br>` antes de abrir, e o usuário precisa saber que o valor passará a ser gravado como HTML.

## `po-menu`

**O menu não empurra o conteúdo sozinho.** O `po-menu` é `position: fixed` e ocupa **56px recolhido / 290px expandido**; quem desloca o conteúdo é o CSS da aplicação. Com margem fixa de 56px, o menu aberto cobre o conteúdo (corrigido em 2026-10-02 no `app.css`, compartilhado pelos dois apps).

**O estado vem por classe no host:** o PO UI põe `po-collapsed-menu` no `app-root` quando o menu está recolhido e a remove ao expandir — daí `:host(:not(.po-collapsed-menu)) .app-content { margin-left: 290px }`.

**Abaixo de ~1200px o menu deixa de ser fixo**: ele sai da tela (`left: -290px`) e passa a abrir sobreposto, por um botão de hambúrguer que o PO UI desenha numa faixa própria acima do conteúdo. Nessa faixa o conteúdo não é deslocado **nem reserva espaço** — `margin-left: 0`, porque não há barra lateral ocupando largura (medido com 1100px e 375px, recarga limpa, sem rolagem horizontal). Daí as duas faixas no `app.css`: `@media (min-width: 1200px)` desloca 290px com o menu aberto; `@media (max-width: 1199px)` zera a margem.

**`po-menu` não tem divisor nativo.** A separação visual dos grupos no app de cadastro é feita por CSS ancorado no `href` do primeiro item de cada grupo (`app-cadastro.css`).

## `po-disclaimer-group`

**O "x" do disclaimer nem sempre chega ao `(p-change)`.** No `thl-crud-page` o clique remove a tag do DOM — o componente faz `splice` no próprio array que recebeu — mas o handler ligado a `p-change` não foi chamado, então a tela ficava filtrada com a tag some (verificado em 2026-10-08, PO UI 21.30). A saída foi `hideClose: true` nos disclaimers e um botão próprio para limpar.

**O componente muta o array que você passa.** Guardar o array no componente e esperar que ele reflita o estado é enganoso: depois de um clique no "x" ele já está sem o item, mesmo sem evento.

## `po-modal` e `po-tabs`

**`po-tabs` renderiza todas as abas** e esconde as inativas com `display: none` — vale para validação (o campo obrigatório pode estar em aba fechada) e para qualquer componente que precise medir a si mesmo ao desenhar.

**`po-page-detail` não tem `p-edit`.** Para uma página de detalhe com ação de editar, use `po-page-default` com `pageActions`.

## CSS

**`::ng-deep` é obrigatório para conteúdo vindo de `[innerHTML]`** — o CSS com escopo do componente não alcança esse conteúdo (foi o caso dos marcadores de lista que apareciam fora do bloco).

**O tema zera o recuo das listas**: `ul`/`ol` dentro de HTML renderizado precisam de `padding-left` explícito.

**As linhas do grid PO UI têm margem negativa** e criam rolagem horizontal dentro de modal; o container do formulário usa `overflow-x: hidden`.

## Angular

**`ng.getComponent()` / `ng.applyChanges()`** funcionam no build de desenvolvimento e servem para inspecionar ou injetar estado ao verificar uma tela sem backend — foi assim que os rótulos de status e o estado de erro dos monitores foram provados sem PASOE.

**A mensagem do `HttpErrorResponse` é técnica** (`Http failure during parsing for …`). Para o usuário, mostrar só `error.message` do corpo da resposta e, na falta dele, uma frase do app.

## `po-datetimepicker` — data e hora num campo PO UI (2026-10-13)

Existe desde o PO UI 21 e resolve o que o `po-datepicker` não faz: data **e** hora no mesmo campo, com o visual do tema. Está em uso nos filtros avançados dos três monitores.

Três comportamentos descobertos rodando, que mudam como se lê o valor:

- **O modelo é texto ISO com fuso**, não `Date`: digitar `13/10/2026 08:30` grava `2026-10-13T08:30-03:00`. O backend quer `yyyy-MM-ddTHH:mm` sem fuso — é preciso recortar.
- ⚠️ **Com o campo incompleto, ele grava a string `"Data/hora inválida"` no modelo** — não deixa vazio nem `null`. Quem tratar o valor como data monta um filtro com lixo (`Data/hora T00:00` chegou a sair na query string antes da correção). Valide o formato antes de usar.
- ⚠️ **Campo incompleto não é sinalizado**: o controle fica `ng-valid`, sem borda vermelha nem mensagem. Quem digita só a data e aciona o filtro não recebe aviso nenhum. Nos monitores, o valor digitado é lido do próprio input como resgate (`textoDigitadoParaFaixa`), e a data sozinha vale o dia inteiro.

**Largura:** o campo não cabe em `po-md-3` — o rótulo e o placeholder `dd/mm/aaaa hh:mm` ficam truncados. Use `po-md-6`, dois por linha.

## Campo dentro de `po-tab` oculto **funciona** (2026-10-14)

A lição registrada de que "`po-table` dentro de `po-tab` oculto não desenha" vale para a tabela, e só para ela. Campos de formulário em aba inativa **mantêm o valor e são submetidos normalmente**: no filtro avançado da mensageria, preencher `Cód. Mensagem` na aba Avançado, trocar para a Principal e acionar Filtrar envia os dois campos (`codigoIni=abc-123&aplicacaoIni=datasul`, verificado na query string).

O cuidado que sobra é de UX, não de renderização: **o que está preenchido na aba oculta fica invisível**. Os rótulos das abas trazem contador (`Avançado (1)`) e o `po-disclaimer-group` fora do modal lista os filtros ativos.

`p-active` é booleano: `p-active="true"` não compila (`TS2322: Type 'string' is not assignable to type 'boolean'`). Use `[p-active]="true"`.

## `po-disclaimer-group` emite `(p-change)` também quando a tela preenche a lista (2026-10-14)

O evento não distingue "o usuário removeu um filtro" de "a tela montou os filtros". Preencher `p-disclaimers` programaticamente dispara o mesmo `(p-change)` da remoção.

Nos monitores, o `ngOnInit` lia os `queryParams`, montava os disclaimers e chamava `carregar()`; o `(p-change)` disparado pela montagem chamava `carregar()` de novo. Resultado: **duas consultas idênticas** em toda navegação com filtro na URL — medido com `XMLHttpRequest.open` instrumentado, com as duas pilhas apontando para `ngOnInit` e `onChangeDisclaimers`.

Sem filtro na URL não havia duplicação, porque a lista continuava vazia e o evento não disparava — o que escondia o defeito no uso mais comum.

**Como tratar:** guardar a assinatura da lista que a própria tela montou (`property=value` ordenados) e ignorar o evento quando a lista recebida for igual. Lista menor = o usuário removeu algo, e aí o handler roda. O risco de usar uma flag booleana é o evento chegar em outro ciclo de detecção e a flag já ter sido limpa.

⚠️ **O componente não reinicializa quando só mudam os `queryParams` da mesma rota.** Navegar de `#/mensageria` para `#/mensageria?aplicacao=X` não roda `ngOnInit` de novo, e um filtro lido de `route.snapshot` é ignorado. Hoje isso não aparece no uso real (os atalhos partem das telas de métricas, que são outra rota), mas quem ligar filtro por URL dentro da mesma tela precisa assinar `route.queryParams` em vez de ler o `snapshot`.

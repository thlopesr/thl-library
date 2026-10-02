# PO UI 21 — armadilhas verificadas no projeto

Comportamentos do PO UI que custaram tempo ou geraram defeito no `Fontes\web`, **todos confirmados rodando**, não deduzidos da documentação. Catálogo genérico do PO UI em [poui/INDEX.md](../poui/INDEX.md); o que o app faz com isso em [app-web.md](app-web.md) e [motor-cadastro.md](motor-cadastro.md).

## `po-table`

**`PoTableColumnLabel`: `value` casa com o dado, `label` é o texto exibido.** Invertê-los não quebra nada — a cor e o ícone saem certos e a célula mostra o conteúdo do `label`. Os três monitores ficaram mostrando `1`, `2`, `3` no lugar de Sucesso, Erro e Pendente (corrigido em 2026-10-02; rótulos agora em `shared\domain\status-labels.ts`).

**`type: 'label'` deixa a célula vazia quando o valor não está na lista.** Dado fora do domínio some da tela em vez de aparecer errado — pior, porque esconde inconsistência. O motor acrescenta os valores inesperados como tag neutra (`completarTags`).

**`type` (semântico) sobrepõe cor e ícone.** Com `type: 'info'`, o ícone informado é trocado pelo ícone padrão do tipo. Para manter um ícone próprio (a seta de Entrada/Saída), use `color` do tema (`color-01`…`color-12`) e não `type`.

**Um `po-table` criado dentro de `po-tab` oculto fica em branco** até receber um evento de mouse. O `po-tab` renderiza todas as abas e só esconde as inativas. Solução: o pai guarda a aba ativa pelo `(p-click)` do `po-tab` e a aba só renderiza a tabela quando visível.

**`p-container` é string, não boolean** — `[p-container]="true"` não compila.

**A coluna de ações nativa (`p-actions`) não aceita título.** Para ter a coluna "Ação" com cabeçalho, use `type: 'cellTemplate'` com o `thl-row-actions`.

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

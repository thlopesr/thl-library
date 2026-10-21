---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# TABLE-COMPONENTS.md

## 4.1 po-table

### Propriedades (p-*)
| Propriedade | Tipo | Default | Descrição |
|---|---|---|---|
| `p-columns` | `Array<PoTableColumn>` | 1ª coluna dos items | Definição das colunas |
| `p-items` | `Array<any>` | — | Dados exibidos |
| `p-actions` | `Array<PoTableAction>` | — | Ações por linha |
| `p-height` | `number` | — | Altura fixa (habilita scroll/infinite-scroll) |
| `p-hide-columns-manager` | `boolean` | `false` | Oculta gerenciador de colunas |
| `p-hide-text-overflow` | `boolean` | `false` | **Depreciada (v17)** — reticências automáticas por acessibilidade |
| `p-loading` | `boolean` | `false` | Estado de carregamento |
| `p-selectable` | `boolean` | `false` | Habilita seleção de linhas |
| `p-single-select` | `boolean` | `false` | Seleção única (radio) |
| `p-show-more-disabled` | `boolean` | `false` | Desabilita "Carregar mais" |
| `p-sort` | `boolean` | `false` | Habilita ordenação |
| `p-striped` | `boolean` | `false` | Zebrado |
| `p-container` | `'border' \| 'shadow'` | `'border'` | Container visual (ver Pegadinhas: `'shadow'` foi restringida) |
| `p-auto-collapse` | `boolean` | `false` | Collapse em mobile |
| `p-selectable-entire-line` | `boolean` | `true` | Seleciona clicando na linha inteira |
| `p-infinite-scroll` | `boolean` | `false` | Scroll infinito (requer `p-height`) |
| `p-infinite-scroll-distance` | `number` | `100` | % do scroll para disparar `p-show-more` |
| `p-draggable` | `boolean` | `false` | Drag and drop de colunas |
| `p-service-api` | `string` | — | URL para carga/paginação automática |
| `p-spacing` | `PoTableColumnSpacing` | — | Padding das células |
| `p-text-wrap` | `boolean` | `false` | Quebra de linha no conteúdo |

Constantes do source: `poTableContainerDefault = 'border'`, `poTableParamDeleteApi = 'id'`.

### PoTableColumn — interface
Propriedades principais: `property`, `label`, `type`, `format`, `width`, `visible`, `color`, `labels`, `icons`, `subtitles`, `tooltip`, `action`, `sortable`.
> Nota de fonte: a comunidade pediu `notSort` (Issue #960), mas a propriedade oficial adotada é `sortable`.

**Tipos de coluna (verbatim do JSDoc de `po-table-column.interface.ts`):** `string`, `number`, `currency`, `date`, `dateTime`, `time`, `boolean`, `icon`, `label`, `link`, `subtitle`, `color`, `cellTemplate`, `columnTemplate`, `detail`.
- `time`: aceita `'HH:mm:ss'` ou `'HH:mm:ss.ffffff'` (ex.: `'23:12:45'`).
- `cellTemplate`/`columnTemplate`: usar com `PoTableCellTemplate`/`PoTableColumnTemplate`.
- `visible: false`: coluna oculta, porém restaurável pelo **gerenciador de colunas**.
- Suporta objetos aninhados via *dot notation*: `property: 'client.fantasyName'`.

Exemplo de coluna `icon`:
```typescript
{ property: 'columnIcon', label: 'Actions', type: 'icon', icons: [
  { value: 'add',    icon: 'an an-plus',           color: 'color-06', action: this.add.bind(this),    tooltip: 'Adiciona um novo item' },
  { value: 'edit',   icon: 'an an-pencil-simple',                     action: this.edit.bind(this) },
  { value: 'delete', icon: 'an an-trash',          color: 'color-12', action: this.remove.bind(this) }
]}
```
Exemplo de coluna `label` colorida (`labels`):
```typescript
{ property: 'status', label: 'Status', type: 'label', labels: [
  { value: 'confirmed', color: 'color-11', label: 'Confirmado', tooltip: 'Flight Status' },
  { value: 'delayed',   color: 'color-08', label: 'Atrasado' }
]}
```

### PoTableAction — interface
`action` (função), `label` (texto), `icon`, `separator` (boolean — separador visual), `type` (`'default' | 'danger'`), `disabled` (função/boolean), `visible` (função/boolean).
```typescript
actions: Array<PoTableAction> = [
  { label: 'Editar', icon: 'an an-pencil-simple', action: (row) => this.edit(row) },
  { label: 'Visualizar', icon: 'an an-eye', action: (row) => this.view(row) },
  { label: 'Excluir', icon: 'an an-trash', type: 'danger', separator: true,
    action: (row) => this.confirmDelete(row),
    disabled: (row) => row.status === 'locked' }
];
```

### Eventos do po-table
- `(p-show-more)` → `EventEmitter<PoTableColumnSort>` — carregar mais registros.
- `(p-sort-by)` → `EventEmitter<PoTableColumnSort>` — ordenação (nome exato do evento confirmado no source: **`p-sort-by`**).
- `(p-selected)`, `(p-unselected)` — seleção/desseleção de linha.
- `(p-all-selected)`, `(p-all-unselected)` — seleção total via checkbox de cabeçalho.
- `(p-change-visible-columns)`, `(p-change-fixed-columns)`, `(p-restore-column-manager)` — gerenciador de colunas.

`PoTableColumnSort = { column: PoTableColumn, type: PoTableColumnSortType }` (enum `Ascending`/`Descending`).

### Padrões de uso

**Paginação server-side via `p-service-api`.** Confirmado no source oficial (`po-page-dynamic-table.component.ts`), a montagem de parâmetros é:
```typescript
const defaultParams: any = { page: 1, pageSize: PAGE_SIZE_DEFAULT };
const fullParams: any = { ...defaultParams, ...params, ...orderParam };
```
Ou seja, `page` default = `1` e `pageSize` default = a constante `PAGE_SIZE_DEFAULT` (o valor literal não foi exposto no snippet; a convenção documentada da API PO-UI é `10`). A resposta é consumida assim (verbatim):
```typescript
// po-page-dynamic-table.component.ts
this.items = newArray ? [...newArray] : this.items;
this.page = fullParams.page;
this.hasNext = response.hasNext;
// po-table-base.component.ts
this.items = data.items || [];
this.showMoreDisabled = !data.hasNext;
```
Para ordenação, a coluna é enviada no parâmetro `order` (ex.: `order=name` asc, `order=-name` desc).

**Paginação manual (`p-show-more`) + ordenação server-side:**
```html
<po-table [p-columns]="columns" [p-items]="items" [p-sort]="true"
  [p-show-more-disabled]="disableNext"
  (p-show-more)="carregarMais()" (p-sort-by)="onSort($event)"></po-table>
```
```typescript
carregarMais(): void {
  this.page++;
  this.service.get(this.page, this.pageSize, this.order).subscribe(r => {
    this.items = [...this.items, ...r.items];
    this.disableNext = !r.hasNext;
  });
}
onSort(sort: PoTableColumnSort): void {
  this.order = (sort.type === PoTableColumnSortType.Descending ? '-' : '') + sort.column.property;
  this.page = 1;
  this.reload();
}
```

**Seleção + ação em lote:** habilite `p-selectable` e ouça `(p-selected)`/`(p-all-selected)`; recupere os marcados via `this.items.filter(i => i.$selected)`.

**Template de célula customizado:**
```html
<po-table [p-columns]="columns" [p-items]="items">
  <ng-template p-table-cell-template let-column="column" let-row="row">
    <span *ngIf="column.property === 'ativo'">{{ row.ativo ? 'Ativo' : 'Inativo' }}</span>
  </ng-template>
</po-table>
```

**CRUD completo com confirmação de exclusão (PoDialogService):**
```typescript
confirmDelete(row: any): void {
  this.poDialog.confirm({
    title: 'Confirmar exclusão',
    message: `Deseja excluir ${row.nome}?`,
    confirm: () => this.service.delete(row.id).subscribe(() => {
      this.poNotification.success('Registro excluído');
      this.reload();
    })
  });
}
```

### Pegadinhas — po-table
- `hasNext` (boolean) é o único sinal de paginação; **não use `total`**.
- `p-infinite-scroll` só funciona com `p-height` definido **e** com scroll já presente na carga inicial dos dados.
- `p-hide-text-overflow` foi **depreciada** (v17): "por regras de acessibilidade a célula apresentará reticências automaticamente quando não houver espaço".
- A opção `'shadow'` do container foi restringida: o CHANGELOG registra "container: removida propriedade `p-no-shadow` — não é mais possível definir shadow por questões de acessibilidade e usabilidade". Prefira `'border'`.
- Coluna `type: 'icon'` exige que o item traga o `value` correspondente ao ícone mapeado.

Doc oficial: https://po-ui.io/documentation/po-table

## 4.2 po-list-view
Alternativa ao `po-table` quando o foco é exibição em **cards / detalhe expansível** por item (em vez de grade densa). Propriedades: `p-items`, `p-property-title`, `p-property-subtitle`, `p-actions` (`Array<PoListViewAction>`), `p-show-more`. **Requer `BrowserAnimationsModule`** no módulo principal.
```html
<po-list-view p-property-title="name" [p-items]="items">
  <ng-template p-list-view-detail-template let-item let-code="index">
    <div class="po-row">
      <po-info class="po-md-6"  p-label="Code"  [p-value]="code"></po-info>
      <po-info class="po-md-12" p-label="Email" [p-value]="item.email"></po-info>
    </div>
  </ng-template>
</po-list-view>
```

## 4.3 po-tree-view
Dados hierárquicos via `PoTreeViewItem` (propriedades típicas: `label`, `value`, `subItems`, `expanded`, `selectable`). Propriedades do componente: `p-items`, `p-single-select`, `p-selectable`. Eventos de expansão/seleção: `(p-expanded)`, `(p-collapsed)`, `(p-selected)`, `(p-unselected)`.
> Nota de fonte: os nomes exatos das propriedades/eventos do `po-tree-view` não puderam ser confirmados verbatim no source (GitHub bloqueado e po-ui.io é SPA); tratar como referência a confirmar contra a versão instalada.

---

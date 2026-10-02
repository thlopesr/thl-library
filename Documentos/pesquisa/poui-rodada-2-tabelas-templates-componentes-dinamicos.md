# PO-UI — Rodada 2/4: Tabelas, Templates de Página e Componentes Dinâmicos (pt-BR)

## TL;DR
- O sistema *metadata-driven* (`po-page-dynamic-*` + `po-dynamic-form`/`po-dynamic-view`) é o caminho recomendado para o CRUD do módulo THL: gera telas a partir de um contrato JSON (`page`/`pageSize`/`order` → `{ items, hasNext }`) e reduz drasticamente o código de tela.
- `po-table` é o componente central de listagem, com paginação server-side (via `p-service-api` ou `(p-show-more)`), ordenação server-side via `(p-sort-by)`, seleção em lote e colunas customizadas por template.
- Fontes verificadas: código-fonte oficial em `po-ui/po-angular` e `po-ui.io/documentation`. **GitHub bloqueia fetch automatizado e po-ui.io é uma SPA** — vários tipos/defaults foram confirmados por *snippets* de código e do CHANGELOG; os itens não confirmáveis estão sinalizados explicitamente ao longo do texto.

## Key Findings
- **Contrato server-side** do `po-table` e dos *dynamics*: envia `page`, `pageSize` e `order` (prefixo `-` para descendente) e espera `{ items, hasNext }`. Não usa `total`/`totalCount`.
- **`PoDynamicFormField.type`** define o componente renderizado por regras determinísticas (boolean→po-switch, number→po-number, currency→po-decimal, options≤3→radio/checkbox, options≥3→select/multiselect, optionsService→po-combo, searchService→po-lookup).
- **Templates dinâmicos** suportam roteamento automático (`p-auto-router`) e rotas com `data: { serviceApi, serviceMetadataApi, serviceLoadApi }`, com cache de metadata versionado no browser.
- **Deprecações relevantes** (CHANGELOG oficial): `p-hide-text-overflow` (reticências agora automáticas por acessibilidade) e a opção `'shadow'` de container (`p-no-shadow` removida por acessibilidade/usabilidade).

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

# PAGE-TEMPLATES.md

## 5.1 Templates estáticos

Módulo: `PoPageModule` — cobre `po-page-default`, `po-page-detail`, `po-page-edit`, `po-page-list` e `po-page-slide`.

### po-page-default
`p-title` (string), `p-breadcrumb` (`PoBreadcrumb`), `p-actions` (`Array<PoPageAction>`).
- `PoPageAction`: `label`, `action` (função), `icon`, `disabled`, `visible`, `url`, `type` (`'default' | 'danger'`).
- `PoBreadcrumb`: `{ items: Array<PoBreadcrumbItem>, favorite?, ... }`.
- `PoBreadcrumbItem`: `{ label, link?, action? }`.
```html
<po-page-default p-title="Produtos" [p-actions]="actions" [p-breadcrumb]="breadcrumb">
  <po-table [p-columns]="columns" [p-items]="items"></po-table>
</po-page-default>
```
```typescript
public readonly actions: Array<PoPageAction> = [
  { label: 'Atualizar', action: this.getItems.bind(this), icon: 'an an-arrows-clockwise' },
  { label: 'Novo', action: () => this.router.navigate(['/new']) }
];
```

### po-page-list
Template de listagem com busca rápida, filtro avançado e *disclaimers*.
- `p-title`, `p-actions` (`Array<PoPageAction>` — Novo, Exportar etc.).
- `p-filter` (`PoPageFilter`) — busca rápida.
- `p-disclaimer-group` (`PoDisclaimerGroup`) — filtros ativos.

Interfaces:
- `PoPageFilter`: `action`, `advancedAction`, `placeholder`, `width`.
- `PoDisclaimerGroup`: `disclaimers`, `title`, `change`, `remove`, `removeAll`, `hideRemoveAll`.
- `PoDisclaimer`: `value`, `label`, `property`, `hideClose`.

Padrão: busca rápida (`p-filter.action`) + filtro avançado (`p-filter.advancedAction`) alimentando `p-disclaimer-group.disclaimers`, com `po-table` no conteúdo.

### po-page-detail
Ações padrão via eventos `(p-back)`, `(p-edit)`, `(p-remove)`; breadcrumb via `p-breadcrumb`. No conteúdo, use `po-info` e `po-tag` para exibir os campos do registro.

### po-page-edit
Container para edição/criação com ações "Salvar", "Salvar e Novo" e "Cancelar".
- `p-disable-submit` (boolean) — desabilita Salvar/Salvar e Novo (ex.: form inválido).
- Eventos `(p-save)`, `(p-save-new)`, `(p-cancel)`.
```html
<po-page-edit [p-disable-submit]="form.invalid" p-title="Cadastro de Pessoa"
  (p-save)="save()" (p-save-new)="saveNew()" (p-cancel)="cancel()">
  <form #form="ngForm">
    <div class="po-row">
      <po-input class="po-md-6" name="nome" [(ngModel)]="pessoa.nome" p-label="Nome" p-required></po-input>
    </div>
  </form>
</po-page-edit>
```

## 5.2 Templates dinâmicos (metadata-driven)

### po-page-dynamic-table
Aponta para uma API e renderiza listagem, filtros e ações automaticamente.

Propriedades (confirmadas verbatim na doc oficial — seletor do componente): `p-actions`, `p-actions-right`, `p-auto-router`, `p-breadcrumb`, `p-concat-filters`, `p-draggable`, `p-fields`, `p-height`, `p-hide-close-disclaimers`, `p-hide-columns-manager`, `p-hide-remove-all-disclaimer`, `p-infinite-scroll`, `p-keep-filters`, `p-load`, `p-page-custom-actions`, `p-quick-search-param`, `p-quick-search-value`, `p-quick-search-width`, `p-literals`, `p-service-api`, `p-spacing`, `p-table-custom-actions`, `p-text-wrap`, `p-title`, `p-components-size`.

Contrato da API que o componente espera:
- `GET /` → `{ items, hasNext }` (recebe `page`, `pageSize`, `order` e filtros como query params).
- `DELETE /:id` → exclusão individual; **DELETE em lote** via `?ids=`.
- `GET {end-point}/metadata?type=list&version={version}` → metadata dos campos (usado quando `serviceMetadataApi` não é especificado).

Metadata (verbatim do source):
```json
{
  "version": 1,
  "title": "Person Table",
  "fields": [
    { "property": "id", "key": true, "disabled": true },
    { "property": "status" },
    { "property": "name" },
    { "property": "nickname" },
    { "property": "birthdate", "label": "Birth date" },
    { "property": "genre" },
    { "property": "city" },
    { "property": "country" }
  ],
  "keepFilters": true
}
```

`PoPageDynamicTableActions` (confirmado no CHANGELOG e source): `new`, `edit`, `detail`, `duplicate`, `remove`, `removeAll`, `beforeNew`, `beforeEdit`, `beforeDuplicate`, `beforeDetail`, `beforeRemove`, `beforeRemoveAll`. Interfaces auxiliares: `PoPageDynamicTableCustomAction` (ação de página) e `PoPageDynamicTableCustomTableAction` (ação na linha).
```typescript
readonly serviceApi = 'https://po-sample-api.onrender.com/v1/hotels';
readonly actions: PoPageDynamicTableActions = {
  new: '/documentation/po-page-dynamic-edit',
  remove: true,
  removeAll: true
};
readonly breadcrumb: PoBreadcrumb = { items: [{ label: 'Home', link: '/' }, { label: 'Hotéis' }] };
```
```html
<po-page-dynamic-table
  [p-auto-router]="true" [p-concat-filters]="true" [p-keep-filters]="true"
  p-title="Hotéis" [p-actions]="actions" [p-actions-right]="true"
  [p-page-custom-actions]="pageCustomActions" [p-table-custom-actions]="tableCustomActions"
  [p-breadcrumb]="breadcrumb" [p-fields]="fields" [p-service-api]="serviceApi"
  [p-quick-search-width]="quickSearchWidth" [p-text-wrap]="true">
</po-page-dynamic-table>
```
As ações `beforeRemove`/`beforeRemoveAll` interceptam a exclusão: podem apontar para uma URL (POST) ou método que retorna uma estrutura que permite cancelar/alterar a operação antes do `remove`.

### po-page-dynamic-search
Diferença para o dynamic-table: **só executa a pesquisa** (busca rápida + avançada) e emite os filtros; a exibição dos resultados fica por conta do desenvolvedor. Propriedades relevantes (confirmadas no source): `p-quick-search-width` (número, limitado a **6 colunas** do Grid System), `p-keep-filters` (default `false`), `p-concat-filters` (default `false` — concatena a busca rápida na lista de *disclaimers*), `p-hide-remove-all-disclaimer`, `p-hide-close-disclaimers`. Filtros via `PoPageDynamicSearchFilters` (suporta `initValue` para valor default no disclaimer).

### po-page-dynamic-detail
`p-service-api`, `p-fields`, `p-actions` (`back`, `edit`, `remove`). Contrato: `GET /:id`. `PoPageDynamicDetailActions`: `back`, `edit`, `remove`, `beforeBack`, `beforeEdit`, `beforeRemove`.

### po-page-dynamic-edit
Formulário dinâmico para criar/editar. Seletor (verbatim doc): `p-actions`, `p-auto-router`, `p-breadcrumb`, `p-components-size`, `p-fields` (`Array<PoPageDynamicEditField>` — herda `PoDynamicFormField`), `p-literals`, `p-notification-type`, `p-load` (`string | (() => PoPageDynamicEditOptions)`), `p-load-data`, `p-service-api`, `p-title`.
Contrato: `GET /:id`, `POST /`, `PUT /:id`, e `GET {end-point}/metadata?type=edit&version={version}`.
`PoPageDynamicEditActions`: `save`, `saveNew`, `cancel`, `beforeSave`, `beforeSaveNew`, `beforeCancel`.
```typescript
import { PoPageDynamicEditActions, PoPageDynamicEditField } from '@po-ui/ng-templates';

readonly serviceApi = 'https://po-sample-api.onrender.com/v1/people';
readonly actions: PoPageDynamicEditActions = {
  save: '/documentation/po-page-dynamic-detail',
  saveNew: '/documentation/po-page-dynamic-edit'
};
readonly fields: Array<PoPageDynamicEditField> = [
  { property: 'id', key: true, visible: false },
  { property: 'name', label: 'Nome', divider: 'Dados pessoais' },
  { property: 'birthdate', label: 'Data de nascimento', type: 'date' },
  { property: 'genre', label: 'Gênero', gridXlColumns: 4, options: [
      { value: 'feminino', label: 'Feminino' },
      { value: 'masculino', label: 'Masculino' }
  ]}
];
```
Validações customizadas: use `p-load` para transformar a metadata em runtime, ou a propriedade `validate` de cada field (URL/função retornando `PoDynamicFormValidation`).

### Fluxo CRUD dinâmico (roteamento end-to-end)
Roteamento por `data` (o componente lê `serviceApi`/`serviceMetadataApi`/`serviceLoadApi` do `ActivatedRoute`):
```typescript
{
  path: 'people',
  component: PoPageDynamicTableComponent,
  data: {
    serviceApi: 'http://localhost:3000/v1/people',       // endpoint de dados
    serviceMetadataApi: 'http://localhost:3000/v1/metadata', // metadata (GET)
    serviceLoadApi: 'http://localhost:3000/load-metadata'    // customização (POST)
  }
}
```
Com `p-auto-router`, o template navega automaticamente entre **list → detail → edit → new**. A metadata é buscada na inicialização enviando o `type` esperado e a `version` cacheada pelo browser; **se o servidor de metadata falhar, o cache é reutilizado** (e, se não houver cache, é disparada uma notificação).

---

# DYNAMIC-COMPONENTS.md

## 6.1 po-dynamic-form
Formulário renderizado a partir de `p-fields` (`Array<PoDynamicFormField>`) e `p-value` (objeto de valores). Suporta `p-auto-focus` (nome da `property` que recebe foco), `p-group-form`, evento `(p-form-validate)` e validação por campo (`validateFields`).

### Interface PoDynamicFormField — propriedades confirmadas
Único membro obrigatório: **`property: string`**.
`property`, `label`, `type`, `required`, `disabled`, `visible`, `key`, `divider`, `container`, `gridColumns`, `gridSmColumns`, `gridMdColumns`, `gridLgColumns`, `gridXlColumns`, `order`, `minLength`, `maxLength`, `min`, `max`, `rows`, `options`, `optionsMulti`, `optionsService`, `searchService`, `columns`, `fieldLabel`, `fieldValue`, `validate`, `mask`, `pattern`, `format`, `locale`, `icon`, `help`, `secret`, `noAutocomplete`, `placeholder`, `params`, `range`, `decimalsLength`, `thousandMaxlength`, `concatLabelValue`, `optional`, `forceBooleanComponentType`, `errorMessage`, `additionalHelpTooltip`, `booleanTrue`, `booleanFalse`.

> Confiança de fonte: `searchService`, `fieldLabel`, `fieldValue`, `concatLabelValue` e `locale` estão confirmados no CHANGELOG oficial (adições à interface). A maioria dos **defaults** dessas propriedades **não é declarada na interface** — eles são aplicados pelos componentes-alvo (ex.: `po-decimal` aplica `decimalsLength` = 2; `time` aplica máscara `'99:99'`). Os tipos exatos de union e marcadores de opcionalidade de alguns campos (`gridMdColumns`, `gridLgColumns`, `gridXlColumns`, `order`, `columns`, `min`, `max`, `format`, `locale`, `icon`, `help`, `noAutocomplete`, `errorMessage`, `additionalHelpTooltip`, `booleanTrue`, `booleanFalse`) **não puderam ser confirmados verbatim** do arquivo `.interface.ts`.

### Regras de type → componente (verbatim do JSDoc de po-dynamic-form-base.component.ts)
- `string` → `po-input`
- `currency` **sem** `mask`/`pattern` → `po-decimal`; **com** `mask`/`pattern` → `po-input`
- `number` **sem** `mask`/`pattern` → `po-number`; **com** `mask`/`pattern` → `po-input`
- `time` → `po-input` com máscara `99:99` por padrão
- `date` → `po-datepicker` (`range: true` → datepicker-range)
- `boolean` → `po-switch` (pode ser forçado via `forceBooleanComponentType` / `ForceBooleanComponentEnum`)
- `options` com **≤3** itens → `po-radio-group` (ou `po-checkbox-group` se `optionsMulti`)
- `options` com **≥3** itens → `po-select` (ou `po-multiselect` se `optionsMulti`)
- `optionsService` informado → `po-combo`
- `searchService` informado → `po-lookup` (com `columns`, `fieldLabel`, `fieldValue`)
- `rows >= 3` → `po-textarea`; `rows < 3` → `po-input`
- `secret: true` → `po-password`

> Nota de fonte: o literal `dateTime` como `type` distinto e a regra exata do corte "≤3/≥3" para options não puderam ser 100% confirmados verbatim no snippet do source (o corpo do JSDoc de `po-dynamic-form-base.component.ts` não foi totalmente exposto); a regra options e as demais linhas acima estão confirmadas.

### Exemplo completo
`sample-po-dynamic-form-register.component.ts` (imports e forma reais):
```typescript
import { Component, OnInit, ViewChild, inject } from '@angular/core';
import {
  PoDynamicFormField, PoDynamicFormFieldChanged, PoDynamicFormValidation,
  PoNotificationService, ForceBooleanComponentEnum, PoDynamicFormComponent
} from '@po-ui/ng-components';

@Component({ selector: 'app-cadastro', templateUrl: './cadastro.component.html' })
export class CadastroComponent implements OnInit {
  private poNotification = inject(PoNotificationService);
  @ViewChild('dynamicForm', { static: true }) dynamicForm!: PoDynamicFormComponent;

  person: any = {};
  validateFields: Array<string> = ['state'];

  fields: Array<PoDynamicFormField> = [
    { property: 'name', divider: 'DADOS PESSOAIS', required: true, minLength: 4, maxLength: 50,
      gridColumns: 6, gridSmColumns: 12, order: 1, placeholder: 'Digite seu nome' },
    { property: 'birthday', label: 'Data de nascimento', type: 'date', format: 'dd/MM/yyyy', gridColumns: 6 },
    { property: 'state', label: 'Estado', gridColumns: 6,
      options: [{ code: 1, state: 'Santa Catarina' }, { code: 2, state: 'São Paulo' }],
      fieldLabel: 'state', fieldValue: 'code' },
    { property: 'city', label: 'Cidade', gridColumns: 6, disabled: true },       // habilitado via validate de 'state'
    { property: 'vacation', label: 'Férias', type: 'date', range: true, divider: 'DADOS PROFISSIONAIS', gridColumns: 5 },
    { property: 'entryTime', label: 'Horário de entrada', type: 'time', gridColumns: 2 },
    { property: 'wage', label: 'Salário', type: 'currency', gridColumns: 3, decimalsLength: 2, thousandMaxlength: 7,
      icon: 'an an-currency-circle-dollar' },
    { property: 'active', label: 'Ativo', type: 'boolean' },
    { property: 'client', label: 'Cliente', searchService: '/api/clientes',
      columns: [{ property: 'id', label: 'Código' }, { property: 'name', label: 'Nome' }],
      fieldLabel: 'name', fieldValue: 'id' },
    { property: 'country', label: 'País', optionsService: '/api/paises' },
    { property: 'hobbies', label: 'Hobbies', gridColumns: 6, optional: true,
      options: ['Futebol', 'Basquete', 'Leitura'], optionsMulti: true }
  ];

  onChangeState(changed: PoDynamicFormFieldChanged): PoDynamicFormValidation {
    if (changed.property === 'state') {
      return { fields: [{ property: 'city', disabled: false }] };
    }
    return {};
  }
  ngOnInit(): void {}
}
```
```html
<po-dynamic-form #dynamicForm [p-fields]="fields" [p-value]="person"
  [p-validate-fields]="validateFields" (p-form-validate)="onChangeState($event)">
</po-dynamic-form>
```
Campos condicionais: use `validate`/`(p-form-validate)` retornando `PoDynamicFormValidation`, que pode alterar `fields` (ex.: `visible`, `disabled`, `required`) e `value` em runtime.

## 6.2 po-dynamic-view
Exibição somente-leitura via `p-fields` (`Array<PoDynamicViewField>`) + `p-value`. Cada field suporta: `property`, `label`, `type`, `tag` (boolean — renderiza como `po-tag`), `color`, `format`, `divider`, `gridColumns`, entre outros.
- `date`: aceita formato do **DatePipe** e caracteres dd/MM/yyyy; **default `'dd/MM/yyyy'`**.
- `time`: aceita HH/mm/ss e milissegundos (f-ffffff, opcionais); **default `'HH:mm:ss'`**.
```html
<po-modal #hotelDetailModal p-title="Detalhe do Hotel">
  <po-dynamic-view [p-fields]="detailFields" [p-value]="detailedHotel"></po-dynamic-view>
</po-modal>
```
```typescript
detailFields: Array<PoDynamicViewField> = [
  { property: 'name', label: 'Nome', divider: 'Identificação', gridColumns: 6 },
  { property: 'status', label: 'Status', tag: true, color: 'color-11' },
  { property: 'checkin', label: 'Check-in', type: 'date', format: 'dd/MM/yyyy' }
];
```

## 6.3 Contrato JSON de metadata (referência)
```json
{
  "version": 1,
  "title": "Person edit",
  "fields": [
    { "property": "id", "key": true, "disabled": true },
    { "property": "status" },
    { "property": "name" },
    { "property": "birthdate", "label": "Birth date" }
  ],
  "actions": [ ],
  "keepFilters": true
}
```
- Cada objeto em `fields` segue `PoDynamicFormField`/`PoPageDynamicTableFilters` (ex.: `property`, `label`, `type`, `key`, `disabled`, `visible`, `options`, `labels`, `gridColumns`).
- `actions` segue a interface de ações do template correspondente (`PoPageDynamicTableActions`, `PoPageDynamicEditActions` etc.).
- `version` controla o **cache** de metadata: o browser envia a versão cacheada; se o servidor não responder, o cache é reutilizado.
- Endpoint padrão quando `serviceMetadataApi` não é informado: `GET {end-point}/metadata?type={list|edit}&version={version}`.

> Nota de fonte: `PoPageDynamicTableFilters` historicamente **não** tipava a propriedade `labels` (Issue #1038), embora `labels` funcione em runtime — atenção ao compilar em TS strict; valide contra a versão instalada.

---

## Recommendations
1. **Adote os `po-page-dynamic-*`** para as telas CRUD padrão do THL (cadastro/consulta). Só recorra a `po-page-list` + `po-table` (ou `po-page-edit` + `po-dynamic-form`) quando houver layout/regra fora do padrão que a metadata não expresse bem. *Benchmark para mudar de abordagem:* se você precisar de mais de ~2 templates de célula customizados ou lógica de negócio pesada no cliente, migre para a versão estática.
2. **Padronize o back-end PASOE no contrato PO-UI:** `page`/`pageSize`/`order` na entrada e `{ items, hasNext }` na saída; `DELETE /:id` e `DELETE ?ids=`; metadata versionada em `GET /metadata?type=...&version=...`. Isso maximiza o reuso dos dynamics sem código adicional.
3. **Use `p-auto-router`** com rotas contendo `serviceApi`/`serviceMetadataApi`/`serviceLoadApi` para acelerar o scaffolding das 4 páginas (list/detail/edit/new) compartilhando a mesma metadata.
4. **Para a IA de codificação:** trate como *fonte de verdade* as regras `type → componente` (seção 6.1) e o contrato de resposta `{ items, hasNext }` (seção 4.1). Gere sempre `key: true` no campo identificador e `visible: false` quando ele não deve aparecer.
5. **Fixe a versão** de `@po-ui/ng-components` e `@po-ui/ng-templates` no `package.json` e valide os defaults sinalizados como "não confirmados" contra o `node_modules` local antes de gerar código em massa.

## Caveats
- **Limitação de fonte:** GitHub bloqueia fetch automatizado e po-ui.io é uma SPA (retorna "Carregando..."). Tipos e defaults foram confirmados por *snippets* do source e do CHANGELOG; itens não confirmáveis estão sinalizados no texto (ex.: literal `dateTime`, corpo completo de `PoDynamicFormField`, propriedades do `po-tree-view`).
- **`pageSize` default** aparece no source como a constante `PAGE_SIZE_DEFAULT` (valor literal não exposto no snippet; a convenção documentada da API PO-UI é `10`) — confirme no build instalado.
- **Deprecações por acessibilidade** (`p-hide-text-overflow`, opção `'shadow'`/`p-no-shadow`) mudam de comportamento entre majors; a lista de propriedades acima reflete o `master` atual e pode divergir da versão que você tem instalada.
- `po-list-view` exige `BrowserAnimationsModule`; esquecer esse import é uma causa comum de o componente não animar/renderizar corretamente.
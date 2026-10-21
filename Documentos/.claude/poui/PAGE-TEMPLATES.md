---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
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

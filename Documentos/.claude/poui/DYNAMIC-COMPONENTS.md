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

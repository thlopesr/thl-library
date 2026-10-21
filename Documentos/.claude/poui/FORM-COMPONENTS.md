---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# FORM-COMPONENTS.md

> **Observação metodológica:** as propriedades abaixo foram extraídas do código-fonte oficial (`po-ui/po-angular`, arquivos `*-base.component.ts`) e da documentação `po-ui.io`. Onde o valor default não pôde ser confirmado, isso está indicado. Todos os componentes de campo aceitam `[(ngModel)]` (template-driven) ou binding reativo via `formControlName`, além das propriedades comuns `p-label`, `p-help`, `p-disabled`, `p-required`, `p-optional`, e emitem o evento `p-change`.

## Convenções gerais dos campos
Propriedades comuns confirmadas em `po-input-base.component.ts` (e reutilizadas por vários campos):

| Propriedade | Tipo | Default | Descrição |
|---|---|---|---|
| `p-label` | `string` | — | Rótulo do campo. |
| `p-help` | `string` | — | Texto de ajuda abaixo do campo. |
| `p-placeholder` | `string` | — | Texto de placeholder. |
| `p-required` | `boolean` | `false` | Campo obrigatório. |
| `p-optional` | `boolean` | `false` | Marca o campo como opcional. |
| `p-disabled` | `boolean` | `false` | Desabilita o campo. |
| `p-readonly` | `boolean` | `false` | Somente leitura. |
| `p-clean` | `boolean` | `false` | Exibe botão para limpar o campo. |
| `p-maxlength` / `p-minlength` | `number` | — | Limites de caracteres. |
| `p-error-pattern` | `string` | — | Mensagem de erro para `p-pattern`. |
| `p-required-field-error-message` | `boolean` | `false` | Exibe mensagem quando vazio e requerido (requer `p-required`). |
| `p-upper-case` | `boolean` | `false` | Converte o conteúdo em maiúsculas automaticamente. |

Eventos comuns: `p-change` (dispara ao alterar/sair), `p-blur`, `p-enter`, `p-keydown`.

### `po-input` — texto simples
Seletor: `<po-input>`. Texto genérico com suporte a máscara.
Propriedades específicas confirmadas (doc + `po-input-base.component.ts`): `p-mask: string` (máscara customizada), `p-mask-format-model: boolean` (se o model recebe o valor com máscara), `p-mask-no-length-validation: boolean`, `p-pattern: string`, `p-icon: string`, `p-loading: boolean`, `p-no-autocomplete: boolean`, `p-size: string`, `p-show-required: boolean`.

```html
<po-input name="nome" [(ngModel)]="nome" p-label="Nome" p-required p-clean></po-input>
```
```typescript
export class MinhaTela { nome = ''; }
```
**Pegadinha:** `p-mask-format-model` define se a máscara é gravada no model — importante ao enviar para a API (o back-end Datasul geralmente espera o valor **sem** formatação).
Doc: https://po-ui.io/documentation/po-input

### `po-number` — números inteiros
Seletor: `<po-number>`. Aceita apenas dígitos inteiros. Propriedades típicas: `p-min`, `p-max`, `p-step`, `p-clean`.
```html
<po-number name="idade" [(ngModel)]="idade" p-label="Idade" p-clean></po-number>
```
Doc: https://po-ui.io/documentation/po-number

### `po-decimal` — números decimais
Seletor: `<po-decimal>`. Trata separador de milhar e decimal. Propriedades confirmadas em `po-decimal.component.ts`:

| Propriedade | Tipo | Default | Descrição |
|---|---|---|---|
| `p-decimals-length` | `number` | `2` | Casas decimais (máximo 14; a soma com `p-thousand-maxlength` limita-se a 16). |
| `p-thousand-maxlength` | `number` | — | Máximo de dígitos antes do separador decimal (máximo 13). |
| `p-locale` | `string` | — | Define separadores (`pt` → vírgula decimal e ponto de milhar). |

```html
<po-decimal name="valor" [(ngModel)]="valor" p-label="Valor"
            [p-decimals-length]="2" p-locale="pt"></po-decimal>
```
Doc: https://po-ui.io/documentation/po-decimal

### `po-textarea` — texto multilinha
Seletor: `<po-textarea>`. Propriedades: `p-rows: number`, `p-maxlength`, além das comuns.
```html
<po-textarea name="obs" [(ngModel)]="obs" p-label="Observações" [p-rows]="4"></po-textarea>
```
Doc: https://po-ui.io/documentation/po-textarea

### `po-rich-text` — editor rich text
Seletor: `<po-rich-text>`. Editor de texto formatado (negrito, itálico, listas, links). Emite `p-change` com o HTML resultante.
```html
<po-rich-text name="descricao" [(ngModel)]="descricao" p-label="Descrição"></po-rich-text>
```
Doc: https://po-ui.io/documentation/po-rich-text

### `po-password` — senha
Seletor: `<po-password>`. Campo mascarado; propriedades semelhantes ao `po-input` (`p-required`, `p-pattern`, `p-error-pattern`, `p-clean`).
Doc: https://po-ui.io/documentation/po-password

### `po-email` — e-mail com validação embutida
Seletor: `<po-email>`. Valida formato de e-mail automaticamente.
```html
<po-email name="email" [(ngModel)]="email" p-label="E-mail" p-clean></po-email>
```
Doc: https://po-ui.io/documentation/po-email

### `po-url` — URL com validação embutida
Seletor: `<po-url>`. Valida formato de URL automaticamente.
```html
<po-url name="site" [(ngModel)]="site" p-label="Website" p-clean></po-url>
```
Doc: https://po-ui.io/documentation/po-url

### `po-input-mask`
Máscara customizada é feita via a propriedade **`p-mask` do próprio `po-input`** (não há um seletor `<po-input-mask>` separado na biblioteca atual). Exemplos de máscara (`9` = dígito numérico):
- CPF: `p-mask="999.999.999-99"`
- CNPJ: `p-mask="99.999.999/9999-99"`
- Telefone: `p-mask="(99) 99999-9999"`
- CEP: `p-mask="99999-999"`
```html
<po-input name="cpf" [(ngModel)]="cpf" p-label="CPF" p-mask="999.999.999-99"
          [p-mask-format-model]="true"></po-input>
```
**Pegadinha:** `9` representa dígito numérico na máscara do PO-UI. Confirmar os demais coringas na doc antes de assumir.
Doc: https://po-ui.io/documentation/po-input

## Componentes de seleção

### `po-select` — dropdown simples
Seletor: `<po-select>`. Opções fixas via `p-options: Array<PoSelectOption>` (`{ label, value }`). **Não** permite digitação/busca.
```html
<po-select name="uf" [(ngModel)]="uf" p-label="UF" [p-options]="ufs"></po-select>
```
```typescript
import { PoSelectOption } from '@po-ui/ng-components';
ufs: Array<PoSelectOption> = [{ label: 'SP', value: 'SP' }, { label: 'RJ', value: 'RJ' }];
```
Doc: https://po-ui.io/documentation/po-select

### `po-combo` — combo com busca (opções fixas ou API)
Seletor: `<po-combo>`. Permite digitação para filtrar. Opções via `p-options` (fixas) ou `p-filter-service` (dinâmicas). Ver seção dedicada abaixo.
```html
<po-combo name="cor" [(ngModel)]="cor" p-label="Cor" [p-options]="cores" p-clean></po-combo>
```
Doc: https://po-ui.io/documentation/po-combo

### `po-multiselect` — seleção múltipla
Seletor: `<po-multiselect>`. Propriedades confirmadas na doc: `p-options`, `p-filter-service`, `p-field-label`, `p-field-value`, `p-filter-mode`, `p-hide-search: boolean`, `p-hide-select-all: boolean`, `p-sort: boolean`, `p-auto-height`, `p-placeholder-search`, `p-listbox-control-position`. Emite `p-change`. O model é um **array**.
```html
<po-multiselect name="perfis" [(ngModel)]="perfis" p-label="Perfis"
                [p-options]="opcoes"></po-multiselect>
```
**Dica (da doc):** para < 5 itens, considere `po-checkbox-group`; para seleção única, use `po-select`/`po-radio-group`.
Doc: https://po-ui.io/documentation/po-multiselect

### `po-lookup` — busca com modal/zoom
Seletor: `<po-lookup>`. **Fundamental para ERP.** Ver seção dedicada abaixo.
Doc: https://po-ui.io/documentation/po-lookup

### `po-checkbox` — checkbox individual
Seletor: `<po-checkbox>`. Booleano único; `p-label`.
```html
<po-checkbox name="aceite" [(ngModel)]="aceite" p-label="Aceito os termos"></po-checkbox>
```
Doc: https://po-ui.io/documentation/po-checkbox

### `po-checkbox-group` — grupo de checkboxes
Seletor: `<po-checkbox-group>`. Opções via `p-options: Array<PoCheckboxGroupOption>` (`{ label, value }`); model é um array. `p-columns: number` distribui em colunas.
```html
<po-checkbox-group name="itens" [(ngModel)]="itens" p-label="Itens"
                   [p-options]="opcoes" [p-columns]="4"></po-checkbox-group>
```
```typescript
import { PoCheckboxGroupOption } from '@po-ui/ng-components';
opcoes: Array<PoCheckboxGroupOption> = [
  { value: '1', label: 'Opção 1' }, { value: '2', label: 'Opção 2' }, { value: '3', label: 'Opção 3' }
];
```
Doc: https://po-ui.io/documentation/po-checkbox-group

### `po-radio-group` — grupo de radio buttons
Seletor: `<po-radio-group>`. Seleção única. Opções via `p-options: Array<PoRadioGroupOption>`. `p-columns: number`. Verbatim da doc: *"deve ser utilizado para disponibilizar múltiplas opções ao usuário, permitindo a ele que selecione apenas uma delas. Seu uso é recomendado para um número pequeno de opções, caso contrário, recomenda-se o uso do po-combo ou po-select"*. **Pegadinha (doc):** *"Ao passar um valor para o model que não esteja na lista de opções, o mesmo será definido como undefined."*
```html
<po-radio-group name="sexo" [(ngModel)]="sexo" p-label="Sexo"
                [p-options]="opcoes" [p-columns]="2"></po-radio-group>
```
Doc: https://po-ui.io/documentation/po-radio-group

### `po-switch` — toggle liga/desliga
Seletor: `<po-switch>`. Booleano. `p-label-on` / `p-label-off` (textos exibidos em cada estado). Em versões recentes há propriedades para validação de erros.
```html
<po-switch name="ativo" [(ngModel)]="ativo" p-label="Ativo"
           p-label-on="Sim" p-label-off="Não"></po-switch>
```
Doc: https://po-ui.io/documentation/po-switch

## Componentes de data/hora

### `po-datepicker` — seleção de data
Seletor: `<po-datepicker>`. Propriedades: `p-format` (ex.: `dd/mm/yyyy`), `p-min-date`, `p-max-date`, `p-locale`, `p-clean`.
**Pegadinha confirmada (issue #1725):** quando o formato é ISO8601 estendido, o componente historicamente acrescentava **1 segundo** ao valor no `ngModel` (relacionado ao `hour: 'T00:00:01-00:00'` no base component). Validar na versão em uso.
```html
<po-datepicker name="nascimento" [(ngModel)]="nascimento" p-label="Nascimento"
               p-format="dd/mm/yyyy" p-clean></po-datepicker>
```
Doc: https://po-ui.io/documentation/po-datepicker

### `po-datepicker-range` — intervalo de datas
Seletor: `<po-datepicker-range>`. Propriedades confirmadas na doc: `p-start-date`, `p-end-date`, `p-min-date`, `p-max-date`, `p-locale`, `p-field-error-message`, `p-clean`, `p-error-limit`. **Importante (verbatim da doc):** *"Permite trabalhar com as duas datas separadamente através das propriedades p-start-date e p-end-date no lugar do [(ngModel)], no entanto sem a validação do formulário; Para a validação do formulário, utilize o [(ngModel)]."*
```html
<po-datepicker-range name="periodo" [(ngModel)]="periodo" p-label="Período"></po-datepicker-range>
```
Doc: https://po-ui.io/documentation/po-datepicker-range

## Componentes de arquivo

### `po-upload` — upload de arquivos
Seletor: `<po-upload>`. Propriedades: `p-url: string` (endpoint que recebe os arquivos), `p-restrictions` (com `allowedExtensions`, `maxFileSize`), `p-auto-upload: boolean`, `p-multiple`, `p-hide-send-button: boolean`, `p-drag-drop: boolean`, `p-disabled-remove-file`.
```html
<po-upload name="anexos" [(ngModel)]="anexos" p-label="Anexos"
           p-url="/api/thl/v1/uploads"></po-upload>
```
**Pegadinha (issue #593):** o componente faz a requisição diretamente para `p-url`; em HTTPS/cross-origin é preciso configurar CORS no back-end (PASOE), senão ocorre erro `Access-Control-Allow-Origin`. A partir de versões recentes, o evento de upload inclui a `url`.
Doc: https://po-ui.io/documentation/po-upload

## Componentes de exibição em formulário

### `po-info` — exibição somente leitura (label + valor)
Seletor: `<po-info>`. Exibe `p-label` + `p-value` (read-only). Suporta `p-url` para renderizar como link.
```html
<po-info p-label="Data" [p-value]="data | date:'dd/MM/yyyy'"></po-info>
```
No Datasul, é comum combinar com o pipe `dtsDateFormat` da `dts-backoffice-util`: `[p-value]="date | dtsDateFormat:'dd/MM/yyyy'"`.
Doc: https://po-ui.io/documentation/po-info

### `po-tag` — etiquetas/tags coloridas
Seletor: `<po-tag>`. Propriedades: `p-value`, `p-color` (tokens `color-01`…`color-12` ou nomes de cor), `p-type` (status: `success`/`warning`/`danger`/`info`/`neutral`), `p-icon`.
```html
<po-tag p-value="Ativo" p-type="success"></po-tag>
```
Doc: https://po-ui.io/documentation/po-tag

### `po-divider` — divisor/separador visual com título
Seletor: `<po-divider>`. Separador horizontal com título opcional (`p-label`).
```html
<po-divider p-label="Dados de Contato"></po-divider>
```
Doc: https://po-ui.io/documentation/po-divider

### `po-avatar` — avatar/imagem de perfil
Seletor: `<po-avatar>`. `p-src`, `p-size` (`xs`…`xl`).
```html
<po-avatar p-src="assets/user.png" p-size="lg"></po-avatar>
```
Doc: https://po-ui.io/documentation/po-avatar

### `po-image` — imagem
Seletor: `<po-image>`. `p-src`, `p-alt`.
Doc: https://po-ui.io/documentation/po-image

### `po-widget` — card/widget
Seletor: `<po-widget>`. Container tipo card. Propriedades: `p-title`, `p-help`, `p-primary-label`, `p-no-shadow`.
```html
<po-widget p-title="Resumo"> ...conteúdo... </po-widget>
```
Doc: https://po-ui.io/documentation/po-widget

## po-lookup em detalhe (crítico para ERP)

O `po-lookup` é o "zoom" clássico de ERP: um campo com botão que abre um **modal de busca em tabela**, permitindo pesquisar registros de uma API e selecionar um (ou vários).

**Propriedades principais (confirmadas em `po-lookup.component.ts` e `po-lookup-modal-base.component.ts`):**

| Propriedade | Tipo | Default | Descrição |
|---|---|---|---|
| `p-field-label` | `string` | — | Propriedade do objeto exibida como descrição no campo. |
| `p-field-value` | `string` | — | Propriedade que é o valor efetivo (gravado no model). |
| `p-columns` | `Array<PoLookupColumn>` | — | Colunas da tabela do modal. |
| `p-filter-service` | `PoLookupFilter \| string` | — | Serviço (ou URL padrão API TOTVS) que retorna os dados. |
| `p-filter-params` | `any` | — | Parâmetros extras enviados ao serviço. |
| `p-advanced-filters` | `Array<PoLookupAdvancedFilter>` | — | Filtros avançados no modal. |
| `p-hide-columns-manager` | `boolean` | `false` | Esconde o gerenciador de colunas. |
| `p-multiple` | `boolean` | `false` | Habilita seleção múltipla. |
| `p-field-format` | `Function` | — | Função para formatar o valor exibido. |

Evento: `p-change` (na seleção). Método: `focus()` via `@ViewChild(PoLookupComponent)`.

**Interface `PoLookupColumn`:** `{ property: string; label?: string; type?: string; width?: string; ... }`.

**Interface/serviço `PoLookupFilter`:** classe que implementa os métodos que retornam `Observable` (para itens filtrados e para recuperar objeto pelo valor). Alternativamente, informar uma URL no padrão API TOTVS.

**Exemplo completo funcional:**
```html
<po-lookup name="cliente" [(ngModel)]="clienteCodigo"
           p-label="Cliente"
           p-field-label="nome"
           p-field-value="codigo"
           [p-columns]="colunasLookup"
           [p-filter-service]="clienteService"
           (p-change)="onSelect($event)">
</po-lookup>
```
```typescript
import { Component, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  PoLookupColumn, PoLookupFilter, PoLookupFilteredItemsParams
} from '@po-ui/ng-components';

@Injectable({ providedIn: 'root' })
export class ClienteLookupService implements PoLookupFilter {
  private url = '/api/thl/v1/clientes';
  constructor(private http: HttpClient) {}

  getFilteredItems(params: PoLookupFilteredItemsParams): Observable<any> {
    return this.http.get(this.url, {
      params: {
        filter: params.filter ?? '',
        page: `${params.page ?? 1}`,
        pageSize: `${params.pageSize ?? 10}`
      }
    });
  }

  getObjectByValue(value: string): Observable<any> {
    return this.http.get(`${this.url}/${value}`).pipe(map((r: any) => r));
  }
}

@Component({ selector: 'app-cliente-form', templateUrl: './cliente-form.component.html' })
export class ClienteFormComponent {
  clienteCodigo!: string;
  colunasLookup: Array<PoLookupColumn> = [
    { property: 'codigo', label: 'Código', width: '20%' },
    { property: 'nome', label: 'Nome', width: '80%' }
  ];
  constructor(public clienteService: ClienteLookupService) {}
  onSelect(evento: any): void { /* item selecionado */ }
}
```
**Seleção múltipla:** adicionar `[p-multiple]="true"` — o model passa a ser um array.
**Filtros:** `p-advanced-filters` adiciona campos de filtro no modal; a URL recebe os parâmetros (exemplo da própria doc do código: `http://localhost:3000/v1/heroes?filter=&page=1&pageSize=10&name=Tony%20Stark,Peter%20Parker`).
Doc: https://po-ui.io/documentation/po-lookup

## po-combo com carga dinâmica (seção dedicada)

**Como carregar de API:** informar em `p-filter-service` a **URL** do serviço (padrão API TOTVS) **ou** um serviço que implemente a interface `PoComboFilter`. Verbatim do código-fonte: *"Nesta propriedade deve ser informada a URL do serviço em que será realizado o filtro para carregamento da lista... Caso haja a necessidade de customização, então pode ser informado um serviço implementando a interface PoComboFilter."*

**Propriedades relevantes (confirmadas em `po-combo-base.component.ts`):**

| Propriedade | Tipo | Descrição |
|---|---|---|
| `p-filter-service` | `PoComboFilter \| string` | Serviço ou URL para carga dinâmica. |
| `p-filter-mode` | `startsWith` \| `endsWith` \| `contains` | Como o filtro compara o texto digitado. |
| `p-debounce-time` | `number` | Atraso (ms) antes de disparar a busca ao digitar. |
| `p-field-label` / `p-field-value` | `string` | Mapeiam as propriedades do objeto retornado. |
| `p-options` | `Array<PoComboOption>` | Opções fixas (alternativa ao serviço). |
| `p-clean` / `p-required` | `boolean` | Limpar / obrigatório. |

Evento: `p-change`.

**Comportamentos confirmados (código-fonte):** o `po-combo` guarda o último valor caso o usuário desista da busca (saindo do campo ou pressionando `Esc`); se o usuário digitar a descrição completa de um item, a seleção é feita automaticamente ao sair ou pressionar `Enter`. Se usar URL, o serviço deve responder no padrão API TOTVS.

**Exemplo completo funcional:**
```html
<po-combo name="produto" [(ngModel)]="produtoId"
          p-label="Produto"
          [p-filter-service]="produtoComboService"
          p-field-label="descricao"
          p-field-value="id"
          p-filter-mode="contains"
          [p-debounce-time]="400">
</po-combo>
```
```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { PoComboFilter, PoComboOption } from '@po-ui/ng-components';

@Injectable({ providedIn: 'root' })
export class ProdutoComboService implements PoComboFilter {
  private url = '/api/thl/v1/produtos';
  constructor(private http: HttpClient) {}

  getFilteredData(params: { property: string; value: string }): Observable<Array<PoComboOption>> {
    return this.http.get(this.url, { params: { search: params.value } })
      .pipe(map((res: any) => res.items.map((p: any) => ({ label: p.descricao, value: p.id }))));
  }

  getObjectByValue(value: string): Observable<PoComboOption> {
    return this.http.get(`${this.url}/${value}`)
      .pipe(map((p: any) => ({ label: p.descricao, value: p.id })));
  }
}
```
**Pegadinha confirmada (issue #1183):** ao usar `PoComboFilter`, quando o `value` é `0` (zero) o componente pode tratar como `undefined` — cuidado com códigos numéricos que começam/valem zero.
Doc: https://po-ui.io/documentation/po-combo

## Formulários reativos vs template-driven

- **Template-driven (`[(ngModel)]`)** — importar `FormsModule`. É a abordagem mostrada na maioria dos exemplos oficiais do PO-UI. Requer o atributo `name` em cada campo dentro de um `<form>`. Simples e direta para telas de cadastro.
- **Reactive forms (`FormGroup`/`FormControl`)** — importar `ReactiveFormsModule` (nativo do Angular). Use `formControlName` nos componentes PO-UI. Melhor para validações complexas, formulários dinâmicos e testes.

> **Qual o PO-UI recomenda:** a documentação oficial de campos afirma apenas que *"Não esqueça de importar o módulo FormsModule para usar os componentes de formulários e caso esteja trabalhando com formulários reativos, importe o módulo ReactiveFormsModule"* — ou seja, o PO-UI **suporta as duas abordagens** e não declara explicitamente uma preferência. A escolha fica a critério do projeto. **Recomendação para o THL:** para telas de ERP com muitas validações condicionais e dependências entre campos (comum em cadastros Datasul), prefira **reactive forms**; para telas simples de consulta/edição rápida, template-driven é mais ágil.

**Validação — verificar se o form está válido:**
- Template-driven: adicionar `#form="ngForm"` no `<form>` e checar `form.valid`.
- Reactive: `this.meuForm.valid` / `this.meuForm.get('campo')?.errors`.

**Acessar valores programaticamente:**
- Template-driven: a própria variável ligada ao `[(ngModel)]`.
- Reactive: `this.meuForm.value` ou `this.meuForm.get('campo')?.value`.

**Exemplo reactive:**
```typescript
import { FormBuilder, Validators } from '@angular/forms';
// ...
this.form = this.fb.group({
  codigo: ['', Validators.required],
  nome: ['', [Validators.required, Validators.maxLength(60)]]
});
```
```html
<form [formGroup]="form">
  <div class="po-row">
    <po-input class="po-md-4" formControlName="codigo" p-label="Código"></po-input>
    <po-input class="po-md-8" formControlName="nome" p-label="Nome"></po-input>
  </div>
  <po-button p-label="Salvar" p-kind="primary" [p-disabled]="form.invalid"
             (p-click)="salvar()"></po-button>
</form>
```

---

## Recommendations
1. **Fixe as versões** no `package.json` conforme a tabela (PO-UI 21.x ↔ Angular ~21.2.4 ↔ Node 20.11+ ↔ TS ~5.9.3). Só suba de major com `ng update` e faça teste visual — o AnimaliaDS muda a aparência dos componentes entre majors. *Benchmark:* se o projeto THL ainda estiver em Angular ≤ 18, priorize a migração de versão antes de escrever telas novas.
2. **Confirme os breakpoints e classes de espaçamento default** abrindo o CSS compilado `@po-ui/style/css/po-theme-core.min.css` (ou o repo `po-ui/po-style`) **antes** de gerar telas — não assuma valores de Bootstrap/Material. Registre os px reais no knowledge base para as próximas rodadas.
3. **Padronize o `po-lookup`** como componente de zoom para todas as chaves estrangeiras do módulo THL, com um `PoLookupFilter` por entidade apontando para as APIs REST do PASOE via **caminho relativo** (`/api/thl/...`) + proxy.
4. **Use um `SharedModule`** reexportando `PoModule`/`PoTemplatesModule`/`FormsModule`/`ReactiveFormsModule`, com lazy loading por feature (`loadChildren`).
5. **Envie ao back-end valores sem máscara** — controle `p-mask-format-model` conscientemente e trate o comportamento de `value = 0` no `po-combo` e o "+1 segundo" ISO8601 do `po-datepicker`.
6. **Avalie a `dts-backoffice-util`** (integração de menu/perfil Datasul) e, se precisar de grids editáveis avançados, a `dts-backoffice-kendo-grid` — ambas são bibliotecas da comunidade ModernizaDatasul.

## Caveats
- **Não confirmado em fonte oficial nesta rodada:** os valores **default em pixels dos breakpoints** do grid e o **intervalo/mapeamento das classes de espaçamento (`po-mt-*`, `po-p-*`) e offset (`po-offset-*`)**. As páginas `po-ui.io/guides/*` são renderizadas via JavaScript e não retornam conteúdo por HTTP simples; a fonte definitiva é o CSS compilado do `@po-ui/style` ou o repositório `po-ui/po-style`.
- Vários **defaults de propriedades individuais** (ex.: `p-size`, `p-format`, `p-debounce-time`) não foram exaustivamente confirmados componente a componente; onde não indicado, tratar como "verificar na doc oficial do componente".
- A documentação oficial e os exemplos assumem **majoritariamente `NgModule`** (o próprio getting-started condiciona a configuração do `PoTemplatesModule` a apps "configuradas com módulos"); o suporte a **standalone components** deve ser verificado por componente antes de assumir.
- `dts-backoffice-util` e `dts-backoffice-kendo-grid` são bibliotecas da **comunidade (ModernizaDatasul)**, não do core oficial PO-UI/TOTVS.
- O pacote de ícones do Animalia publicado no NPM é **`@animaliads/ani-icon`** (o CHANGELOG do PO-UI refere-se genericamente à "lib do Animalia"); confirme o nome exato do pacote na versão do PO-UI em uso.
- Fontes de terceiros (Medium, Scribd) foram usadas apenas como corroboração de exemplos; sempre que possível o conteúdo foi ancorado no repositório oficial `po-ui/po-angular`, no NPM e na doc `po-ui.io`.
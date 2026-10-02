# LAYOUT.md

## 2.1 Grid system (12 colunas)

O PO-UI usa um grid de **12 colunas** com classes de largura por breakpoint, aplicadas diretamente no atributo `class` dos componentes (confirmado nos exemplos oficiais e no `STYLEGUIDE.md` do repo, ex.: `class="po-sm-12"`, `class="po-md-6"`, `class="po-md-3"`):

- `po-sm-*` — telas pequenas (small)
- `po-md-*` — telas médias (medium)
- `po-lg-*` — telas grandes (large)
- `po-xl-*` — telas extra grandes (extra large)

Onde `*` é um inteiro de **1 a 12** (número de colunas ocupadas). Exemplo: `class="po-md-6"` ocupa metade da largura em telas médias.

**Breakpoints (px):** o PO-UI expõe os breakpoints como **tokens customizáveis** via `PoMediaQueryService` (tipo `PoMediaQueryTokens`), com os nomes `gridSystemSmMaxWidth`, `gridSystemMdMinWidth`, `gridSystemMdMaxWidth`, `gridSystemLgMinWidth`, `gridSystemLgMaxWidth` e `gridSystemXlMinWidth`. Exemplo de **customização** extraído da doc oficial (estes números **NÃO** são os defaults — são valores de exemplo aplicados via serviço):
```typescript
import { PoMediaQueryService, PoMediaQueryTokens } from '@po-ui/ng-components';

const tokens: PoMediaQueryTokens = {
  sm: { gridSystemSmMaxWidth: '1024px' },                                   // até 1024px
  md: { gridSystemMdMinWidth: '1025px', gridSystemMdMaxWidth: '1366px' },   // 1025–1366px
  lg: { gridSystemLgMinWidth: '1367px', gridSystemLgMaxWidth: '1465px' },   // 1367–1465px
  xl: { gridSystemXlMinWidth: '1466px' }                                    // a partir de 1466px
};
this.poMediaQueryService.setValues(tokens);
```

> **⚠️ Não confirmado em fonte oficial:** os valores **default em pixels** de cada breakpoint (`sm`/`md`/`lg`/`xl`) não puderam ser confirmados a partir da documentação/CSS oficiais nesta rodada. A página `po-ui.io/guides/grid-system` é renderizada via JavaScript e não retorna conteúdo por HTTP simples. A fonte definitiva é o **CSS compilado** `@po-ui/style/css/po-theme-core.min.css` (procurar regras `@media` e classes `po-sm`/`po-md`/`po-lg`/`po-xl`) ou o SCSS no repositório `po-ui/po-style`. **Verifique diretamente antes de fixar os números** — os valores 1024/1366/1465/1466 px acima são apenas valores de *customização* mostrados na doc, e não os padrões da biblioteca.

**Como combinar classes para responsividade:** aplique múltiplas classes no mesmo elemento para larguras diferentes por breakpoint. Ex.: `class="po-sm-12 po-md-6 po-lg-4"` → 100% em telas pequenas, 50% em médias, ~33% em grandes.

**Layouts comuns:**
- **Formulário 2 colunas:** cada campo `class="po-md-6"`.
- **Formulário 3 colunas:** cada campo `class="po-md-4"`.
- **Formulário misto:** ex. `po-md-8` (campo grande, como "Nome") + `po-md-4` (campo pequeno, como "Código") na mesma linha.

## 2.2 Containers e utilitários

- **`po-container`**: componente (`<po-container>`) que agrupa conteúdo — verbatim da doc: *"O po-container é um componente que visa facilitar o agrupamento de conteúdos. Por padrão o mesmo exibe uma borda, um efeito de sombra ao seu redor e um espaçamento"*. Use para agrupar blocos visuais.
- **`po-row`**: classe (`class="po-row"`) que envolve as colunas, funcionando como a linha do grid (flex). As colunas (`po-md-*` etc.) devem ficar dentro de um elemento com `po-row` — confirmado em exemplos oficiais (`<div class="po-row"> ... </div>`).
- **`po-widget`**: componente `<po-widget>` que renderiza um card/painel, muito usado como container de formulários e tabelas.

**Classes de offset e espaçamento:** o PO-UI oferece classes utilitárias de offset (deslocamento de colunas) e de espaçamento de margem/padding (`po-mt-*`, `po-mb-*`, `po-ml-*`, `po-mr-*`, `po-p-*`, etc.).

> **⚠️ Não confirmado em fonte oficial:** o intervalo numérico exato (de 0 até quanto) e o mapeamento em rem/px das classes de espaçamento (`po-mt-*`, `po-p-*`) e das classes de offset (`po-offset-*`) não puderam ser confirmados nesta rodada a partir de fonte oficial. Verificar no CSS compilado `@po-ui/style` ou no guia de grid. **Não confundir com as classes do Bootstrap/Material** (que apareceram nas buscas mas não se aplicam ao PO-UI).

## 2.3 Exemplos visuais de layout

**Layout de formulário de cadastro padrão ERP (header + body em colunas + footer com botões):**
```html
<po-page-default p-title="Cadastro de Cliente" [p-actions]="actions">
  <po-widget>
    <form #form="ngForm">
      <div class="po-row">
        <po-input class="po-md-4" name="codigo" [(ngModel)]="cliente.codigo"
                  p-label="Código" p-required></po-input>
        <po-input class="po-md-8" name="nome" [(ngModel)]="cliente.nome"
                  p-label="Nome" p-required></po-input>
      </div>

      <po-divider p-label="Contato"></po-divider>

      <div class="po-row">
        <po-email class="po-md-6" name="email" [(ngModel)]="cliente.email"
                  p-label="E-mail"></po-email>
        <po-input class="po-md-6" name="telefone" [(ngModel)]="cliente.telefone"
                  p-label="Telefone" p-mask="(99) 99999-9999"></po-input>
      </div>
    </form>
  </po-widget>
</po-page-default>
```
```typescript
import { Component } from '@angular/core';
import { PoPageAction } from '@po-ui/ng-components';

@Component({ selector: 'app-cliente-form', templateUrl: './cliente-form.component.html' })
export class ClienteFormComponent {
  cliente = { codigo: '', nome: '', email: '', telefone: '' };
  actions: Array<PoPageAction> = [
    { label: 'Salvar', action: this.salvar.bind(this) },
    { label: 'Cancelar', action: this.cancelar.bind(this) }
  ];
  salvar(): void { /* POST /api/thl/... */ }
  cancelar(): void { /* voltar */ }
}
```
O `p-actions: Array<PoPageAction>` define os botões (topo/rodapé) do `po-page-default`.

**Layout de tela de consulta padrão ERP (filtros + tabela + paginação):**
```html
<po-page-default p-title="Consulta de Clientes">
  <po-widget>
    <div class="po-row">
      <po-input class="po-md-6" name="filtroNome" [(ngModel)]="filtroNome"
                p-label="Nome"></po-input>
      <po-button class="po-md-2" p-label="Pesquisar" p-kind="primary"
                 (p-click)="pesquisar()"></po-button>
    </div>

    <po-divider></po-divider>

    <po-table [p-columns]="colunas" [p-items]="itens"
              [p-loading]="carregando"
              [p-sort]="true" [p-striped]="true"
              [p-show-more-disabled]="semMais"
              (p-show-more)="carregarMais()"></po-table>
  </po-widget>
</po-page-default>
```
```typescript
import { PoTableColumn } from '@po-ui/ng-components';
colunas: Array<PoTableColumn> = [
  { property: 'codigo', label: 'Código', width: '15%' },
  { property: 'nome', label: 'Nome' },
  { property: 'situacao', label: 'Situação', type: 'label',
    labels: [
      { value: 'A', label: 'Ativo', color: 'color-11' },
      { value: 'I', label: 'Inativo', color: 'color-07' }
    ] }
];
```

---

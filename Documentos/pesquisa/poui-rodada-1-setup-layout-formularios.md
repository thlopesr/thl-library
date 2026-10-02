# Pesquisa PO-UI — Rodada 1/4: Setup, Layout e Componentes de Formulário

## TL;DR
- A versão estável mais recente do PO-UI é a **21.3.0** (`@po-ui/ng-components`, conforme o registro NPM: *"PO UI - Components. Latest version: 21.3.0"*), alinhada ao Angular **~21.2.4**, Node.js **20.11.x ou superior**, TypeScript **~5.9.3**; a instalação é feita com `ng add @po-ui/ng-components`, que configura tema, styles, `PoModule` e `HttpClient` automaticamente.
- O sistema de layout usa grid de **12 colunas** com as classes `po-sm-*`, `po-md-*`, `po-lg-*`, `po-xl-*` dentro de `po-row`/`po-container`/`po-widget`, com breakpoints customizáveis via `PoMediaQueryService`.
- Os componentes de formulário funcionam tanto com template-driven (`[(ngModel)]` + `FormsModule`) quanto reactive forms (`formControlName` + `ReactiveFormsModule`); para telas de ERP THL o `po-lookup` (zoom com modal + API REST) e o `po-combo` com `p-filter-service` são os mais críticos.

## Key Findings
- **Versão:** `@po-ui/ng-components` 21.3.0 (NPM). O PO-UI segue o ciclo major do Angular (PO-UI 21 ↔ Angular 21).
- **Pré-requisitos oficiais** (`getting-started.md`, repo `po-ui/po-angular`): Node.js 20.11.x+, Angular CLI 21 (`npm i -g @angular/cli@21`), dependências `@angular/core ~21.2.4` … `typescript ~5.9.3`.
- **Tema TOTVS:** `@totvs/po-theme` + `@po-ui/style`; o design system subjacente é o **AnimaliaDS** — *"o design system open source da TOTVS"*.
- **`po-lookup`:** colunas via `p-columns: Array<PoLookupColumn>`, serviço via `p-filter-service: PoLookupFilter`, filtros avançados via `p-advanced-filters`.
- **`po-combo`:** carga dinâmica via `p-filter-service` (URL padrão API TOTVS ou serviço implementando `PoComboFilter`).
- **Lacuna assumida:** os valores default **em pixels** dos breakpoints do grid e o intervalo/mapeamento exato das classes de espaçamento/offset não puderam ser confirmados em fonte oficial nesta rodada (as páginas `po-ui.io/guides` são renderizadas via JavaScript). Estão sinalizados como não confirmados.

---

# SETUP.md

## 1.1 Versões e compatibilidade

A versão estável mais recente do PO-UI é a **21.3.0** (`@po-ui/ng-components`), conforme o registro NPM: *"PO UI - Components. Latest version: 21.3.0, last published: 4 days ago"*. O PO-UI acompanha o ciclo de releases major do Angular — cada major do PO-UI corresponde ao major do Angular equivalente (ex.: PO-UI 21 ↔ Angular 21).

| Item | Versão recomendada (verificada em fonte oficial) |
|---|---|
| `@po-ui/ng-components` | 21.3.0 |
| Angular (`@angular/core`, `common`, `forms`, `router`…) | ~21.2.4 |
| Node.js | 20.11.x ou superior |
| TypeScript | ~5.9.3 |
| RxJS | ~7.8.1 |
| zone.js | ~0.15.0 |
| tslib | ^2.6.2 |
| `@angular/cli` | ~21.2.4 (instalar global com `@angular/cli@21`) |

> **Fonte:** bloco de dependências e pré-requisitos de `docs/guides/getting-started.md` no repositório oficial `po-ui/po-angular` (verbatim: *"Para começar a utilizar o PO UI é pré-requisito ter o Node.js instalado (versão 20.11.x ou acima)"* e `"@angular/core": "~21.2.4" ... "typescript": "~5.9.3"`) e a página NPM de `@po-ui/ng-components`.

**Angular suportado:** o PO-UI mantém compatibilidade com a versão major correspondente. O getting-started atual instala o CLI com `npm i -g @angular/cli@21` (verbatim da seção Pré-requisitos). Versões anteriores do PO-UI (v5 a v20) suportam os Angulars correspondentes; a migração entre majors é assistida por `ng update`.

**Pegadinha (Angular 19+/21+):** o projeto pode usar o novo build system `@angular/build`. Se aparecer o erro `Could not find the @angular/build:dev-server builder's package`, instale `npm install -D @angular/build` e confirme no `angular.json` que o builder é `@angular/build:application` / `@angular/build:dev-server`. Se o builder ainda for `@angular-devkit/build-angular`, mantém-se o modelo tradicional.

## 1.2 Criação de projeto

```bash
# 1. Instalar o Angular CLI compatível
npm i -g @angular/cli@21

# 2. Criar o projeto (sem instalar dependências de imediato)
ng new my-po-project --skip-install

# 3. Entrar na pasta e instalar
cd my-po-project
npm install

# 4. Adicionar o PO-UI (configura tema, styles, PoModule e HttpClient)
ng add @po-ui/ng-components

# 5. (Opcional) Adicionar os templates (po-page-login, po-page-dynamic-table, etc.)
ng add @po-ui/ng-templates

# 6. Rodar
ng serve   # acesse http://localhost:4200
```

**O que o `ng add @po-ui/ng-components` configura automaticamente** (verbatim do getting-started: *"o mesmo se encarregará de configurar o tema, instalar o pacote e importar o módulo do Po. Além de importar também o modulo HttpClientModule"*):
- Instala o pacote `@po-ui/ng-components`;
- Importa o `PoModule` no módulo raiz (ou configura provedores em apps standalone);
- Configura o tema/styles no `angular.json`;
- Importa o `HttpClientModule` (ou `provideHttpClient`);
- Pergunta se deseja incluir uma estrutura inicial com menu lateral, toolbar e página (responder `Y` para incluir).

`ng add @po-ui/ng-templates` instala `@po-ui/ng-templates` e configura o `PoTemplatesModule` no `app.module` — verbatim: *"configurado o PoTemplatesModules no app.module somente se sua aplicação for configurada com módulos"*.

**Estrutura de pastas recomendada para projeto Datasul** (prática de comunidade / padrão dts-backoffice):
```
src/app/
  core/            # serviços singleton, interceptors, guards
  shared/          # SharedModule (reexporta PoModule, PoTemplatesModule, FormsModule)
  <modulo-thl>/
    pages/
      <entidade>-list/     # tela de consulta (filtros + tabela)
      <entidade>-detail/   # tela de cadastro (form)
    services/              # serviços REST que apontam para o PASOE
    models/                # interfaces TypeScript
  app.module.ts
proxy.conf.js
```

## 1.3 Pacotes NPM do ecossistema

| Pacote | Descrição | Quando usar |
|---|---|---|
| `@po-ui/ng-components` | Biblioteca principal de componentes de UI (inputs, tabela, grid, page, toolbar, menu, etc.). Versão atual **21.3.0**. | Sempre — é o núcleo do PO-UI. |
| `@po-ui/ng-templates` | Componentes de alto nível/"templates": `po-page-login`, `po-page-dynamic-table`, `po-page-dynamic-edit`, `po-page-blocked-user`, `po-modal-password-recovery`, etc. | Quando quiser telas prontas (CRUD dinâmico, login, recuperação de senha). |
| `@po-ui/ng-code-editor` | Componente de editor de código (baseado no Monaco Editor). | Telas que editam código/scripts/JSON. |
| `@po-ui/ng-schematics` | Schematics (geradores) do PO-UI usados por `ng add`/`ng generate`. | Scaffolding de componentes/páginas via CLI. |
| `@po-ui/ng-storage` | Serviço de armazenamento local — verbatim NPM: *"fornece um serviço para armazenamento de dados no dispositivo local, sendo semelhante ao funcionamento do IonicStorage"*, com drivers WebSQL, IndexedDB, LocalStorage e LokiJS. | Persistência offline no dispositivo. |
| `@po-ui/ng-sync` | Sincronização de dados offline/online baseada em schemas (versão atual ~19.26.0). | Apps mobile/offline-first (Ionic + PO). |
| `@po-ui/style` | CSS base do PO-UI (grid, tokens, `po-theme-core`, `po-theme-default`). Versão atual ~21.30.0; código-fonte no repositório `po-ui/po-style`. | Sempre presente (instalado pelo tema). |
| `@totvs/po-theme` | Tema visual TOTVS (cores, fontes) aplicado sobre o `@po-ui/style`. | Projetos TOTVS/Datasul que devem seguir o visual corporativo. |
| `dts-backoffice-util` | Biblioteca da comunidade **ModernizaDatasul** — verbatim: *"Biblioteca que engloba diversos componentes e serviços utilizados no desenvolvimento HTML/Angular com PO-UI"*. Inclui `MenuDatasulService` (integração com o menu do Datasul), `ProfileService` (preferências de usuário), pipe `dtsDateFormat`, e utilitários de agendamento RPW. | Projetos Datasul — integração com menu, perfil de usuário, agendamento de jobs. |

## 1.4 Configuração do tema

**Instalação do tema TOTVS:**
```bash
npm i --save @totvs/po-theme
```

**`angular.json` — propriedade `styles` (ordem recomendada, tema TOTVS):**
```json
"styles": [
  "node_modules/@totvs/po-theme/css/po-theme-default-variables.min.css",
  "node_modules/@totvs/po-theme/css/po-theme-default.min.css",
  "node_modules/@po-ui/style/css/po-theme-core.min.css",
  "src/styles.css"
]
```

Se usar apenas o tema padrão do PO-UI (sem TOTVS):
```json
"styles": [
  "node_modules/@po-ui/style/css/po-theme-default.min.css"
]
```

**Customização de cores e fontes:** o PO-UI permite personalizar o tema via **tokens CSS** (variáveis CSS) — sobrescrevendo variáveis (ex.: cor primária) nos seus próprios estilos, ou gerando um tema customizado a partir do guia oficial de criação de tema. Componentes expõem tokens específicos (ex.: no `po-radio-group` a customização ocorre nos elementos `po-radio` que compõem o grupo).

**AnimaliaDS:** é o **design system open source da TOTVS** que passou a fundamentar o PO-UI nas versões recentes. Diversos componentes tiveram suas definições visuais reimplementadas segundo o AnimaliaDS (o CHANGELOG registra, por exemplo, *"accordion: implementa definições do AnimaliaDS"* e *"breadcrumb: implementa definições do AnimaliaDS"*), e os ícones migraram para a lib de ícones do Animalia — o pacote publicado é o **`@animaliads/ani-icon`** (MIT); o prefixo de ícone mudou de `ph` para `an`. Na prática, o AnimaliaDS afeta espaçamentos, tipografia, ícones e tokens de tema — telas antigas podem mudar de aparência ao atualizar de major.

## 1.5 Módulos Angular do PO-UI

**`PoModule`** (`@po-ui/ng-components`): agrega os módulos de todos os componentes principais (campos de formulário, tabela, page, toolbar, menu, etc.). Importe-o uma vez no módulo raiz ou em um `SharedModule`.

**`PoTemplatesModule`** (`@po-ui/ng-templates`): agrega os componentes de template (páginas dinâmicas, login, etc.).

**Módulo de campos:** o `PoFieldModule` (incluído no `PoModule`) contém, conforme a doc oficial: `po-checkbox`, `po-checkbox-group`, `po-combo`, `po-datepicker`, `po-datepicker-range`, `po-email`, `po-input`, `po-lookup`, `po-number`, `po-multiselect`, `po-password`, `po-radio-group`, `po-select`, `po-switch`, `po-textarea`, `po-upload` e `po-url`. **É obrigatório importar o `FormsModule`** (e o `ReactiveFormsModule` se usar formulários reativos), ambos nativos do Angular.

**Exemplo completo `app.module.ts` (baseado em módulos):**
```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { PoModule } from '@po-ui/ng-components';
import { PoTemplatesModule } from '@po-ui/ng-templates';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    FormsModule,
    ReactiveFormsModule,
    HttpClientModule,
    PoModule,
    PoTemplatesModule,
    AppRoutingModule
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}
```

**SharedModule recomendado** (reexporta o PO-UI para todos os módulos de feature — padrão do workshop oficial `crud-po-ui-workshop`):
```typescript
@NgModule({
  imports: [CommonModule, FormsModule, ReactiveFormsModule, PoModule, PoTemplatesModule],
  exports: [CommonModule, FormsModule, ReactiveFormsModule, PoModule, PoTemplatesModule]
})
export class SharedModule {}
```

**Lazy loading:** configure rotas com `loadChildren` apontando para módulos de feature que importam o `SharedModule` (padrão do workshop oficial):
```typescript
const routes: Routes = [
  { path: 'clientes', loadChildren: () => import('./clientes/clientes.module').then(m => m.ClientesModule) },
  { path: '', redirectTo: '/clientes', pathMatch: 'full' }
];
```
Em projetos standalone (Angular moderno), use `loadComponent`/`loadChildren` com `provideHttpClient()` no `bootstrapApplication`. **Observação:** grande parte da documentação e dos exemplos oficiais do PO-UI ainda assume `NgModule` (o próprio getting-started ressalva que o `PoTemplatesModule` é configurado *"somente se sua aplicação for configurada com módulos"*); verificar caso a caso o suporte standalone antes de assumir.

## 1.6 Proxy para desenvolvimento local (Datasul / PASOE)

O proxy do Angular CLI evita erros de CORS em desenvolvimento, redirecionando chamadas do `localhost:4200` para o servidor **PASOE** (Progress Application Server for OpenEdge) onde as APIs REST do Datasul estão publicadas.

**`proxy.conf.js` apontando para o PASOE:**
```javascript
const PROXY_CONFIG = [
  {
    context: [
      '/api',          // APIs REST do Datasul (ex.: /api/thl/v1/...)
      '/dts',
      '/totvs-menu'
    ],
    target: 'http://servidor-datasul:8180', // host:porta do PASOE
    secure: false,
    changeOrigin: true,
    logLevel: 'debug'
  }
];

module.exports = PROXY_CONFIG;
```

**`angular.json` — registrar o proxy no target `serve`:**
```json
"serve": {
  "builder": "@angular/build:dev-server",
  "options": {
    "proxyConfig": "proxy.conf.js"
  }
}
```
(Em projetos que ainda usam o builder clássico, o `builder` será `@angular-devkit/build-angular:dev-server` e a opção `proxyConfig` fica no mesmo lugar.) Rode com `ng serve` — o CLI lê automaticamente o `proxyConfig`.

**Pegadinha:** os serviços Angular devem chamar **caminhos relativos** (`/api/thl/...`) e **não** a URL absoluta do PASOE, senão o proxy não intercepta. Em builds de produção o proxy não é usado — o roteamento fica a cargo do servidor que hospeda a aplicação. Use `proxy.conf.js` (JS) quando precisar de lógica (variáveis de ambiente, múltiplos gateways); `proxy.conf.json` (JSON) basta para casos simples.

---

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
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

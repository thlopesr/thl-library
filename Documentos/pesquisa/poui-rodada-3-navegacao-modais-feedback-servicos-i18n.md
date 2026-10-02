# Knowledge Base PO-UI — Rodada 3/4: Navegação, Modais, Feedback, Serviços e i18n

## TL;DR
- Este documento consolida, a partir do código-fonte oficial (po-ui/po-angular — arquivos `*-base.component.ts`/`*.interface.ts`) e do repositório ModernizaDatasul/dts-backoffice-util (README/CHANGELOG + NPM), as APIs de navegação (po-menu, po-toolbar, po-breadcrumb, po-tabs, po-stepper, po-accordion, rotas), modais/diálogos (po-modal, PoDialogService, disclaimers, po-page-slide, po-popup), feedback/UX (notification, loading, progress, tooltip, popover, button, dropdown), serviços utilitários Datasul e internacionalização.
- Fontes de verdade priorizadas: código-fonte do po-ui e README/CHANGELOG do dts-backoffice-util (versão mais recente **19.3.0**, publicada há cerca de um mês conforme registro no NPM). Onde a assinatura exata não pôde ser confirmada na fonte oficial, isso está **sinalizado explicitamente** como "a confirmar".
- O interceptor PO (`PoHttpInterceptorModule`) exibe mensagens automáticas com base no payload TOTVS e nos headers `X-PO-No-Message`/`X-PO-No-Error`; combine-o com `PoNotificationService`/`PoDialogService` seguindo os padrões de UX da Seção 9.9.

## Key Findings
- **PoMenuItem** — documentação oficial: "O componente po-menu recebe uma lista de objetos do tipo MenuItem com as informações dos itens de menu como textos, links para redirecionamento, ações, **até 4 níveis de menu e ícones para o primeiro nível de menu**."
- **PoModalAction** (verbatim do fonte): `action: Function`, `label: string`, `danger?: boolean`, `disabled?: boolean`, `loading?: boolean`.
- **Interceptor**: constantes internas `X-PO-No-Error` (não mostra erros 4xx/5xx) e `X-PO-No-Message` (não exibe notificações de erro e/ou sucesso); payload TOTVS suporta `detailTitle` (confirmado no CHANGELOG do po-angular).
- **Ícones**: o PO-UI migrou para a biblioteca **Animalia** — o CHANGELOG oficial registra "Substitui o prefixo 'ph' por 'an' seguindo as definições da atualização da lib @animaliads/animalia-icon" (prefixo `an an-*`).
- **dts-backoffice-util** expõe MenuDatasulService, ReportService, ProfileService, TranslateService, FileUtil, DisclaimerUtil, GenericFunctionsUtils, UserLoginService, BreadcrumbControlService, TotvsScheduleExecutionComponent/Service e o pipe dtsDateFormat.

---

# SEÇÃO 7 — NAVEGAÇÃO E ROTAS (ROUTING.md)

## 7.1 Padrão de rotas Angular para CRUD PO-UI

**Explicação técnica.** Convenção recomendada (prática de comunidade, alinhada aos templates `PoPageDynamic*` do PO), consistente com o `PoPageDynamicTableActions` do workshop oficial (`detail: 'people/view/:id'`, `edit: 'people/edit/:id'`, `new: 'people/new'`, `remove: true`):

- `/recurso` → listagem
- `/recurso/new` → criação
- `/recurso/edit/:id` → edição
- `/recurso/detail/:id` → visualização

**Exemplo completo — `app-routing.module.ts` com lazy loading:**

```typescript
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  { path: '', redirectTo: 'clientes', pathMatch: 'full' },
  {
    path: 'clientes',
    loadChildren: () => import('./clientes/clientes.module').then(m => m.ClientesModule),
    canActivate: [AuthGuard]
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
```

**Rotas do feature module:**

```typescript
const routes: Routes = [
  { path: '', component: ClienteListComponent },
  { path: 'new', component: ClienteFormComponent },
  { path: 'edit/:id', component: ClienteFormComponent },
  { path: 'detail/:id', component: ClienteDetailComponent }
];
```

**ActivatedRoute (ler `:id`) e Router (navegar):**

```typescript
constructor(private route: ActivatedRoute, private router: Router) {}

ngOnInit() {
  const id = this.route.snapshot.paramMap.get('id');
  // ou reativo: this.route.paramMap.subscribe(p => this.id = p.get('id'));
}

irParaEdicao(id: string) {
  this.router.navigate(['/clientes/edit', id]);
}
```

**Lazy loading — quando usar:** feature modules grandes ou raramente acessados, para reduzir o bundle inicial. **Route guards:** `CanActivate` para proteger rotas (autenticação/permissão); `CanDeactivate` para confirmar saída de formulário com alterações não salvas (ver 9.9).

**Pegadinhas.** Em Angular 17/18 com `app.routes.ts` standalone, não há `app-routing.module.ts`; use `provideRouter(routes)`. O `po-menu` destaca automaticamente o item ativo com base na URL — não é necessário controle manual.

📚 https://po-ui.io/documentation

## 7.2 po-menu — menu lateral

**Explicação técnica.** Recebe `[p-menus]` (Array<PoMenuItem>). Documentação oficial: suporta "até 4 níveis de menu e ícones para o primeiro nível de menu"; "Aparece completo em telas com largura maior que 1200px, caso contrário o menu é escondido e chamado por meio de um botão." Segundo o `po-menu-base.component.ts`, "O menu será colapsado/expandido apenas se todos os itens de menu tiverem valor nas propriedades `icon` e `shortLabel`."

**Propriedades principais:** `p-menus`, `p-filter`, `p-logo`, `p-short-logo`, `p-collapsed`, `p-service` (URL de serviço para filtro de itens).

**Interface PoMenuItem:**

```typescript
interface PoMenuItem {
  label: string;               // obrigatório; não pode ser vazio
  action?: string | Function;  // ação ao clicar
  badge?: PoMenuItemBadge;      // badge numérico { value, color? }
  icon?: string;               // ícone (apenas 1º nível é exibido)
  link?: string;               // rota interna ou URL externa
  shortLabel?: string;         // rótulo curto (modo colapsado)
  subItems?: Array<PoMenuItem>; // sub-menus (até 4 níveis)
}
```

**Exemplo completo:**

```typescript
import { Component } from '@angular/core';
import { PoMenuItem } from '@po-ui/ng-components';

@Component({ selector: 'app-root', templateUrl: './app.component.html' })
export class AppComponent {
  readonly menus: Array<PoMenuItem> = [
    { label: 'Home', link: '/home', icon: 'an an-house', shortLabel: 'Home' },
    { label: 'Cadastros', icon: 'an an-folder', shortLabel: 'Cad', subItems: [
      { label: 'Clientes', link: '/clientes' },
      { label: 'Produtos', link: '/produtos' }
    ]},
    { label: 'Sair', action: this.logout.bind(this), icon: 'an an-sign-out', shortLabel: 'Sair' }
  ];
  logout() { /* ... */ }
}
```

```html
<div class="po-wrapper">
  <po-toolbar p-title="THL"></po-toolbar>
  <po-menu [p-menus]="menus" p-filter></po-menu>
  <router-outlet></router-outlet>
</div>
```

**Pegadinhas.** Para colapsar, TODOS os itens de 1º nível precisam de `icon` **e** `shortLabel`. A lib de ícones atual é Animalia (`an an-*`); ícones legados (`po-icon po-icon-*`) e Font Awesome ainda são aceitos. Confira ícones disponíveis em https://po-ui.io/icons.

📚 https://po-ui.io/documentation/po-menu

## 7.3 po-toolbar — barra superior

**Propriedades:** `p-title`, `p-actions` (Array<PoToolbarAction>), `p-actions-icon`, `p-profile` (PoToolbarProfile), `p-profile-actions`, `p-notification-actions`, `p-notification-number`.

**Interfaces** *(a confirmar campos exatos em `po-toolbar-action.interface.ts` e `po-toolbar-profile.interface.ts`)*:
- `PoToolbarAction`: `label`, `action`, `icon`, `disabled?`, `link?`, `type?`.
- `PoToolbarProfile`: `title`, `subtitle?`, `avatar?` (URL da imagem).

**Exemplo completo:**

```html
<po-toolbar
  p-title="Cadastro de Clientes"
  [p-actions]="actions"
  [p-profile]="profile"
  [p-profile-actions]="profileActions"
  [p-notification-number]="3">
</po-toolbar>
```

```typescript
profile = { title: 'João Silva', subtitle: 'Administrador', avatar: '/assets/avatar.png' };
actions = [{ label: 'Ajuda', icon: 'an an-question', action: this.ajuda.bind(this) }];
profileActions = [{ label: 'Sair', icon: 'an an-sign-out', action: this.logout.bind(this) }];
```

**Pegadinha.** Muitas notificações não geram scroll na lista antiga (Issue #377, tratada em release posterior).

📚 https://po-ui.io/documentation/po-toolbar

## 7.4 po-breadcrumb

**Propriedades:** `p-items` (Array<PoBreadcrumbItem>), `p-favorite-service`, `p-params-service`.

**Interface PoBreadcrumbItem:** `label: string`, `link?: string`, `action?: Function`.

**Exemplo:**

```html
<po-breadcrumb [p-items]="[
  { label: 'Home', link: '/' },
  { label: 'Clientes', link: '/clientes' },
  { label: 'Editar' }
]"></po-breadcrumb>
```

**Breadcrumb dinâmico.** O último item representa a página atual e não recebe link. Monte o array no `ngOnInit` a partir da rota atual, ou utilize o `BreadcrumbControlService` do dts-backoffice-util (Seção 10.2) para criar/remover itens de forma centralizada.

📚 https://po-ui.io/documentation/po-breadcrumb

## 7.5 po-tabs

**Explicação técnica.** `po-tabs` agrupa `po-tab`. Propriedades de `po-tab`: `p-label`, `p-active`, `p-disabled`, `p-hide`, e o evento `(p-click)`.

**Exemplo (formulário organizado em abas):**

```html
<po-tabs>
  <po-tab p-label="Dados Gerais" [p-active]="true">
    <!-- campos gerais -->
  </po-tab>
  <po-tab p-label="Endereço">
    <!-- campos de endereço -->
  </po-tab>
  <po-tab p-label="Contatos" (p-click)="carregarContatos()">
    <!-- carregado lazy ao clicar -->
  </po-tab>
</po-tabs>
```

**Carregamento lazy por aba:** use `(p-click)` para disparar a carga de dados apenas quando a aba é aberta.

📚 https://po-ui.io/documentation/po-tabs

## 7.6 po-stepper — wizard

**Explicação técnica.** Duas abordagens: (1) `po-stepper` com `po-step` (envolve o conteúdo de cada passo); (2) `p-steps` com Array<PoStepperItem> + controle manual de troca. Com `po-step` o fluxo é **sequencial**: não é possível pular para um step desabilitado; o primeiro `po-step` fica ativo, o próximo em `default` e os demais desabilitados.

**Propriedades:** `p-steps`, `p-step` (passo ativo), `p-sequential`, `p-orientation`. **Validação por etapa:** propriedade `p-can-active-next-step` no `po-step` (boolean ou função). **Eventos:** `(p-active-step)`, `(p-next-step)`.

**Exemplo (cadastro em etapas):**

```html
<po-stepper>
  <po-step p-label="Dados" [p-can-active-next-step]="validarDados">
    <!-- conteúdo -->
  </po-step>
  <po-step p-label="Endereço" [p-can-active-next-step]="validarEndereco">
    <!-- conteúdo -->
  </po-step>
  <po-step p-label="Confirmação">
    <!-- conteúdo -->
  </po-step>
</po-stepper>
```

**Pegadinha.** A Issue oficial #2342 documenta que "O comportamento da propriedade `p-can-active-next-step` dificulta a validação do passo" — teste bem a lógica de validação antes/depois da troca de step.

📚 https://po-ui.io/documentation/po-stepper

## 7.7 po-accordion

**Explicação técnica.** `po-accordion` com `po-accordion-item`. Propriedades de `po-accordion-item`: `p-label`, `p-expand`.

```html
<po-accordion>
  <po-accordion-item p-label="Dados Pessoais" [p-expand]="true">
    <!-- campos -->
  </po-accordion-item>
  <po-accordion-item p-label="Endereço">
    <!-- campos -->
  </po-accordion-item>
</po-accordion>
```

📚 https://po-ui.io/documentation/po-accordion

---

# SEÇÃO 8 — MODAIS E DIÁLOGOS (MODALS.md)

## 8.1 po-modal

**Propriedades:** `p-title`, `p-size` (`sm`, `md`, `lg`, `xl`, `auto`), `p-hide-close`, `p-click-out`, `p-primary-action`, `p-secondary-action`. Conforme o `po-modal-base.component.ts`: "Quando informado `auto` a modal calculará automaticamente seu tamanho baseado em seu conteúdo. Caso não seja informado um valor, a modal terá o tamanho definido como `md`." "É possível fechar a modal através da tecla ESC, quando a propriedade `p-hide-close` não estiver habilitada."

**Interface PoModalAction (verbatim do fonte):**

```typescript
export interface PoModalAction {
  action: Function;    // função executada ao clicar
  label: string;       // rótulo do botão
  danger?: boolean;    // aplica o tipo "danger" (se em ambos, só o primário recebe)
  disabled?: boolean;  // desabilita o botão
  loading?: boolean;   // exibe estado de carregamento e desabilita
}
```

**Abrir/fechar via @ViewChild:**

```typescript
import { Component, ViewChild } from '@angular/core';
import { PoModalComponent, PoModalAction } from '@po-ui/ng-components';

@Component({ /* ... */ })
export class CadastroRapidoComponent {
  @ViewChild(PoModalComponent, { static: true }) modal: PoModalComponent;

  primaryAction: PoModalAction = { label: 'Salvar', action: () => this.salvar() };
  secondaryAction: PoModalAction = { label: 'Cancelar', action: () => this.modal.close() };

  abrir() { this.modal.open(); }
  salvar() { /* ... */ this.modal.close(); }
}
```

```html
<po-modal #modal p-title="Cadastro Rápido" p-size="md"
  [p-primary-action]="primaryAction"
  [p-secondary-action]="secondaryAction">
  <form>
    <po-input name="nome" p-label="Nome" [(ngModel)]="cliente.nome"></po-input>
  </form>
</po-modal>
```

**Modal de busca avançada:** dentro do `<po-modal>`, combine `po-input`/`po-datepicker-range` (filtros) com uma `po-table` de resultados; use `PoModalAction` para "Pesquisar"/"Fechar". Passe dados setando propriedades do componente antes de `open()`.

**Pegadinha.** O fechamento por ESC/"X" não emite evento próprio (Issue #1217); se precisar reagir ao cancelamento, use `p-hide-close` e trate o cancelamento por botão.

📚 https://po-ui.io/documentation/po-modal

## 8.2 po-dialog (PoDialogService)

**Explicação técnica.** Serviço injetável (`inject(PoDialogService)` ou construtor). `alert()` = alerta simples; `confirm()` = confirmação Sim/Não.

```typescript
import { Component, inject } from '@angular/core';
import { PoDialogService } from '@po-ui/ng-components';

export class ClienteListComponent {
  private poDialog = inject(PoDialogService);

  confirmarExclusao(id: string) {
    this.poDialog.confirm({
      title: 'Confirmar exclusão',
      message: 'Deseja realmente excluir o registro?',
      confirm: () => this.excluir(id),
      cancel: () => { /* opcional */ }
    });
  }

  alertaConcluido() {
    this.poDialog.alert({
      title: 'Sucesso',
      message: 'Operação concluída.',
      ok: () => { /* opcional */ }
    });
  }
}
```

**Interfaces (campos principais):**
- `PoDialogAlertOptions`: `title`, `message`, `ok?` (callback).
- `PoDialogConfirmOptions`: `title`, `message`, `confirm` (callback), `cancel?` (callback).

📚 https://po-ui.io/documentation/po-dialog

## 8.3 po-disclaimer / po-disclaimer-group

**Interfaces:**
- `PoDisclaimer`: `value: string`, `label?: string`, `property?: string`, `hideClose?: boolean`.
- `PoDisclaimerGroup`: `disclaimers: Array<PoDisclaimer>`, `title?: string`, `hideRemoveAll?: boolean`.

**Eventos do `po-disclaimer-group`:** `(p-change)`, `(p-remove)`, `(p-remove-all)`.

**Padrão completo (filtro avançado → disclaimer → recarrega tabela):**

```html
<po-disclaimer-group
  [p-disclaimers]="disclaimers"
  [p-title]="'Filtros aplicados'"
  (p-change)="onFilterChange($event)"
  (p-remove)="onRemove($event)"
  (p-remove-all)="onRemoveAll()">
</po-disclaimer-group>

<po-table [p-items]="items" [p-columns]="columns"></po-table>
```

```typescript
onFilterChange(disclaimers: PoDisclaimer[]) {
  this.disclaimers = disclaimers;
  this.recarregarTabela(disclaimers);
}
```

Para sincronizar automaticamente filtros ↔ disclaimers, use o `DisclaimerUtil` do dts-backoffice-util (Seção 10.2).

📚 https://po-ui.io/documentation/po-disclaimer-group

## 8.4 po-page-slide — painel lateral

**Propriedades:** `p-title`, `p-subtitle`, `p-size`, `p-hide-close`, `p-click-out`, `p-hide-secondary-actions`.

**Abrir/fechar via @ViewChild (`open()`/`close()`):**

```typescript
import { ViewChild } from '@angular/core';
import { PoPageSlideComponent } from '@po-ui/ng-components';

@ViewChild(PoPageSlideComponent, { static: true }) pageSlide: PoPageSlideComponent;

verDetalhe(item: ICliente) {
  this.itemSelecionado = item;
  this.pageSlide.open();
}
```

```html
<po-page-slide #slide p-title="Detalhe do Registro" p-size="md">
  <po-info p-label="Nome" [p-value]="itemSelecionado?.nome"></po-info>
</po-page-slide>
```

**Uso típico:** exibir o detalhe de um registro sem sair da listagem (mantém contexto da tabela).

📚 https://po-ui.io/documentation/po-page-slide

## 8.5 po-popup — menu contextual

**Interface PoPopupAction:** `label`, `action?`, `icon?`, `visible?`, `disabled?`, `separator?`, `selected?`, `type?`, `url?`.

```html
<po-button p-label="Ações" (p-click)="popup.toggle($event)"></po-button>
<po-popup #popup [p-actions]="acoes"></po-popup>
```

```typescript
acoes = [
  { label: 'Editar', icon: 'an an-pencil-simple', action: this.editar.bind(this) },
  { label: 'Excluir', icon: 'an an-trash', action: this.excluir.bind(this) }
];
```

📚 https://po-ui.io/documentation/po-popup

---

# SEÇÃO 9 — FEEDBACK E UX (FEEDBACK-UX.md)

## 9.1 po-notification (PoNotificationService)

**Métodos:** `success()`, `error()`, `warning()`, `information()`.

**Interface PoNotification:** `message`, `duration`, `action`, `actionLabel`, `orientation`, `type`.

**Comportamento (do `po-notification.service.ts`):** notificações do tipo **Error** e aquelas com `action`+`actionLabel` **não** somem automaticamente; as demais são destruídas após `duration`. Orientação via enum `PoToasterOrientation` (`Top`/`Bottom`); tipo via `PoToasterType` (`Success`, `Error`, `Warning`, `Information`).

```typescript
private poNotification = inject(PoNotificationService);

this.poNotification.success('Registro salvo com sucesso!');
this.poNotification.warning('Verifique os campos obrigatórios.');
this.poNotification.error('Erro ao salvar o registro.');
this.poNotification.information('Processamento em andamento.');

// Com ação e orientação:
this.poNotification.success({
  message: 'Registro salvo.',
  duration: 5000,
  orientation: PoToasterOrientation.Bottom,
  actionLabel: 'Desfazer',
  action: () => this.desfazer()
});
```

📚 https://po-ui.io/documentation/po-notification

## 9.2 po-loading-overlay

**Propriedades:** `p-screen-lock`, `p-text`.

```html
<po-loading-overlay *ngIf="carregando" [p-screen-lock]="true" p-text="Carregando..."></po-loading-overlay>
```

**Loading automático via interceptor.** O `po-http-request-interceptor` cria um `PoLoadingOverlayComponent` com `screenLock = true` quando a requisição envia o header `X-PO-Screen-Lock: true`. Requer `provideHttpClient(withInterceptorsFromDi())` e importação do `PoModule`/`PoHttpInterceptorModule`.

📚 https://po-ui.io/documentation/po-loading-overlay

## 9.3 po-loading

Loading inline dentro de componentes. Propriedade `p-text`.

```html
<po-loading p-text="Aguarde"></po-loading>
```

## 9.4 po-progress

**Propriedades:** `p-value` (0–100), `p-info`, `p-status`, `p-text`, `p-size`, `p-indeterminate`.

```html
<po-progress [p-value]="percentual" [p-info]="percentual + '%'" p-status="success"></po-progress>
```

**Exemplo (upload com progresso):** atualize `p-value` conforme o evento `HttpEventType.UploadProgress` do HttpClient.

## 9.5 po-tooltip

Diretiva `p-tooltip` com `p-tooltip-position` (`top`, `right`, `bottom`, `left`). Aplicável a qualquer elemento.

```html
<po-button p-icon="an an-trash" p-tooltip="Excluir" p-tooltip-position="bottom"></po-button>
<span p-tooltip="Informação adicional">ⓘ</span>
```

## 9.6 po-popover

**Diferença tooltip × popover:** o tooltip exibe apenas um texto curto no hover; o popover exibe conteúdo rico e título, com trigger configurável (hover/click).

**Propriedades:** `p-title`, `p-trigger`, `p-position`, `p-target` (ElementRef | HTMLElement), `p-hide-arrow`, `p-append-in-body`, `p-custom-classes`, `(p-open)`, `(p-close)`.

```html
<po-button p-label="Abrir Popover" #btn></po-button>
<po-popover [p-target]="btn" p-title="Informação" p-trigger="click">
  Conteúdo rico do popover
</po-popover>
```

```typescript
@ViewChild(PoButtonComponent, { read: ElementRef, static: true }) btn: PoButtonComponent;
```

📚 https://po-ui.io/documentation/po-popover

## 9.7 po-button / po-button-group

**Propriedades po-button:** `p-label`, `p-icon` (string | TemplateRef), `p-disabled`, `p-loading`, `p-kind`, `p-type` (PoButtonType — comportamento em formulário HTML), `p-danger`, `p-size`, `p-aria-label`, `(p-click)`.

`p-kind` define o estilo (`primary`, `secondary`, `tertiary`); o estilo *danger* é obtido com `p-danger="true"`.

**Exemplo (toolbar de ações Salvar/Cancelar/Excluir):**

```html
<po-button p-label="Salvar" p-kind="primary" p-icon="an an-check" (p-click)="salvar()"></po-button>
<po-button p-label="Cancelar" p-kind="secondary" (p-click)="cancelar()"></po-button>
<po-button p-label="Excluir" p-kind="tertiary" [p-danger]="true" p-icon="an an-trash" (p-click)="excluir()"></po-button>
```

`po-button-group` agrupa botões via `[p-buttons]`.

📚 https://po-ui.io/documentation/po-button

## 9.8 po-dropdown

Menu dropdown de ações. **Interface PoDropdownAction:** `label`, `action?`, `icon?`, `visible?`, `disabled?`, `selected?`, `type?`.

```html
<po-dropdown [p-actions]="acoes" p-label="Mais ações"></po-dropdown>
```

```typescript
acoes = [
  { label: 'Exportar CSV', action: this.exportar.bind(this) },
  { label: 'Imprimir', action: this.imprimir.bind(this) }
];
```

📚 https://po-ui.io/documentation/po-dropdown

## 9.9 Padrões de UX para ERP

- **notification vs dialog** — notification para feedback **não-bloqueante** (salvou, erro pós-operação); dialog para decisões **bloqueantes** que exigem resposta do usuário (confirmar exclusão).
- **loading-overlay vs loading inline** — overlay com `p-screen-lock` para operações que bloqueiam a tela inteira; inline para carregamento de um componente/área específica.
- **Após salvar** → `PoNotificationService.success()`.
- **Erro de validação (regra de negócio/campos)** → `warning()`.
- **Erro de servidor (5xx/indisponível)** → `error()` (ou automático via interceptor).
- **Ação destrutiva** → `PoDialogService.confirm()` antes de executar.
- **Sair de formulário com alterações não salvas** → guard `CanDeactivate` + `confirm()`:

```typescript
canDeactivate(): boolean | Observable<boolean> {
  if (!this.form.dirty) return true;
  return new Observable(observer => {
    this.poDialog.confirm({
      title: 'Alterações não salvas',
      message: 'Deseja sair sem salvar?',
      confirm: () => { observer.next(true); observer.complete(); },
      cancel: () => { observer.next(false); observer.complete(); }
    });
  });
}
```

---

# SEÇÃO 10 — SERVIÇOS E UTILITÁRIOS (SERVICES.md)

## 10.1 Serviços nativos do PO-UI

- **PoNotificationService** — ver 9.1.
- **PoDialogService** — ver 8.2.
- **PoI18nService** — ver Seção 13.
- **PoHttpInterceptorModule / po-http-interceptor** — "tem a finalidade de exibir notificações com mensagens na tela, baseado nas respostas das requisições HTTP". Constantes internas: `X-PO-No-Error` (não mostra notificações de erro `4xx`/`5xx`) e `X-PO-No-Message` (não exibe notificações de erro e/ou sucesso). Requer `BrowserAnimationsModule`/`provideAnimations()`.

**Configuração (standalone):**

```typescript
import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { PoHttpInterceptorModule } from '@po-ui/ng-components';

export const appConfig: ApplicationConfig = {
  providers: [
    provideAnimations(),
    provideHttpClient(withInterceptorsFromDi()),
    importProvidersFrom([PoHttpInterceptorModule])
  ]
};
```

**Payload de mensagem TOTVS:** `code`, `message`, `detailedMessage`, `type` (`error`/`warning`/`information` — default `error`), `details` (lista recursiva) e `detailTitle` (título dos detalhes; o CHANGELOG do po-angular registra "interceptor: adiciona a propriedade detailTitle para permitir definir o titulo da mensagem retornada"). Se houver apenas uma mensagem de retorno, o interceptor "exibe a mensagem principal na modal". Loading automático é ativado por `X-PO-Screen-Lock: true` no header da requisição.

📚 https://po-ui.io/documentation/po-http-interceptor

## 10.2 Serviços do dts-backoffice-util (Datasul)

**Módulo Angular:** `DtsBackofficeUtilsModule` (alguns componentes exigem `.forRoot()`). Descrição oficial: "Biblioteca que engloba diversos componentes e serviços utilizados no desenvolvimento HTML/Angular com PO-UI." Versão mais recente: **19.3.0** (NPM). Os nomes das versões acompanham PO-UI/Angular (ex.: linha 15 = PO-UI v15/Angular 15; linha 19 = PO-UI v19/Angular 19).

Serviços da primeira versão (verbatim do CHANGELOG): `breadcrumb-control.service`, `cache-params.service`, `menu-datasul.service`, `profile.service`, `report.service`, `session-info.service`, `date.util`, `disclaimer.util`, `field-validation.util`, `filter-range.util`, `generic-functions.utils`.

### MenuDatasulService — interagir com o Menu do Datasul

```typescript
import { MenuDatasulService } from 'dts-backoffice-util';
constructor(public menuDatasulService: MenuDatasulService) { }

// callProgress — executar programa Progress
program = {
  prg: 'bas_lote_liquidac_acr',
  params: [
    { type: 'character', value: 'ABC' },
    { type: 'integer', value: '345' }
  ]
};
this.menuDatasulService.callProgress(program);

// openTHF — abrir tela THF1 cadastrada no menu do Datasul
this.menuDatasulService.openTHF('dts/mab/activities', '', true);

// openPath — abrir tela (PO-UI) em nova aba do Datasul
this.menuDatasulService.openPath('html.creditCardOperator', '1509;10;1', true);

// sendNotification — notificação do Datasul
notification = {
  type: 'success',
  title: 'Operação executada com Sucesso.',
  detail: 'A Operação 4343 finalizou conforme parametrizado.'
};
this.menuDatasulService.sendNotification(notification);

// programSecurity — verificar segurança do menu para o usuário
this.menuDatasulService.programSecurity('html.cashControl')
  .subscribe((response: Array<Object>) => {
    // Ex.: { programName: "html.cashControl", hasAccess: true }
  });
// Aceita também uma lista de programas.
```

**Navegar entre telas THL pelo menu Datasul:** use `openPath()` (telas PO-UI/HTML), `openTHF()` (telas THF1) e `callProgress()` (programas Progress puros), passando os parâmetros no formato esperado pelo menu.

### ReportService — integração com datasul-report

```typescript
import { ReportService, IReportServiceParams, ReportFormats } from 'dts-backoffice-util';
constructor(public reportService: ReportService) { }

// enum ReportFormats: XLSX="xlsx", PDF="pdf", DOCX="docx", HTML="html"

const params: IReportServiceParams = {
  reportName: 'crm/rel_campaign_export',
  programName: '/report/crm/crm0010',
  properties: [{ name: 'custom.quick_search', value: '186' }], // Array<IProperty> { name, value }
  dialect: 'pt',
  download: true,
  downloadName: '2020-1-10_CRM_CAMPANHAS',
  format: ReportFormats.XLSX
};

this.reportService.generate(params).subscribe(
  () => this.notification.success('Arquivo baixado com sucesso!'),
  () => this.notification.error('Não foi possível baixar o arquivo')
);
```

`IReportServiceParams` (campos observados): `reportName`, `programName`, `properties: Array<IProperty>`, `dialect`, `download`, `downloadName`, `format`.

### TotvsScheduleExecutionComponent / TotvsScheduleExecutionService — integração RPW

Busca do servidor RPW usa o endpoint oficial `/dts/datasul-rest/resources/prg/btb/v1/servidoresExecucao`.

**Propriedades:** `programName`, `externalName`, `programEMS5`, `programStyle`, `programVersion`, `parameters`, `paramSelections`, `paramDigitDef`, `paramDigitData`, `disabledParams` (habilita/desabilita infos do agendamento: data, servidor, repetição etc.). **Métodos:** `setScheduleParameters()` (enviar as informações do agendamento, ex.: última configuração do usuário), `getScheduleParameters()`. **Evento:** `(endExecution)` — dispara com as informações do agendamento; a interface `IScheduleParameters` retorna `listExecutionID` (número da agenda criada no RPW). Consulta de status: `getExecutionByJobScheduleID()` e `getExecutionByExecutionID()`.

```html
<!-- EMS5 -->
<app-totvs-schedule-execution #schParam
  programName="rpt_grp_repres" externalName="rpt_grp_repres"
  programEMS5="true" programStyle="40" programVersion="1.00.00.004"
  [parameters]="parametersRpw" [paramSelections]="paramSelectionsRpw"
  (endExecution)="endExecutionSchedule($event)">
</app-totvs-schedule-execution>

<!-- EMS2 -->
<app-totvs-schedule-execution #schParam
  programName="pdapi701" externalName="pdp/pdapi701.p"
  [parameters]="parametersRpw" [paramDigitDef]="paramDigitDefRpw"
  [paramDigitData]="paramDigitDataRpw"
  (endExecution)="endExecutionSchedule($event)">
</app-totvs-schedule-execution>
```

```typescript
@ViewChild('schParam', { static: true }) schParam: TotvsScheduleExecutionComponent;
scheduleParams: IScheduleParameters;
parametersRpw = new Array<any>();

ngOnInit() {
  this.loadLocalStorage();
  this.schParam.setScheduleParameters(this.scheduleParams);
}
endExecutionSchedule(params: IScheduleParameters) {
  // salvar params digitados; params.listExecutionID = número da agenda
}
```

Parâmetros são passados via temp-table através dos arrays `parameters`/`paramSelections` (EMS5) ou `paramDigitDef`/`paramDigitData` (EMS2).

### TranslateService — controle de idioma

"Realizar o controle do idioma corrente, considerando o que estiver parametrizado no Cadastro de Usuários do Datasul, e caso não esteja informado, será considerado o idioma informado no Browser."

```typescript
import { TranslateService } from 'dts-backoffice-util';
```

*(Nomes/assinaturas exatos dos métodos: a confirmar no README/raw do repo; não assuma métodos do ngx-translate.)*

### ProfileService — preferências do usuário no Datasul

```typescript
import { ProfileService, IProfile } from 'dts-backoffice-util';
constructor(public preferenceService: ProfileService) { }

// IProfile: { dataCode, pageId, dataValue, userCode }
const profile: IProfile = {
  dataCode: 'preference',
  pageId: 'clientes-list',
  dataValue: this.colunasConfiguradas, // ex.: config de colunas da tabela
  userCode: 'super'
};

this.preferenceService.setProfile(profile).subscribe(
  () => this.notification.success('Preferência salva com sucesso!'),
  () => this.notification.error('Não foi possível salvar a preferência')
);
```

`setProfile` aceita um parâmetro adicional opcional (boolean) para exibir tela de loading. `getProfile()` carrega a preferência salva. Uso típico: salvar configuração de colunas/filtros por tela.

### FileUtil — manipulação de arquivos (métodos estáticos)

```typescript
import { FileUtil, DownloadDataParams } from 'dts-backoffice-util';

// downloadFile — conteúdo do backend
FileUtil.downloadFile(response['content'], response['filename']);

// downloadFile — Blob (4º parâmetro base64 = false)
FileUtil.downloadFile(response, 'qrCode.png', '', false);

// downloadData — exportar CSV
const p = new DownloadDataParams();
p.fileName = 'clientes.csv';
p.columnDelimiter = ';';
p.columnList = ['codigo', 'nome']; // respeita a ordem informada
p.literals = this.literals;
FileUtil.downloadData(p, dados);
```

**Métodos:** `downloadFile()` (parâmetro `base64: boolean` indica formato base64 ou Blob), `b64toBlob()` (Base64 → Blob), `fileToB64()` (arquivo → Base64), `downloadData()` (gera e baixa CSV). Interface `IDownloadDataParams`/classe `DownloadDataParams`: `fileName`, `columnDelimiter`, `literals`, `columnList`.

### DisclaimerUtil — sincronização filtros ↔ disclaimers

Padrão de nomes: `make*` cria o disclaimer a partir do valor do filtro; `atz*` (de "atualiza") atualiza o valor do filtro a partir do disclaimer. **Atenção:** os nomes no código-fonte usam a grafia "Disclamer" (sem o "i") em `atzBooleanFromDisclamer` e `atzDatepickerRangeFromDisclamer`.

**Métodos (do CHANGELOG):**
- `makeDisclaimerFromDatepickerRange()` / `atzDatepickerRangeFromDisclamer()` — cria/atualiza o objeto Disclaimer para o `PoDatepickerRange`.
- `atzBooleanFromDisclamer()` — retorna valor verdadeiramente boolean (necessário para o `po-switch` funcionar corretamente).
- `makeDisclaimerFromNumber(..., options)` — 5º parâmetro `options` é uma lista de-para (valor × label); se informado, exibe o label no disclaimer mantendo o valor numérico.
- `makeDisclaimerFromMultiSelect(..., tradValue)` — `tradValue` indica se o value deve ser traduzido (via literals enviados ao serviço).
- `makeDisclaimerFromMultiSelectNumber()` — label String com valor numérico interno.

### GenericFunctionsUtils

`focusInternalInput()` — dá foco a um campo PO-UI dentro de um Modal ou quando o campo não está disponível na abertura da tela (casos em que não é possível usar `@ViewChild`).

### UserLoginService

"Retorna o login do usuário tanto no framework atual quanto no novo framework."

```typescript
import { UserLoginService } from 'dts-backoffice-util';
constructor(public sessionService: UserLoginService) { }

this.sessionService.getUserLogin().subscribe(user => {
  this.notification.success(`O usuário logado é ${user}`);
});
```

### BreadcrumbControlService

"Realiza a criação e controle do breadcrumb das telas." Inclui o método `delBreadcrumb` para excluir um item do breadcrumb. *(Assinatura do método de criação: a confirmar no README.)*

### Pipe dtsDateFormat

"PIPE para formatar datas, ele foi criado pois o PIPE date do angular não consegue formatar datas inferiores a 1901." Requer importar `DtsBackofficeUtilsModule`.

```html
<po-info p-label="Data" [p-value]="date | dtsDateFormat : 'dd/MM/yyyy'"></po-info>
<po-info p-label="Data" [p-value]="date | dtsDateFormat : 'MM/dd/yyyy'"></po-info>
```

📚 https://github.com/ModernizaDatasul/dts-backoffice-util · https://www.npmjs.com/package/dts-backoffice-util

## 10.3 Padrão de Service Angular para CRUD

APIs REST Datasul retornam o padrão `{ items, hasNext }` com paginação `page`/`pageSize` (o tipo `TotvsResponse<T>` do dts-backoffice-util encapsula isso).

```typescript
export interface TotvsResponse<T> { items: T[]; hasNext: boolean; }

@Injectable({ providedIn: 'root' })
export class CadastroService {
  private url = '/dts/datasul-rest/resources/prg/api/v1/clientes';
  constructor(private http: HttpClient) {}

  query(page = 1, pageSize = 20): Observable<TotvsResponse<ICliente>> {
    return this.http.get<TotvsResponse<ICliente>>(
      `${this.url}?page=${page}&pageSize=${pageSize}`
    );
  }
  get(id: string): Observable<ICliente> { return this.http.get<ICliente>(`${this.url}/${id}`); }
  create(item: ICliente): Observable<ICliente> { return this.http.post<ICliente>(this.url, item); }
  update(id: string, item: ICliente): Observable<ICliente> { return this.http.put<ICliente>(`${this.url}/${id}`, item); }
  delete(id: string): Observable<void> { return this.http.delete<void>(`${this.url}/${id}`); }
}
```

Tratamento de erros: deixe o `PoHttpInterceptorModule` exibir o payload TOTVS automaticamente; para casos específicos, use `catchError` e trate localmente (enviando `X-PO-No-Message`/`X-PO-No-Error` quando quiser suprimir a notificação automática).

## 10.4 HttpClient e Interceptors

Configure via `provideHttpClient(withInterceptorsFromDi())` (standalone) ou `HttpClientModule` (NgModule). Em **desenvolvimento**, use um interceptor para injetar Basic Auth; em **produção** o framework Datasul gerencia a sessão. Payload de erro TOTVS: `code`, `message`, `detailedMessage`.

```typescript
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const cloned = req.clone({
      setHeaders: { Authorization: 'Basic ' + btoa('usuario:senha') } // apenas DEV
    });
    return next.handle(cloned).pipe(
      catchError((err: HttpErrorResponse) => {
        // err.error: { code, message, detailedMessage }
        return throwError(() => err);
      })
    );
  }
}
```

```typescript
providers: [
  { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
]
```

O loading automático e as mensagens de erro globais são melhor delegados ao interceptor nativo do PO (Seção 10.1), evitando duplicar lógica.

---

# SEÇÃO 13 — INTERNACIONALIZAÇÃO (I18N.md)

## 13.1 Configuração do i18n no PO-UI

O `PoI18nService` "possibilita utilizar múltiplos idiomas e contextos na aplicação". Configura-se via `PoI18nModule.config(config)`.

```typescript
import { PoI18nModule, PoI18nConfig } from '@po-ui/ng-components';
import { generalEn } from './i18n/general-en';
import { generalPt } from './i18n/general-pt';

const config: PoI18nConfig = {
  default: {
    language: 'pt-BR',
    context: 'geral',
    cache: true
  },
  contexts: {
    geral: {
      'pt-BR': generalPt,
      'en-US': generalEn
    }
    // Alternativa: um contexto pode apontar para uma URL de serviço
    // financeiro: { url: '/api/i18n/financeiro/' }
  }
};

@NgModule({ imports: [PoI18nModule.config(config)] })
export class AppModule {}
```

**Idiomas suportados pelo PO-UI:** português, inglês, espanhol e russo (literais internas do componente têm essas variantes no fonte). É possível sobrescrever literais padrão informando as chaves no contexto.

## 13.2 Traduções customizadas

Estrutura do arquivo: **contexts → idioma → chave/valor**.

```typescript
// i18n/general-pt.ts
export const generalPt = { salvar: 'Salvar', cancelar: 'Cancelar', excluir: 'Excluir' };
// i18n/general-en.ts
export const generalEn = { salvar: 'Save', cancelar: 'Cancel', excluir: 'Delete' };
```

Uso no componente:

```typescript
import { PoI18nService } from '@po-ui/ng-components';

export class ClienteComponent implements OnInit {
  literals: any = {};
  constructor(private poI18nService: PoI18nService) {}

  ngOnInit() {
    // Todas as literais do contexto ativo:
    this.poI18nService.getLiterals().subscribe(l => this.literals = l);
    // Ou por chaves específicas / contexto:
    // this.poI18nService.getLiteralsByKeys(['salvar'], { context: 'geral' })...
  }
}
```

```html
<po-button [p-label]="literals.salvar"></po-button>
<!-- Alternativa via pipe no template: -->
<span>{{ 'salvar' | poI18n }}</span>
```

Ordem de resolução do idioma ativo (do `po-i18n-base.service.ts`): (1) idioma armazenado no localStorage via `setLanguage()`; (2) idioma do navegador; (3) `default.language` configurado.

## 13.3 Integração com Datasul

Detecte o idioma do usuário logado com o `TranslateService` do dts-backoffice-util, que considera o idioma parametrizado no **Cadastro de Usuários do Datasul** e, na ausência dele, o idioma do **browser**. Alimente o `PoI18nService.setLanguage()` com esse valor no bootstrap da aplicação, garantindo que literais PO e customizadas fiquem no idioma correto.

```typescript
// pseudo-integração (confirmar assinatura do TranslateService no README)
this.translateService.getCurrentLanguage(); // idioma Datasul → fallback browser
this.poI18nService.setLanguage(idiomaDatasul, true); // reload das literais
```

📚 https://po-ui.io/documentation/po-i18n

---

## Recommendations

**Estágio 1 — Fundação (fazer primeiro):**
1. Padronize as rotas CRUD conforme 7.1 e centralize a navegação com `Router`/`ActivatedRoute`; adote lazy loading por feature module do THL.
2. Ative o `PoHttpInterceptorModule` (com `provideAnimations()` + `provideHttpClient(withInterceptorsFromDi())`) e alinhe com o back-end Progress/PASOE o payload de mensagens TOTVS (`code`, `message`, `detailedMessage`, `type`, `details`, `detailTitle`) para obter feedback automático sem código extra na tela.
3. Configure o i18n (13.1) com contexto `geral` e integre o `TranslateService` do dts-backoffice-util no bootstrap.

**Estágio 2 — Componentização:**
4. Use `dts-backoffice-util` para toda integração Datasul: `MenuDatasulService` (navegação entre telas THL), `ReportService` (relatórios), `TotvsScheduleExecutionComponent` (RPW), `ProfileService` (persistir configuração de colunas/filtros), `DisclaimerUtil` (sincronizar filtros ↔ disclaimers) e `UserLoginService`.
5. Aplique consistentemente os padrões de UX da Seção 9.9 (success/warning/error; overlay vs inline; confirm antes de excluir; CanDeactivate).

**Estágio 3 — Refino e verificação:**
6. Antes de a IA de codificação gerar telas, **confirme no código-fonte** (`.interface.ts`) as assinaturas sinalizadas como "a confirmar".

**Thresholds que mudam a recomendação:** se o back-end **não** padronizar o payload de mensagem TOTVS, abandone o feedback automático do interceptor e trate erros explicitamente com `catchError` + `PoNotificationService`. Se a aplicação usar Angular ≥17 standalone, substitua `app-routing.module.ts`/`NgModule` por `provideRouter`/`ApplicationConfig`.

## Caveats
- **Interfaces confirmadas no fonte oficial:** `PoModalAction` (verbatim), comportamento de `po-menu` (até 4 níveis, ícones no 1º nível, colapso exige `icon`+`shortLabel`, >1200px), constantes do interceptor (`X-PO-No-Error`, `X-PO-No-Message`, `X-PO-Screen-Lock`), migração de ícones para Animalia (`an an-*`), ordem de resolução do `PoI18nService`.
- **Descritas a partir de exemplos/documentação (confirmar campos exatos nos `.interface.ts`):** `PoToolbarAction`, `PoToolbarProfile`, `PoBreadcrumbItem`, `PoDialogAlertOptions`/`PoDialogConfirmOptions`, `PoPopupAction`, `PoDropdownAction`, `PoDisclaimer`/`PoDisclaimerGroup`, `PoStepperItem`, propriedades de `po-page-slide`, `po-progress` e `po-accordion-item`.
- **dts-backoffice-util:** métodos e exemplos vêm do README/NPM (v0.0.21 e v15.4.0) e do CHANGELOG; **assinaturas completas (nomes/tipos de todos os parâmetros)** de `TranslateService`, de vários métodos `make*`/`atz*` do `DisclaimerUtil`, de `getProfile()`, da interface `IDownloadDataParams` e do método de criação do `BreadcrumbControlService` **não foram recuperadas verbatim** — pull do arquivo raw `projects/dts-backoffice-util/README.md` antes de gerar código final. A grafia dos métodos `atz*FromDisclamer` está **sem o "i"** propositalmente (é assim no código).
- **Idiomas suportados** listados a partir das literais internas do fonte; verifique a documentação oficial para a lista definitiva por versão.
- As páginas GitHub blob e npmjs.com estão sujeitas a bloqueio anti-bot; use os arquivos raw (`raw.githubusercontent.com`) para recuperar conteúdo integral.
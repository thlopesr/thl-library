---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
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

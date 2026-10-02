# PO-UI Rodada 4/4 — Padrões de Tela, Ícones e Referência Final (THL / Datasul 12)

## TL;DR
- Os 7 padrões de tela abaixo (Listagem, Cadastro/Edição, Detalhe, Master-Detail, CRUD Dinâmico, Consulta, Abas) são blueprints end-to-end prontos para o Claude Code replicar — todos em Angular 21 standalone, PO-UI 21.x, consumindo o backend TOTVS `{ items, hasNext }` com paginação `page`/`pageSize`.
- **Ícones:** a lib POIcon (`po-icon-*`) foi depreciada e **removida na v21.x.x**; usar exclusivamente a **Animalia Icons** com prefixo `an an-<nome>` (ex.: `an an-pencil-simple`). Os nomes seguem a convenção Phosphor (kebab-case). Migração: `<i class="po-icon po-icon-user"></i>` → `<i class="an an-user"></i>`.
- Componentes-chave verificados em fonte oficial: `po-page-list`/`po-page-default`, `po-table`, `po-modal`, `po-dynamic-form`/`po-dynamic-view`, `po-page-dynamic-table`/`-edit`/`-detail`, `po-lookup`, `po-disclaimer-group`.

## Key Findings
1. **Prefixo `an an-*` confirmado em código-fonte oficial.** A interface `po-table-column.interface.ts` do repositório po-ui/po-angular já usa, verbatim, `icon: 'an an-plus'`, `icon: 'an an-pencil-simple'` e `icon: 'an an-trash'` nos exemplos de coluna do tipo `icon`.
2. **POIcon removido na v21.** O guia oficial de *deprecations* do po-angular registra: "A partir da v21, a biblioteca de ícones POIcon foi removida. O conjunto padrão de ícones passa a ser a lib Animalia Icons" — e a página po-ui.io/icons repete: "A Biblioteca de ícones POIcon está depreciada e foi removida na v21.x.x. Recomendamos o uso da Lib Animalia Icons".
3. **Templates dinâmicos** (`po-page-dynamic-table/-edit/-detail`) suportam metadata via `p-service-api` + `GET {end-point}/metadata?type=list&version={version}`, com ações `beforeSave`/`beforeRemove`/`beforeDetail`/`beforeDuplicate` e custom actions.
4. **Font Awesome** é suportado como fonte de ícone externa (via `<link>` no `index.html` e `p-icon="fa fa-check-circle"`), confirmado em discussão oficial e no sample do `po-button`.
5. **Rotas** dos padrões espelham o `crud-po-ui-workshop` oficial (`PeopleRoutingModule` com `''`, `view/:id`, `edit/:id`, `new`).

---

## SEÇÃO 11 — SCREEN-PATTERNS.md

> **Convenções comuns a todos os padrões:**
> - Rotas: `/recurso`, `/recurso/new`, `/recurso/edit/:id`, `/recurso/detail/:id`.
> - Backend TOTVS: resposta paginada `{ items: T[], hasNext: boolean }`, parâmetros `page` e `pageSize`.
> - Angular 21 / PO-UI 21.x, componentes standalone.
> - Módulos: `@po-ui/ng-components` (UI) e `@po-ui/ng-templates` (templates/páginas).
> - Os exemplos são **construção própria baseada nas APIs oficiais documentadas** e na estrutura do `crud-po-ui-workshop`; endpoints `/dts/datasul-rest/...` são ilustrativos.

---

### PADRÃO 1 — Listagem/Consulta (CRUD-L)

**list/recurso.model.ts**
```typescript
// recurso.model.ts — interfaces e models compartilhados
// Representa uma entidade genérica de cadastro (ex.: colaborador THL)
export interface Recurso {
  id: string;
  codigo: string;
  nome: string;
  valor: number;
  dataCadastro: string;       // ISO date
  status: RecursoStatus;
}

export type RecursoStatus = 'ativo' | 'inativo' | 'pendente';

// Resposta padrão TOTVS/Datasul para coleções paginadas
export interface TotvsPage<T> {
  items: T[];
  hasNext: boolean;
}

// Filtros aplicados via busca avançada
export interface RecursoFilter {
  codigo?: string;
  nome?: string;
  status?: RecursoStatus;
}
```

**list/recurso.service.ts**
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Recurso, RecursoFilter, TotvsPage } from './recurso.model';

@Injectable({ providedIn: 'root' })
export class RecursoService {
  private http = inject(HttpClient);
  // Endpoint REST PASOE/Datasul. O interceptor PO adapta o payload TOTVS.
  private readonly api = '/dts/datasul-rest/resources/prg/thl/v1/recursos';

  // Busca paginada server-side. Converte filtros e ordenação em query params.
  getAll(
    page: number,
    pageSize: number,
    filters: RecursoFilter = {},
    sort?: string
  ): Observable<TotvsPage<Recurso>> {
    let params = new HttpParams()
      .set('page', page)
      .set('pageSize', pageSize);

    // Cada filtro preenchido vira um query param (base para disclaimers)
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        params = params.set(key, String(value));
      }
    });

    if (sort) {
      params = params.set('order', sort); // ex.: 'nome' ou '-nome' (desc)
    }

    return this.http.get<TotvsPage<Recurso>>(this.api, { params });
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.api}/${id}`);
  }
}
```

**list/recurso-list.component.ts**
```typescript
import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';
import {
  PoBreadcrumb,
  PoPageAction,
  PoTableColumn,
  PoTableAction,
  PoNotificationService,
  PoDialogService,
  PoDisclaimer,
  PoDisclaimerGroup,
  PoModule
} from '@po-ui/ng-components';
import { FormsModule } from '@angular/forms';
import { RecursoService } from './recurso.service';
import { Recurso, RecursoFilter } from './recurso.model';

@Component({
  selector: 'app-recurso-list',
  standalone: true,
  imports: [PoModule, FormsModule],
  templateUrl: './recurso-list.component.html'
})
export class RecursoListComponent implements OnInit {
  private service = inject(RecursoService);
  private router = inject(Router);
  private poNotification = inject(PoNotificationService);
  private poDialog = inject(PoDialogService);

  items: Recurso[] = [];
  loading = false;
  hasNext = false;
  private page = 1;
  private readonly pageSize = 20;

  // Modelo do formulário de busca avançada (modal)
  advancedFilter: RecursoFilter = {};

  breadcrumb: PoBreadcrumb = {
    items: [{ label: 'THL', link: '/' }, { label: 'Recursos' }]
  };

  // Ações de página (topo direito)
  pageActions: PoPageAction[] = [
    { label: 'Novo', action: () => this.novo(), icon: 'an an-plus' },
    { label: 'Atualizar', action: () => this.recarregar(), icon: 'an an-arrows-clockwise' }
  ];

  // Grupo de disclaimers dos filtros ativos
  disclaimerGroup: PoDisclaimerGroup = {
    title: 'Filtros aplicados',
    disclaimers: [],
    change: (disclaimers: PoDisclaimer[]) => this.onChangeDisclaimers(disclaimers)
  };

  // Colunas tipadas (texto, moeda, data, status com label colorida)
  columns: PoTableColumn[] = [
    { property: 'codigo', label: 'Código', width: '12%' },
    { property: 'nome', label: 'Nome' },
    { property: 'valor', label: 'Valor', type: 'currency', format: 'BRL', width: '15%' },
    { property: 'dataCadastro', label: 'Cadastro', type: 'date', format: 'dd/MM/yyyy', width: '15%' },
    {
      property: 'status',
      label: 'Status',
      type: 'label',
      width: '12%',
      labels: [
        { value: 'ativo', label: 'Ativo', color: 'color-11' },
        { value: 'inativo', label: 'Inativo', color: 'color-07' },
        { value: 'pendente', label: 'Pendente', color: 'color-08' }
      ]
    }
  ];

  // Ações por linha
  tableActions: PoTableAction[] = [
    { label: 'Visualizar', action: (row: Recurso) => this.visualizar(row), icon: 'an an-eye' },
    { label: 'Editar', action: (row: Recurso) => this.editar(row), icon: 'an an-pencil-simple' },
    { label: 'Excluir', action: (row: Recurso) => this.confirmarExclusao(row), icon: 'an an-trash', type: 'danger' }
  ];

  ngOnInit(): void {
    this.carregar(true);
  }

  // ---- Busca rápida (po-page-list p-filter) ----
  buscaRapida(termo: string): void {
    this.advancedFilter = { ...this.advancedFilter, nome: termo };
    this.sincronizarDisclaimers();
    this.carregar(true);
  }

  // ---- Busca avançada aplicada (via modal) ----
  aplicarBuscaAvancada(): void {
    this.sincronizarDisclaimers();
    this.carregar(true);
  }

  // Converte o objeto de filtro em disclaimers visíveis
  private sincronizarDisclaimers(): void {
    const d: PoDisclaimer[] = [];
    if (this.advancedFilter.codigo) d.push({ property: 'codigo', label: `Código: ${this.advancedFilter.codigo}`, value: this.advancedFilter.codigo });
    if (this.advancedFilter.nome) d.push({ property: 'nome', label: `Nome: ${this.advancedFilter.nome}`, value: this.advancedFilter.nome });
    if (this.advancedFilter.status) d.push({ property: 'status', label: `Status: ${this.advancedFilter.status}`, value: this.advancedFilter.status });
    this.disclaimerGroup.disclaimers = d;
  }

  // Disparado ao remover disclaimer individual ou "remover todos"
  private onChangeDisclaimers(disclaimers: PoDisclaimer[]): void {
    const filtro: RecursoFilter = {};
    disclaimers.forEach(d => { (filtro as any)[d.property] = d.value; });
    this.advancedFilter = filtro;
    this.carregar(true);
  }

  // ---- Carga paginada (carregar mais / show-more) ----
  private carregar(reset = false): void {
    if (reset) { this.page = 1; this.items = []; }
    this.loading = true;
    this.service.getAll(this.page, this.pageSize, this.advancedFilter, 'nome').subscribe({
      next: (resp) => {
        this.items = reset ? resp.items : [...this.items, ...resp.items];
        this.hasNext = resp.hasNext;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.poNotification.error('Erro ao carregar a lista de recursos.');
      }
    });
  }

  carregarMais(): void { this.page++; this.carregar(false); }
  recarregar(): void { this.carregar(true); }

  // ---- Navegação ----
  novo(): void { this.router.navigate(['/recursos/new']); }
  editar(row: Recurso): void { this.router.navigate(['/recursos/edit', row.id]); }
  visualizar(row: Recurso): void { this.router.navigate(['/recursos/detail', row.id]); }

  // ---- Exclusão com confirmação e notificação ----
  confirmarExclusao(row: Recurso): void {
    this.poDialog.confirm({
      title: 'Confirmar exclusão',
      message: `Deseja realmente excluir o recurso "${row.nome}"?`,
      confirm: () => this.excluir(row)
    });
  }

  private excluir(row: Recurso): void {
    this.loading = true;
    this.service.delete(row.id).subscribe({
      next: () => {
        this.poNotification.success('Recurso excluído com sucesso.');
        this.carregar(true);
      },
      error: () => {
        this.loading = false;
        this.poNotification.error('Não foi possível excluir o recurso.');
      }
    });
  }
}
```

**list/recurso-list.component.html**
```html
<po-page-list
  p-title="Recursos"
  [p-breadcrumb]="breadcrumb"
  [p-actions]="pageActions"
  [p-filter]="{ action: buscaRapida.bind(this), placeholder: 'Buscar por nome...' }"
  [p-disclaimer-group]="disclaimerGroup">

  <po-button
    p-label="Busca avançada"
    p-icon="an an-funnel"
    (p-click)="advancedModal.open()">
  </po-button>

  <po-table
    [p-columns]="columns"
    [p-items]="items"
    [p-actions]="tableActions"
    [p-loading]="loading"
    [p-sort]="true"
    [p-striped]="true"
    p-container
    [p-show-more-disabled]="!hasNext"
    (p-show-more)="carregarMais()">
  </po-table>
</po-page-list>

<!-- Modal de busca avançada -->
<po-modal #advancedModal p-title="Busca avançada"
  [p-primary-action]="{ label: 'Filtrar', action: aplicarBuscaAvancada.bind(this) }">
  <form>
    <div class="po-row">
      <po-input class="po-md-6" name="codigo" [(ngModel)]="advancedFilter.codigo" p-label="Código"></po-input>
      <po-input class="po-md-6" name="nome" [(ngModel)]="advancedFilter.nome" p-label="Nome"></po-input>
      <po-select class="po-md-6" name="status" [(ngModel)]="advancedFilter.status" p-label="Status"
        [p-options]="[{ label: 'Ativo', value: 'ativo' }, { label: 'Inativo', value: 'inativo' }, { label: 'Pendente', value: 'pendente' }]">
      </po-select>
    </div>
  </form>
</po-modal>
```

**recurso-routing.module.ts (parcial)**
```typescript
import { Routes } from '@angular/router';

export const recursoRoutes: Routes = [
  { path: '', loadComponent: () => import('./list/recurso-list.component').then(m => m.RecursoListComponent) },
  { path: 'new', loadComponent: () => import('./form/recurso-form.component').then(m => m.RecursoFormComponent) },
  { path: 'edit/:id', loadComponent: () => import('./form/recurso-form.component').then(m => m.RecursoFormComponent) },
  { path: 'detail/:id', loadComponent: () => import('./detail/recurso-detail.component').then(m => m.RecursoDetailComponent) }
];
```

> **Fonte:** estrutura de rotas espelha o `crud-po-ui-workshop`; disclaimers baseados no `po-disclaimer-group` oficial; colunas `type: 'label'` conforme documentação do `po-table`.

---

### PADRÃO 2 — Cadastro/Edição (CRUD-CE)

**form/recurso.service.ts (métodos adicionais ao do Padrão 1)**
```typescript
getById(id: string): Observable<Recurso> {
  return this.http.get<Recurso>(`${this.api}/${id}`);
}
create(data: Partial<Recurso>): Observable<Recurso> {
  return this.http.post<Recurso>(this.api, data);
}
update(id: string, data: Partial<Recurso>): Observable<Recurso> {
  return this.http.put<Recurso>(`${this.api}/${id}`, data);
}
```

**form/recurso-form.component.ts**
```typescript
import { Component, OnInit, ViewChild, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgForm, FormsModule } from '@angular/forms';
import { PoBreadcrumb, PoNotificationService, PoDialogService, PoModule } from '@po-ui/ng-components';
import { RecursoService } from '../list/recurso.service';
import { Recurso } from '../list/recurso.model';

@Component({
  selector: 'app-recurso-form',
  standalone: true,
  imports: [PoModule, FormsModule],
  templateUrl: './recurso-form.component.html'
})
export class RecursoFormComponent implements OnInit {
  private service = inject(RecursoService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private poNotification = inject(PoNotificationService);
  private poDialog = inject(PoDialogService);

  @ViewChild('form') form!: NgForm;

  model: Partial<Recurso> & { cnpj?: string; categoria?: string; obs?: string } = { status: 'ativo' };
  loading = false;
  isEdit = false;
  private id: string | null = null;
  private dirtySnapshot = '';

  breadcrumb: PoBreadcrumb = { items: [] };

  // Combo com carga dinâmica de API (ex.: categorias)
  categoriaOptions: Array<{ label: string; value: string }> = [];

  ngOnInit(): void {
    // Verifica criação vs edição via ActivatedRoute
    this.id = this.route.snapshot.paramMap.get('id');
    this.isEdit = !!this.id;
    this.montarBreadcrumb();
    this.carregarCombos();

    if (this.isEdit && this.id) {
      this.loading = true;
      this.service.getById(this.id).subscribe({
        next: (r) => {
          this.model = r;
          this.dirtySnapshot = JSON.stringify(this.model);
          this.montarBreadcrumb();
          this.loading = false;
        },
        error: () => { this.loading = false; this.poNotification.error('Erro ao carregar o registro.'); }
      });
    } else {
      this.dirtySnapshot = JSON.stringify(this.model);
    }
  }

  // Breadcrumb dinâmico: Novo vs Editar: Código X
  private montarBreadcrumb(): void {
    this.breadcrumb = {
      items: [
        { label: 'THL', link: '/' },
        { label: 'Recursos', link: '/recursos' },
        { label: this.isEdit ? `Editar: ${this.model.codigo ?? ''}` : 'Novo' }
      ]
    };
  }

  private carregarCombos(): void {
    // Troque pela chamada real do service (carga dinâmica via API)
    this.categoriaOptions = [
      { label: 'Categoria A', value: 'A' },
      { label: 'Categoria B', value: 'B' }
    ];
  }

  private houveAlteracao(): boolean {
    return JSON.stringify(this.model) !== this.dirtySnapshot;
  }

  // Salvar / Salvar e Novo
  salvar(novoAposSalvar = false): void {
    if (this.form.invalid) {
      this.poNotification.warning('Preencha os campos obrigatórios.');
      return;
    }
    this.loading = true;
    const req = this.isEdit && this.id
      ? this.service.update(this.id, this.model)
      : this.service.create(this.model);

    req.subscribe({
      next: () => {
        this.poNotification.success('Registro gravado com sucesso.');
        this.loading = false;
        if (novoAposSalvar) {
          // Limpa o formulário para novo cadastro
          this.model = { status: 'ativo' };
          this.isEdit = false;
          this.id = null;
          this.dirtySnapshot = JSON.stringify(this.model);
          this.form.reset(this.model);
          this.montarBreadcrumb();
        } else {
          this.router.navigate(['/recursos']);
        }
      },
      error: () => { this.loading = false; this.poNotification.error('Erro ao gravar o registro.'); }
    });
  }

  // Cancelar com confirmação se houver alterações
  cancelar(): void {
    if (this.houveAlteracao()) {
      this.poDialog.confirm({
        title: 'Descartar alterações',
        message: 'Existem alterações não salvas. Deseja sair mesmo assim?',
        confirm: () => this.router.navigate(['/recursos'])
      });
    } else {
      this.router.navigate(['/recursos']);
    }
  }
}
```

**form/recurso-form.component.html**
```html
<po-page-default p-title="{{ isEdit ? 'Editar recurso' : 'Novo recurso' }}" [p-breadcrumb]="breadcrumb">
  <po-widget>
    <form #form="ngForm">
      <po-divider p-label="Dados gerais"></po-divider>
      <div class="po-row">
        <po-input class="po-md-4" name="codigo" [(ngModel)]="model.codigo" p-label="Código" p-required></po-input>
        <po-input class="po-md-8" name="nome" [(ngModel)]="model.nome" p-label="Nome" p-required></po-input>

        <!-- Decimal/moeda -->
        <po-decimal class="po-md-4" name="valor" [(ngModel)]="model.valor" p-label="Valor" p-decimals-length="2"></po-decimal>

        <!-- Combo com carga dinâmica de API -->
        <po-select class="po-md-4" name="categoria" [(ngModel)]="model.categoria" p-label="Categoria" [p-options]="categoriaOptions"></po-select>

        <po-datepicker class="po-md-4" name="dataCadastro" [(ngModel)]="model.dataCadastro" p-label="Data de cadastro"></po-datepicker>

        <!-- Máscara de entrada (CNPJ) -->
        <po-input class="po-md-4" name="cnpj" [(ngModel)]="model.cnpj" p-label="CNPJ" p-mask="99.999.999/9999-99"></po-input>

        <po-switch class="po-md-4" name="status" [(ngModel)]="model.status" p-label="Ativo" p-label-on="Sim" p-label-off="Não"></po-switch>
      </div>

      <po-divider p-label="Observações"></po-divider>
      <div class="po-row">
        <po-textarea class="po-md-12" name="obs" [(ngModel)]="model.obs" p-label="Observações"></po-textarea>
      </div>
    </form>
  </po-widget>

  <po-button p-label="Salvar" p-kind="primary" p-icon="an an-floppy-disk" [p-loading]="loading" (p-click)="salvar(false)"></po-button>
  <po-button p-label="Salvar e novo" p-icon="an an-plus" [p-loading]="loading" (p-click)="salvar(true)"></po-button>
  <po-button p-label="Cancelar" p-icon="an an-x" (p-click)="cancelar()"></po-button>
</po-page-default>
```

> Para lookup/zoom de campos relacionados, ver o Padrão 4 (`po-lookup` com `p-filter-service`). Use `po-decimal` para valores monetários/decimais e `po-number` para inteiros.

---

### PADRÃO 3 — Visualização/Detalhe (CRUD-D)

**detail/recurso-detail.component.ts**
```typescript
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import {
  PoBreadcrumb, PoPageAction, PoDynamicViewField, PoTableColumn,
  PoNotificationService, PoDialogService, PoModule
} from '@po-ui/ng-components';
import { RecursoService } from '../list/recurso.service';
import { Recurso } from '../list/recurso.model';

@Component({
  selector: 'app-recurso-detail',
  standalone: true,
  imports: [PoModule],
  templateUrl: './recurso-detail.component.html'
})
export class RecursoDetailComponent implements OnInit {
  private service = inject(RecursoService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private poNotification = inject(PoNotificationService);
  private poDialog = inject(PoDialogService);

  model: (Recurso & { itens?: any[] }) | null = null;
  loading = false;
  private id!: string;

  breadcrumb: PoBreadcrumb = { items: [] };

  // po-dynamic-view: exibição somente leitura orientada a metadados
  fields: PoDynamicViewField[] = [
    { property: 'codigo', label: 'Código', gridColumns: 4 },
    { property: 'nome', label: 'Nome', gridColumns: 8 },
    { property: 'valor', label: 'Valor', type: 'currency', format: 'BRL', gridColumns: 4 },
    { property: 'dataCadastro', label: 'Cadastro', type: 'date', gridColumns: 4 },
    { property: 'status', label: 'Status', gridColumns: 4, tag: true,
      labels: [
        { value: 'ativo', label: 'Ativo', color: 'color-11' },
        { value: 'inativo', label: 'Inativo', color: 'color-07' }
      ] }
  ];

  // Sub-tabela master-detail (ex.: itens)
  itemColumns: PoTableColumn[] = [
    { property: 'produto', label: 'Produto' },
    { property: 'quantidade', label: 'Qtd', type: 'number' },
    { property: 'valor', label: 'Valor', type: 'currency', format: 'BRL' }
  ];

  pageActions: PoPageAction[] = [
    { label: 'Editar', icon: 'an an-pencil-simple', action: () => this.router.navigate(['/recursos/edit', this.id]) },
    { label: 'Excluir', icon: 'an an-trash', type: 'danger', action: () => this.confirmarExclusao() },
    { label: 'Voltar', icon: 'an an-arrow-left', action: () => this.router.navigate(['/recursos']) }
  ];

  ngOnInit(): void {
    this.id = this.route.snapshot.paramMap.get('id')!;
    this.breadcrumb = { items: [{ label: 'THL', link: '/' }, { label: 'Recursos', link: '/recursos' }, { label: 'Detalhe' }] };
    this.loading = true;
    this.service.getById(this.id).subscribe({
      next: (r) => { this.model = r; this.loading = false; },
      error: () => { this.loading = false; this.poNotification.error('Erro ao carregar o registro.'); }
    });
  }

  private confirmarExclusao(): void {
    this.poDialog.confirm({
      title: 'Confirmar exclusão',
      message: 'Deseja excluir este registro?',
      confirm: () => this.service.delete(this.id).subscribe({
        next: () => { this.poNotification.success('Excluído com sucesso.'); this.router.navigate(['/recursos']); },
        error: () => this.poNotification.error('Erro ao excluir.')
      })
    });
  }
}
```

**detail/recurso-detail.component.html**
```html
<po-page-default p-title="Detalhe do recurso" [p-breadcrumb]="breadcrumb" [p-actions]="pageActions">
  <po-widget p-title="Dados do recurso">
    <po-loading-overlay *ngIf="loading"></po-loading-overlay>
    <po-dynamic-view *ngIf="model" [p-value]="model" [p-fields]="fields"></po-dynamic-view>
  </po-widget>

  <po-widget p-title="Itens" *ngIf="model?.itens?.length">
    <po-table [p-columns]="itemColumns" [p-items]="model!.itens!" p-container></po-table>
  </po-widget>
</po-page-default>
```

> `po-dynamic-view` é o componente oficial para exibição somente leitura orientada a metadados; alternativa manual é o `po-info`.

---

### PADRÃO 4 — Master-Detail

**master-detail/pedido.model.ts**
```typescript
export interface PedidoItem {
  id?: string;
  produtoCodigo: string;
  produtoNome: string;
  quantidade: number;
  valorUnitario: number;
}
export interface Pedido {
  id?: string;
  numero: string;
  clienteCodigo: string;
  clienteNome: string;
  itens: PedidoItem[];
}
export interface TotvsPage<T> { items: T[]; hasNext: boolean; }
```

**master-detail/pedido.service.ts**
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Pedido } from './pedido.model';

@Injectable({ providedIn: 'root' })
export class PedidoService {
  private http = inject(HttpClient);
  private readonly api = '/dts/datasul-rest/resources/prg/thl/v1/pedidos';

  getById(id: string): Observable<Pedido> { return this.http.get<Pedido>(`${this.api}/${id}`); }

  // Grava mestre + itens em UMA única chamada
  save(pedido: Pedido): Observable<Pedido> {
    return pedido.id
      ? this.http.put<Pedido>(`${this.api}/${pedido.id}`, pedido)
      : this.http.post<Pedido>(this.api, pedido);
  }
}
```

**master-detail/pedido-item-modal.component.ts**
```typescript
import { Component, EventEmitter, Output, ViewChild } from '@angular/core';
import { NgForm, FormsModule } from '@angular/forms';
import { PoModalComponent, PoModalAction, PoModule, PoLookupColumn } from '@po-ui/ng-components';
import { PedidoItem } from './pedido.model';

@Component({
  selector: 'app-pedido-item-modal',
  standalone: true,
  imports: [PoModule, FormsModule],
  templateUrl: './pedido-item-modal.component.html'
})
export class PedidoItemModalComponent {
  @ViewChild('modal', { static: true }) modal!: PoModalComponent;
  @ViewChild('form') form!: NgForm;
  @Output() confirmar = new EventEmitter<PedidoItem>();

  item: PedidoItem = this.novoItem();

  // Colunas do lookup de produto
  produtoColumns: PoLookupColumn[] = [
    { property: 'codigo', label: 'Código' },
    { property: 'nome', label: 'Descrição' }
  ];

  confirmAction: PoModalAction = { label: 'Confirmar', action: () => this.emitir() };
  cancelAction: PoModalAction = { label: 'Cancelar', action: () => this.modal.close() };

  abrir(item?: PedidoItem): void {
    this.item = item ? { ...item } : this.novoItem();
    this.modal.open();
  }

  private emitir(): void {
    if (this.form.invalid) return;
    this.confirmar.emit({ ...this.item });
    this.modal.close();
  }

  private novoItem(): PedidoItem {
    return { produtoCodigo: '', produtoNome: '', quantidade: 1, valorUnitario: 0 };
  }
}
```

**master-detail/pedido-item-modal.component.html**
```html
<po-modal #modal p-title="Item do pedido" [p-primary-action]="confirmAction" [p-secondary-action]="cancelAction">
  <form #form="ngForm">
    <div class="po-row">
      <po-input class="po-md-4" name="produtoCodigo" [(ngModel)]="item.produtoCodigo" p-label="Código do produto" p-required></po-input>
      <po-input class="po-md-8" name="produtoNome" [(ngModel)]="item.produtoNome" p-label="Descrição" p-required></po-input>
      <po-number class="po-md-6" name="quantidade" [(ngModel)]="item.quantidade" p-label="Quantidade" p-required></po-number>
      <po-decimal class="po-md-6" name="valorUnitario" [(ngModel)]="item.valorUnitario" p-label="Valor unitário" p-decimals-length="2"></po-decimal>
    </div>
  </form>
</po-modal>
```

**master-detail/pedido-form.component.ts**
```typescript
import { Component, OnInit, ViewChild, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgForm, FormsModule } from '@angular/forms';
import {
  PoBreadcrumb, PoTableColumn, PoTableAction,
  PoNotificationService, PoDialogService, PoModule
} from '@po-ui/ng-components';
import { PedidoService } from './pedido.service';
import { Pedido, PedidoItem } from './pedido.model';
import { PedidoItemModalComponent } from './pedido-item-modal.component';

@Component({
  selector: 'app-pedido-form',
  standalone: true,
  imports: [PoModule, FormsModule, PedidoItemModalComponent],
  templateUrl: './pedido-form.component.html'
})
export class PedidoFormComponent implements OnInit {
  private service = inject(PedidoService);
  private route = inject(ActivatedRoute);
  router = inject(Router);
  private poNotification = inject(PoNotificationService);
  private poDialog = inject(PoDialogService);

  @ViewChild('itemModal') itemModal!: PedidoItemModalComponent;

  pedido: Pedido = { numero: '', clienteCodigo: '', clienteNome: '', itens: [] };
  loading = false;
  private editIndex: number | null = null;

  breadcrumb: PoBreadcrumb = { items: [{ label: 'THL' }, { label: 'Pedidos' }] };

  itemColumns: PoTableColumn[] = [
    { property: 'produtoCodigo', label: 'Código' },
    { property: 'produtoNome', label: 'Produto' },
    { property: 'quantidade', label: 'Qtd', type: 'number' },
    { property: 'valorUnitario', label: 'Vl. Unit.', type: 'currency', format: 'BRL' }
  ];

  itemActions: PoTableAction[] = [
    { label: 'Editar', icon: 'an an-pencil-simple', action: (row: PedidoItem) => this.editarItem(row) },
    { label: 'Excluir', icon: 'an an-trash', type: 'danger', action: (row: PedidoItem) => this.excluirItem(row) }
  ];

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loading = true;
      this.service.getById(id).subscribe({
        next: (p) => { this.pedido = p; this.loading = false; },
        error: () => { this.loading = false; this.poNotification.error('Erro ao carregar o pedido.'); }
      });
    }
  }

  adicionarItem(): void { this.editIndex = null; this.itemModal.abrir(); }
  editarItem(row: PedidoItem): void { this.editIndex = this.pedido.itens.indexOf(row); this.itemModal.abrir(row); }

  // Itens mantidos em memória até salvar o mestre
  onItemConfirmado(item: PedidoItem): void {
    if (this.editIndex !== null) this.pedido.itens[this.editIndex] = item;
    else this.pedido.itens = [...this.pedido.itens, item];
    this.editIndex = null;
  }

  excluirItem(row: PedidoItem): void {
    this.poDialog.confirm({
      title: 'Excluir item',
      message: `Remover o item "${row.produtoNome}"?`,
      confirm: () => { this.pedido.itens = this.pedido.itens.filter(i => i !== row); }
    });
  }

  salvar(form: NgForm): void {
    if (form.invalid) { this.poNotification.warning('Preencha os campos do pedido.'); return; }
    // Validação: não permitir salvar sem pelo menos 1 item
    if (this.pedido.itens.length === 0) { this.poNotification.warning('Adicione pelo menos um item ao pedido.'); return; }
    this.loading = true;
    this.service.save(this.pedido).subscribe({
      next: () => { this.poNotification.success('Pedido gravado com sucesso.'); this.router.navigate(['/pedidos']); },
      error: () => { this.loading = false; this.poNotification.error('Erro ao gravar o pedido.'); }
    });
  }
}
```

**master-detail/pedido-form.component.html**
```html
<po-page-default p-title="Pedido" [p-breadcrumb]="breadcrumb">
  <po-widget p-title="Dados do pedido">
    <form #form="ngForm">
      <div class="po-row">
        <po-input class="po-md-4" name="numero" [(ngModel)]="pedido.numero" p-label="Número" p-required></po-input>
        <po-input class="po-md-4" name="clienteCodigo" [(ngModel)]="pedido.clienteCodigo" p-label="Cód. Cliente" p-required></po-input>
        <po-input class="po-md-4" name="clienteNome" [(ngModel)]="pedido.clienteNome" p-label="Cliente"></po-input>
      </div>
    </form>
  </po-widget>

  <po-widget p-title="Itens">
    <po-button p-label="Adicionar item" p-icon="an an-plus" p-kind="primary" (p-click)="adicionarItem()"></po-button>
    <po-table [p-columns]="itemColumns" [p-items]="pedido.itens" [p-actions]="itemActions" p-container></po-table>
  </po-widget>

  <po-button p-label="Salvar" p-kind="primary" p-icon="an an-floppy-disk" [p-loading]="loading" (p-click)="salvar(form)"></po-button>
  <po-button p-label="Cancelar" p-icon="an an-x" (p-click)="router.navigate(['/pedidos'])"></po-button>
</po-page-default>

<app-pedido-item-modal #itemModal (confirmar)="onItemConfirmado($event)"></app-pedido-item-modal>
```

---

### PADRÃO 5 — CRUD Dinâmico (Metadata-Driven)

**dynamic-crud/recurso.model.ts**
```typescript
import { PoPageDynamicTableActions } from '@po-ui/ng-templates';
export type { PoPageDynamicTableActions };
```

**dynamic-crud/recurso-list.component.ts**
```typescript
import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { PoBreadcrumb, PoModule } from '@po-ui/ng-components';
import {
  PoPageDynamicTableActions, PoPageDynamicTableCustomAction, PoTemplatesModule
} from '@po-ui/ng-templates';

@Component({
  selector: 'app-recurso-dyn-list',
  standalone: true,
  imports: [PoModule, PoTemplatesModule],
  templateUrl: './recurso-list.component.html'
})
export class RecursoDynListComponent {
  private router = inject(Router);
  readonly serviceApi = '/dts/datasul-rest/resources/prg/thl/v1/recursos';

  breadcrumb: PoBreadcrumb = { items: [{ label: 'THL' }, { label: 'Recursos' }] };

  // Rotas para navegação automática do template
  actions: PoPageDynamicTableActions = {
    new: '/recursos-dyn/new',
    edit: '/recursos-dyn/edit/:id',
    detail: '/recursos-dyn/detail/:id',
    remove: true,                    // habilita exclusão via serviceApi
    duplicate: '/recursos-dyn/new'   // ação de duplicar registro
  };

  // Ação customizada de página (ex.: exportar)
  pageCustomActions: PoPageDynamicTableCustomAction[] = [
    { label: 'Exportar', icon: 'an an-export', action: this.exportar.bind(this) }
  ];

  // Override de comportamento padrão: beforeRemove
  onBeforeRemove(resource: any) {
    // pode retornar { allowAction: boolean, newResource? } ou string (URL)
    return { allowAction: true };
  }

  exportar(): void { /* chamada de exportação */ }
}
```

**dynamic-crud/recurso-list.component.html**
```html
<po-page-dynamic-table
  p-title="Recursos"
  [p-breadcrumb]="breadcrumb"
  [p-service-api]="serviceApi"
  [p-actions]="actions"
  [p-page-custom-actions]="pageCustomActions"
  [p-fields]="[
    { property: 'id', key: true, visible: false },
    { property: 'codigo', label: 'Código', filter: true, gridColumns: 6 },
    { property: 'nome', label: 'Nome', filter: true, gridColumns: 6 },
    { property: 'valor', label: 'Valor', type: 'currency', format: 'BRL' },
    { property: 'status', label: 'Status', type: 'label',
      labels: [
        { value: 'ativo', label: 'Ativo', color: 'color-11' },
        { value: 'inativo', label: 'Inativo', color: 'color-07' }
      ] }
  ]">
</po-page-dynamic-table>
```

**dynamic-crud/recurso-detail.component.ts (+ template inline)**
```typescript
import { Component } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { PoTemplatesModule } from '@po-ui/ng-templates';

@Component({
  selector: 'app-recurso-dyn-detail',
  standalone: true,
  imports: [PoModule, PoTemplatesModule],
  template: `
    <po-page-dynamic-detail
      p-title="Detalhe do recurso"
      p-service-api="/dts/datasul-rest/resources/prg/thl/v1/recursos"
      [p-fields]="[
        { property: 'codigo', label: 'Código' },
        { property: 'nome', label: 'Nome' },
        { property: 'valor', label: 'Valor', type: 'currency' },
        { property: 'status', label: 'Status', tag: true }
      ]">
    </po-page-dynamic-detail>`
})
export class RecursoDynDetailComponent {}
```

**dynamic-crud/recurso-edit.component.ts (+ template inline)**
```typescript
import { Component } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { PoTemplatesModule, PoPageDynamicEditActions } from '@po-ui/ng-templates';

@Component({
  selector: 'app-recurso-dyn-edit',
  standalone: true,
  imports: [PoModule, PoTemplatesModule],
  template: `
    <po-page-dynamic-edit
      p-title="Recurso"
      p-service-api="/dts/datasul-rest/resources/prg/thl/v1/recursos"
      [p-actions]="actions"
      [p-fields]="[
        { property: 'id', key: true, visible: false },
        { property: 'codigo', label: 'Código', required: true, gridColumns: 6 },
        { property: 'nome', label: 'Nome', required: true, gridColumns: 6 },
        { property: 'valor', label: 'Valor', type: 'currency', gridColumns: 4 }
      ]">
    </po-page-dynamic-edit>`
})
export class RecursoDynEditComponent {
  actions: PoPageDynamicEditActions = {
    save: '/recursos-dyn',
    saveNew: '/recursos-dyn/new'
    // beforeSave: pode ser URL ou função retornando { allowAction, newResource }
  };
}
```

**dynamic-crud/dynamic-crud-routing.module.ts**
```typescript
import { Routes } from '@angular/router';
export const dynamicCrudRoutes: Routes = [
  { path: '', loadComponent: () => import('./recurso-list.component').then(m => m.RecursoDynListComponent) },
  { path: 'new', loadComponent: () => import('./recurso-edit.component').then(m => m.RecursoDynEditComponent) },
  { path: 'edit/:id', loadComponent: () => import('./recurso-edit.component').then(m => m.RecursoDynEditComponent) },
  { path: 'detail/:id', loadComponent: () => import('./recurso-detail.component').then(m => m.RecursoDynDetailComponent) }
];
```

**JSON de metadata que a API deve retornar** — endpoint `GET {end-point}/metadata?type=list&version={version}`, formato oficial `PoPageDynamicTableMetadata`:
```json
{
  "version": 1,
  "title": "Recursos THL",
  "fields": [
    { "property": "id", "key": true, "visible": false },
    { "property": "codigo", "label": "Código", "filter": true, "gridColumns": 6 },
    { "property": "nome", "label": "Nome", "filter": true, "gridColumns": 6 },
    { "property": "valor", "label": "Valor", "type": "currency", "format": "BRL" },
    { "property": "status", "label": "Status", "type": "label",
      "labels": [
        { "value": "ativo", "label": "Ativo", "color": "color-11" },
        { "value": "inativo", "label": "Inativo", "color": "color-07" }
      ] }
  ],
  "keepFilters": true
}
```

> **Fonte:** documentação oficial do `po-page-dynamic-table` — metadata `{ version, title, fields, keepFilters }` e requisição automática `GET {end-point}/metadata?type=list&version={version}` — e do `po-page-dynamic-edit` (ações `beforeSave`/`beforeSaveNew`/`beforeCancel`).

---

### PADRÃO 6 — Consulta com Filtros Avançados (somente leitura)

**consulta/consulta.model.ts**
```typescript
export interface ConsultaFiltro {
  dataInicial?: string;
  dataFinal?: string;
  status?: string[];
  texto?: string;
}
export interface ConsultaItem {
  documento: string;
  data: string;
  status: string;
  valor: number;
}
export interface ConsultaResultado {
  items: ConsultaItem[];
  hasNext: boolean;
  totalRegistros: number;
  somaValores: number;
}
```

**consulta/consulta.service.ts**
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ConsultaFiltro, ConsultaResultado } from './consulta.model';

@Injectable({ providedIn: 'root' })
export class ConsultaService {
  private http = inject(HttpClient);
  private readonly api = '/dts/datasul-rest/resources/prg/thl/v1/consulta-movimentos';

  consultar(f: ConsultaFiltro, page = 1, pageSize = 50): Observable<ConsultaResultado> {
    let params = new HttpParams().set('page', page).set('pageSize', pageSize);
    if (f.dataInicial) params = params.set('dataInicial', f.dataInicial);
    if (f.dataFinal) params = params.set('dataFinal', f.dataFinal);
    if (f.texto) params = params.set('texto', f.texto);
    (f.status ?? []).forEach(s => params = params.append('status', s));
    return this.http.get<ConsultaResultado>(this.api, { params });
  }
}
```

**consulta/consulta.component.ts**
```typescript
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  PoBreadcrumb, PoPageAction, PoTableColumn, PoDisclaimer, PoDisclaimerGroup,
  PoNotificationService, PoModule
} from '@po-ui/ng-components';
import { ConsultaService } from './consulta.service';
import { ConsultaFiltro, ConsultaItem } from './consulta.model';

@Component({
  selector: 'app-consulta',
  standalone: true,
  imports: [PoModule, FormsModule],
  templateUrl: './consulta.component.html'
})
export class ConsultaComponent {
  private service = inject(ConsultaService);
  private poNotification = inject(PoNotificationService);

  filtro: ConsultaFiltro = {};
  periodo: string[] = [];      // po-datepicker-range → [inicio, fim]
  items: ConsultaItem[] = [];
  loading = false;

  totalRegistros = 0;
  somaValores = 0;

  breadcrumb: PoBreadcrumb = { items: [{ label: 'THL' }, { label: 'Consulta de movimentos' }] };

  statusOptions = [
    { label: 'Aberto', value: 'aberto' },
    { label: 'Faturado', value: 'faturado' },
    { label: 'Cancelado', value: 'cancelado' }
  ];

  // Exportar resultados (ação no header)
  pageActions: PoPageAction[] = [
    { label: 'Exportar', icon: 'an an-export', action: () => this.exportar() }
  ];

  disclaimerGroup: PoDisclaimerGroup = {
    title: 'Filtros', disclaimers: [],
    change: (d: PoDisclaimer[]) => { this.disclaimerGroup.disclaimers = d; }
  };

  columns: PoTableColumn[] = [
    { property: 'documento', label: 'Documento' },
    { property: 'data', label: 'Data', type: 'date', format: 'dd/MM/yyyy' },
    { property: 'status', label: 'Status', type: 'subtitle',
      subtitles: [
        { value: 'aberto', label: 'Aberto', color: 'color-08', content: 'A' },
        { value: 'faturado', label: 'Faturado', color: 'color-11', content: 'F' },
        { value: 'cancelado', label: 'Cancelado', color: 'color-07', content: 'C' }
      ] },
    { property: 'valor', label: 'Valor', type: 'currency', format: 'BRL' }
  ];

  consultar(): void {
    this.filtro.dataInicial = this.periodo?.[0];
    this.filtro.dataFinal = this.periodo?.[1];
    this.montarDisclaimers();
    this.loading = true;
    this.service.consultar(this.filtro).subscribe({
      next: (r) => {
        this.items = r.items;
        this.totalRegistros = r.totalRegistros;
        this.somaValores = r.somaValores;
        this.loading = false;
      },
      error: () => { this.loading = false; this.poNotification.error('Erro na consulta.'); }
    });
  }

  private montarDisclaimers(): void {
    const d: PoDisclaimer[] = [];
    if (this.filtro.dataInicial) d.push({ property: 'periodo', label: `Período: ${this.filtro.dataInicial} a ${this.filtro.dataFinal}`, value: 'periodo' });
    if (this.filtro.texto) d.push({ property: 'texto', label: `Texto: ${this.filtro.texto}`, value: this.filtro.texto });
    (this.filtro.status ?? []).forEach(s => d.push({ property: 'status', label: `Status: ${s}`, value: s }));
    this.disclaimerGroup.disclaimers = d;
  }

  private exportar(): void { /* geração de arquivo / chamada RPW */ }
}
```

**consulta/consulta.component.html**
```html
<po-page-default p-title="Consulta de movimentos" [p-breadcrumb]="breadcrumb" [p-actions]="pageActions">
  <po-widget p-title="Filtros">
    <form>
      <div class="po-row">
        <po-datepicker-range class="po-md-4" name="periodo" [(ngModel)]="periodo" p-label="Período"></po-datepicker-range>
        <po-multiselect class="po-md-4" name="status" [(ngModel)]="filtro.status" p-label="Status" [p-options]="statusOptions"></po-multiselect>
        <po-input class="po-md-4" name="texto" [(ngModel)]="filtro.texto" p-label="Texto livre"></po-input>
      </div>
      <po-button p-label="Consultar" p-kind="primary" p-icon="an an-magnifying-glass" [p-loading]="loading" (p-click)="consultar()"></po-button>
    </form>
  </po-widget>

  <po-disclaimer-group
    [p-title]="disclaimerGroup.title"
    [p-disclaimers]="disclaimerGroup.disclaimers"
    (p-change)="disclaimerGroup.change!($event)">
  </po-disclaimer-group>

  <po-widget>
    <div class="po-row">
      <po-info class="po-md-3" p-label="Total de registros" [p-value]="totalRegistros"></po-info>
      <po-info class="po-md-3" p-label="Soma dos valores" [p-value]="somaValores | currency:'BRL'"></po-info>
    </div>
    <po-table [p-columns]="columns" [p-items]="items" [p-loading]="loading" p-container [p-striped]="true"></po-table>
  </po-widget>
</po-page-default>
```

---

### PADRÃO 7 — Cadastro Multi-Seção com Abas

**tabbed-form/cadastro.model.ts**
```typescript
export interface CadastroCompleto {
  dadosGerais: { codigo: string; nome: string; tipo: string };
  endereco: { cep: string; logradouro: string; cidade: string; uf: string };
  contatos: { email: string; telefone: string };
  configuracoes: { ativo: boolean; perfil: string };
}
```

**tabbed-form/cadastro-tabs.component.ts**
```typescript
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PoBreadcrumb, PoNotificationService, PoModule } from '@po-ui/ng-components';
import { Router } from '@angular/router';
import { CadastroCompleto } from './cadastro.model';
import { DadosGeraisComponent } from './tabs/dados-gerais.component';
import { EnderecoComponent } from './tabs/endereco.component';
import { ContatosComponent } from './tabs/contatos.component';
import { ConfiguracoesComponent } from './tabs/configuracoes.component';

@Component({
  selector: 'app-cadastro-tabs',
  standalone: true,
  imports: [PoModule, FormsModule, DadosGeraisComponent, EnderecoComponent, ContatosComponent, ConfiguracoesComponent],
  templateUrl: './cadastro-tabs.component.html'
})
export class CadastroTabsComponent {
  private poNotification = inject(PoNotificationService);
  private router = inject(Router);

  model: CadastroCompleto = {
    dadosGerais: { codigo: '', nome: '', tipo: '' },
    endereco: { cep: '', logradouro: '', cidade: '', uf: '' },
    contatos: { email: '', telefone: '' },
    configuracoes: { ativo: true, perfil: '' }
  };

  loading = false;
  breadcrumb: PoBreadcrumb = { items: [{ label: 'THL' }, { label: 'Cadastro' }] };

  // Indica visualmente aba com erro (usar em p-label ou badge da aba)
  get abaGeraisInvalida(): boolean { return !this.model.dadosGerais.codigo || !this.model.dadosGerais.nome; }
  get abaEnderecoInvalida(): boolean { return !this.model.endereco.cep; }

  // Um único Salvar grava TODOS os dados de todas as abas
  salvar(): void {
    if (this.abaGeraisInvalida || this.abaEnderecoInvalida) {
      this.poNotification.warning('Existem abas com campos obrigatórios pendentes.');
      return;
    }
    this.loading = true;
    // this.service.save(this.model).subscribe(...) — envia o objeto completo
    this.poNotification.success('Cadastro gravado com sucesso.');
    this.loading = false;
    this.router.navigate(['/cadastros']);
  }
}
```

**tabbed-form/cadastro-tabs.component.html**
```html
<po-page-default p-title="Cadastro" [p-breadcrumb]="breadcrumb">
  <po-tabs>
    <po-tab p-label="Dados Gerais" [p-active]="true">
      <app-dados-gerais [(model)]="model.dadosGerais"></app-dados-gerais>
    </po-tab>
    <po-tab p-label="Endereço">
      <app-endereco [(model)]="model.endereco"></app-endereco>
    </po-tab>
    <po-tab p-label="Contatos">
      <app-contatos [(model)]="model.contatos"></app-contatos>
    </po-tab>
    <po-tab p-label="Configurações">
      <app-configuracoes [(model)]="model.configuracoes"></app-configuracoes>
    </po-tab>
  </po-tabs>

  <po-button p-label="Salvar" p-kind="primary" p-icon="an an-floppy-disk" [p-loading]="loading" (p-click)="salvar()"></po-button>
</po-page-default>
```

**tabbed-form/tabs/dados-gerais.component.ts** (os demais seguem o mesmo modelo Input/Output)
```typescript
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PoModule } from '@po-ui/ng-components';

@Component({
  selector: 'app-dados-gerais',
  standalone: true,
  imports: [PoModule, FormsModule],
  template: `
    <form>
      <div class="po-row">
        <po-input class="po-md-4" name="codigo" [(ngModel)]="model.codigo" (ngModelChange)="emit()" p-label="Código" p-required></po-input>
        <po-input class="po-md-8" name="nome" [(ngModel)]="model.nome" (ngModelChange)="emit()" p-label="Nome" p-required></po-input>
        <po-select class="po-md-4" name="tipo" [(ngModel)]="model.tipo" (ngModelChange)="emit()" p-label="Tipo"
          [p-options]="[{label:'Interno',value:'I'},{label:'Externo',value:'E'}]"></po-select>
      </div>
    </form>`
})
export class DadosGeraisComponent {
  @Input() model!: { codigo: string; nome: string; tipo: string };
  @Output() modelChange = new EventEmitter<any>();
  emit(): void { this.modelChange.emit(this.model); }
}
```

**tabbed-form/tabs/endereco.component.ts** (com lookup/busca de CEP — dependência entre abas)
```typescript
import { Component, Input, Output, EventEmitter, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { PoModule } from '@po-ui/ng-components';

@Component({
  selector: 'app-endereco',
  standalone: true,
  imports: [PoModule, FormsModule],
  template: `
    <form>
      <div class="po-row">
        <po-input class="po-md-3" name="cep" [(ngModel)]="model.cep" p-label="CEP" p-mask="99999-999" (p-blur)="buscarCep()"></po-input>
        <po-input class="po-md-6" name="logradouro" [(ngModel)]="model.logradouro" p-label="Logradouro"></po-input>
        <po-input class="po-md-3" name="cidade" [(ngModel)]="model.cidade" p-label="Cidade"></po-input>
      </div>
    </form>`
})
export class EnderecoComponent {
  private http = inject(HttpClient);
  @Input() model!: { cep: string; logradouro: string; cidade: string; uf: string };
  @Output() modelChange = new EventEmitter<any>();

  buscarCep(): void {
    // Lookup por CEP; preenche logradouro/cidade e reemite o model
    if (this.model.cep?.length >= 8) {
      // this.http.get(...).subscribe(dados => { this.model.logradouro = dados.logradouro; this.modelChange.emit(this.model); });
    }
  }
}
```

> Os componentes `contatos.component.ts` e `configuracoes.component.ts` seguem exatamente o mesmo padrão (Input/Output `model`/`modelChange`, `po-input`/`po-switch`). O botão único **Salvar** consolida `this.model` (todas as abas) em uma chamada. A validação por aba pode ser refletida no `p-label` da `po-tab` (ex.: acrescentar um marcador quando `abaXInvalida` for verdadeiro).

---

## SEÇÃO 12 — ICONS.md

### 12.1 Ícones do PO-UI (Animalia)
- **Status atual (v21.x):** a biblioteca POIcon (`po-icon-*`) foi **depreciada e removida na v21.x.x**. O guia oficial de *deprecations* do po-angular registra: "A partir da v21, a biblioteca de ícones POIcon foi removida. O conjunto padrão de ícones passa a ser a lib Animalia Icons". A recomendação oficial é a **Animalia Icons**, prefixo `an an-<nome>`.
- **Uso em componente PO:** `p-icon="an an-user"`. Ex. verbatim da doc: `<po-input p-icon="an an-user" p-label="PO input"></po-input>`. Também: `<po-button p-icon="an an-floppy-disk" p-label="Salvar"></po-button>`.
- **Uso via classe CSS** (elemento `<i>`): `<i class="an an-user"></i>`. Variante preenchida (fill): `<i class="an-fill an-user"></i>`.
- **Migração POIcon → Animalia** (exemplo verbatim do `deprecations.md`): `<i class="po-icon po-icon-user"></i>` → `<i class="an an-user"></i>`.
- **Uso via TemplateRef** (ícone customizado):
  ```html
  <po-input [p-icon]="template" p-label="input template"></po-input>
  <ng-template #template><i class="an an-arrow-fat-line-down"></i></ng-template>
  ```
- **Instalação:** `npm i @animaliads/animalia-icon`.
- **Prefixos legados:**
  - `po-icon-*` → **removido na v21.x**; não funciona.
  - `ph ph-*` (Phosphor) → prefixo intermediário; a Animalia herda a convenção de nomes do Phosphor (kebab-case), mas o prefixo atual é `an`. Em projetos v21, usar `an an-*`.
- **Categorias** (navegador de ícones em po-ui.io/icons — SPA): ação (plus, pencil-simple, trash, floppy-disk), navegação (arrow-left, caret-*, list), status/feedback (check, warning, x-circle, info), arquivo (file-*, folder-*, download, upload), comunicação (envelope, chat, phone), usuário (user, user-circle), dados/ERP (table, warehouse, credit-card, calendar-*).

### 12.2 Ícones externos (Font Awesome / Phosphor)
- **Sim, o PO-UI suporta ícones externos.** Fonte oficial (comentários de `po-modal`/`po-input`/`po-button`): "Também é possível utilizar outras fontes de ícones, por exemplo a biblioteca Font Awesome".
- **Font Awesome:** incluir o CSS no `index.html` e usar o prefixo `fa`:
  ```html
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" crossorigin="anonymous" />
  ```
  ```html
  <po-button p-icon="fa fa-check-circle" p-label="Confirm"></po-button>
  ```
- **Phosphor:** pode ser incluído do mesmo modo (webfont, prefixo `ph ph-*`) ou via `@fortawesome/angular-fontawesome` como componente Angular. **Recomendação:** como o PO-UI 21 já embarca a Animalia (que usa a convenção Phosphor), prefira `an an-*` e reserve fontes externas para ícones inexistentes na Animalia.

### 12.3 Mapeamento ação → ícone (ERP)
Nomes base confirmados no catálogo Phosphor (do qual a Animalia deriva a convenção; prefixar com `an `). Onde havia equivalente aproximado na antiga POIcon, indicado como referência de migração.

| Ação | Animalia (atual) | Legado POIcon (removido v21) |
|------|------------------|------------------------------|
| Novo/Criar | `an an-plus` (ou `an an-plus-circle`) | `po-icon-plus` |
| Editar | `an an-pencil-simple` | `po-icon-edit` |
| Excluir | `an an-trash` | `po-icon-delete` |
| Visualizar/Detalhe | `an an-eye` | `po-icon-eye` |
| Buscar/Pesquisar | `an an-magnifying-glass` | `po-icon-search` |
| Filtrar | `an an-funnel` | `po-icon-filter` |
| Salvar | `an an-floppy-disk` | *(sem ícone dedicado 1:1)* |
| Cancelar/Fechar | `an an-x` (ou `an an-x-circle`) | `po-icon-close` |
| Voltar | `an an-arrow-left` (ou `an an-caret-left`) | `po-icon-arrow-left` |
| Atualizar/Refresh | `an an-arrows-clockwise` (ou `an an-arrow-clockwise`) | `po-icon-refresh` |
| Exportar | `an an-export` | `po-icon-export` |
| Imprimir | `an an-printer` | `po-icon-print` |
| Configurações | `an an-gear` (ou `an an-gear-six`) | `po-icon-settings` |
| Duplicar/Copiar | `an an-copy` (ou `an an-copy-simple`) | `po-icon-copy` |
| Download | `an an-download` (ou `an an-download-simple`) | `po-icon-download` |
| Upload | `an an-upload` (ou `an an-upload-simple`) | `po-icon-upload` |
| Expandir/Colapsar | `an an-caret-down` / `an an-caret-up` / `an an-caret-right` | `po-icon-arrow-down`/`-up` |
| Usuário/Perfil | `an an-user` (ou `an an-user-circle`) | `po-icon-user` |

> Os nomes base (`plus`, `pencil-simple`, `trash`, `magnifying-glass`, `funnel`, `floppy-disk`, `x`, `arrow-left`, `arrows-clockwise`, `export`, `printer`, `gear`, `copy`, `download`, `upload`, `caret-*`, `user`) são todos ícones padrão do Phosphor. `an an-plus`, `an an-pencil-simple` e `an an-trash` estão **confirmados em código-fonte oficial** do po-angular. Os demais são altamente prováveis na Animalia (mesma convenção), mas devem ser confirmados no navegador de ícones antes do uso em produção. Os nomes `po-icon-*` servem apenas como mapa de migração — não funcionam na v21.

---

## REFERÊNCIA RÁPIDA — Componentes por categoria

| Categoria | Componente | Quando usar |
|-----------|-----------|-------------|
| Input texto | `po-input` | Texto livre; suporta `p-mask` (CPF/CNPJ/telefone) e `p-icon` |
| Input número inteiro | `po-number` | Quantidades, inteiros |
| Input decimal/moeda | `po-decimal` | Valores monetários/decimais (`p-decimals-length`) |
| Senha | `po-password` | Campos de senha |
| Área de texto | `po-textarea` | Observações, textos longos |
| Rich text | `po-rich-text` | Conteúdo formatado (HTML) |
| Seleção única (poucas) | `po-radio-group` | ≤3 opções, escolha única |
| Seleção múltipla (poucas) | `po-checkbox-group` | ≤3 opções, múltipla |
| Combo estático | `po-select` | Lista fixa, escolha única |
| Combo com busca/API | `po-combo` | Carga dinâmica via `p-filter-service`/muitas opções |
| Seleção múltipla | `po-multiselect` | Múltiplos valores (ex.: filtro de status) |
| Lookup/Zoom | `po-lookup` | Campo relacionado com modal (`p-filter-service`, `p-columns`, `p-advanced-filters`) |
| Liga/desliga | `po-switch` | Booleano com rótulo on/off |
| Checkbox único | `po-checkbox` | Aceite/flag isolado |
| Data | `po-datepicker` | Data única |
| Período | `po-datepicker-range` | Intervalo de datas (`[inicio, fim]`) |
| Arquivo | `po-upload` | Upload de arquivos |
| Exibição leitura | `po-info` | Par label/valor somente leitura; totalizadores |
| Exibição dinâmica | `po-dynamic-view` | Detalhe orientado a metadados (`p-fields`, `p-value`) |
| Formulário dinâmico | `po-dynamic-form` | Form gerado de `PoDynamicFormField[]` |
| Tabela | `po-table` | Colunas tipadas, ações, `p-show-more` (paginação), `type: 'label'` |
| Lista visual | `po-list-view` | Cards/itens com layout customizado |
| Página com filtro | `po-page-list` | Listagem com busca + disclaimers + ações |
| Página padrão | `po-page-default` | Formulário/detalhe com breadcrumb e ações |
| Página edição | `po-page-edit` | Formulário com ações Salvar/Cancelar padronizadas |
| Tabela dinâmica | `po-page-dynamic-table` | CRUD list metadata-driven (`p-service-api`) |
| Edição dinâmica | `po-page-dynamic-edit` | Create/edit metadata-driven |
| Detalhe dinâmico | `po-page-dynamic-detail` | Visualização metadata-driven |
| Busca dinâmica | `po-page-dynamic-search` | Filtros avançados metadata-driven |
| Navegação | `po-menu` | Menu lateral |
| Navegação | `po-breadcrumb` | Trilha de navegação |
| Navegação | `po-tabs`/`po-tab` | Cadastro/detalhe multi-seção |
| Navegação | `po-toolbar` | Barra superior |
| Navegação | `po-stepper` | Fluxo em etapas |
| Modal | `po-modal` | Diálogos, form de item (`p-primary-action`/`p-secondary-action`) |
| Modal | `po-page-slide` | Painel lateral deslizante |
| Feedback | `po-notification` (service) | Toasts de sucesso/erro/aviso/info |
| Feedback | `po-dialog` (service) | Confirmação/alerta (`.confirm()`, `.alert()`) |
| Feedback | `po-loading` / `po-loading-overlay` | Indicadores de carregamento |
| Feedback | `po-disclaimer` / `po-disclaimer-group` | Chips de filtros ativos |
| Layout | `po-widget` | Agrupador visual (card) de conteúdo |
| Status | `po-tag` | Etiquetas de status coloridas |

---

## Recommendations
1. **Fase 1 (padrão base):** adote os Padrões 1 (list) + 2 (form) + 3 (detail) como esqueleto de todo cadastro THL — cobrem a grande maioria das telas. Use as rotas `/recurso`, `/recurso/new`, `/recurso/edit/:id`, `/recurso/detail/:id`.
2. **Fase 2 (produtividade):** para cadastros simples e homogêneos, avalie o Padrão 5 (dinâmico) — reduz drasticamente código, mas exige backend que exponha `/metadata`. **Critério de decisão:** se a tela tem regras de UI específicas (lookups encadeados, validações condicionais, layout fora do padrão), use o CRUD manual (Padrões 1–4); se é CRUD "chapa" sobre uma entidade, use o dinâmico.
3. **Ícones:** crie um `icons.constants.ts` centralizando as constantes `an an-*` da tabela 12.3; nunca use `po-icon-*` (quebra na v21). Confirme nomes menos comuns no navegador de po-ui.io/icons antes de codar.
4. **Master-detail (Padrão 4):** mantenha itens em memória e grave mestre+itens numa única chamada; valide ≥1 item antes de habilitar Salvar.
5. **Confirmação de saída (Padrão 2/7):** implemente o guard de "alterações não salvas" via snapshot JSON; para robustez, evolua para `CanDeactivate`.
6. **Threshold de revisão:** ao subir de minor (ex.: 21.x → 21.y), revalide os nomes de propriedades de coluna/field (`subtitles`, `tag`, `gridColumns`) contra a documentação da versão instalada antes de gerar telas em massa.

## Caveats
- A página `po-ui.io/icons` e várias páginas de documentação são SPA (renderizadas por JS); parte do conteúdo foi confirmada via **código-fonte do repositório po-angular** e via snippets de busca, não pelo HTML renderizado.
- A **derivação Animalia→Phosphor é inferida** (mesma convenção kebab-case, mesmo mecanismo de webfont, exemplos idênticos como `an an-user`/`ph ph-user`), **não** uma afirmação textual explícita na doc da Animalia. Os nomes base (`plus`, `pencil-simple`, `trash`, etc.) são padrão Phosphor; `an an-plus`, `an an-pencil-simple`, `an an-trash` estão confirmados em código PO-UI. Nomes específicos além desses devem ser verificados antes de produção.
- **Não foi encontrada fonte oficial** declarando o número total de ícones da Animalia (a doc apenas remete à comunidade Figma); portanto nenhuma contagem é afirmada aqui.
- Alguns detalhes de API de componentes (nomes exatos como `subtitles`, `tag`, `gridColumns`, `p-decimals-length`) podem variar levemente entre minors da 21.x; validar contra a documentação da versão exata instalada.
- Os exemplos de código são **construção própria baseada nas APIs oficiais documentadas** e na estrutura do `crud-po-ui-workshop`; **não** são cópia literal de um único repositório. Endpoints (`/dts/datasul-rest/...`) são ilustrativos e devem ser ajustados aos recursos THL reais. O tratamento de `hasNext` no `po-table` usa `p-show-more`/`p-show-more-disabled` para a paginação "carregar mais" server-side.
- A tabela 12.3 lista nomes `po-icon-*` legados apenas como mapa de migração; alguns são aproximados, pois a POIcon não tinha correspondência 1:1 para todas as ações (ex.: "Salvar").
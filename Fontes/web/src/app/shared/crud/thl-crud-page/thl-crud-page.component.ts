import { ChangeDetectionStrategy, ChangeDetectorRef, Component, DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { PoDisclaimer, PoDisclaimerGroup } from '@po-ui/ng-components';
import { PoModule } from '@po-ui/ng-components';
import { ThlPageHeaderComponent } from '../../components/thl-page-header';
import { ThlSearchBarComponent } from '../../components/thl-search-bar';
import { CrudResource } from '../crud.model';
import { ThlCrudChildrenComponent } from '../thl-crud-children/thl-crud-children.component';
import { ThlCrudListComponent } from '../thl-crud-list/thl-crud-list.component';

/** Página de cadastro genérica: a definição vem em `data: { def }` da rota. */
@Component({
  selector: 'thl-crud-page',
  standalone: true,
  imports: [PoModule, ThlPageHeaderComponent, ThlSearchBarComponent, ThlCrudListComponent, ThlCrudChildrenComponent],
  templateUrl: './thl-crud-page.component.html',
  styleUrls: ['../../styles/thl-browse.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlCrudPageComponent {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);
  private destroyRef = inject(DestroyRef);

  readonly def: CrudResource = this.route.snapshot.data['def'];
  termo = '';
  total: number | null = null;

  /** Filtro vindo da URL (`?aplicacao=THL`), usado no GET. Vazio = lista inteira. */
  filtroUrl: Record<string, string> = {};

  /** Mostra o filtro da URL: lista filtrada sem aviso engana. O "x" do po-disclaimer
   *  tira a tag da tela mas não dispara `p-change` aqui, então o fecha vem do botão ao lado. */
  readonly disclaimers: PoDisclaimerGroup = {
    title: 'Filtro',
    disclaimers: []
  };

  constructor() {
    // queryParams como fluxo: entrar pelo menu depois de um atalho precisa limpar o filtro.
    this.route.queryParams.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(params => {
      this.filtroUrl = { ...params } as Record<string, string>;
      this.disclaimers.disclaimers = Object.entries(this.filtroUrl).map(([campo, valor]) => ({
        property: campo,
        value: valor,
        label: `${this.rotulo(campo)}: ${valor}`,
        hideClose: true
      }));
      // OnPush: a emissão do queryParams não marca este componente sozinha.
      this.cdr.markForCheck();
    });
  }

  private rotulo(campo: string): string {
    return this.def.fields.find(f => f.property === campo)?.label ?? campo;
  }

  limparFiltro(): void {
    this.router.navigate([], { relativeTo: this.route, queryParams: {} });
  }

  /** Subtítulo com o contador, para o usuário saber o tamanho da lista sem rolar. */
  get subtitulo(): string {
    const base = this.def.subtitle ?? '';
    if (this.total === null) return base;
    const registros = this.total === 1 ? '1 registro' : `${this.total} registros`;
    return base ? `${base} · ${registros}` : registros;
  }

  get dica(): string {
    const abas = (this.def.children ?? []).map(f => f.title.toLowerCase()).join(', ');
    return `Clique na seta da linha para ver: ${abas}.`;
  }
}

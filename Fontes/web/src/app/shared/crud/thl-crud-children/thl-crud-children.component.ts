import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { CrudResource, CrudRow } from '../crud.model';
import { ThlCrudListComponent } from '../thl-crud-list/thl-crud-list.component';

/** Card da linha expandida: título do pai e uma aba por recurso filho. */
@Component({
  selector: 'thl-crud-children',
  standalone: true,
  imports: [PoModule, ThlCrudListComponent],
  templateUrl: './thl-crud-children.component.html',
  styleUrls: ['../../styles/thl-detalhe.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlCrudChildrenComponent {
  @Input({ required: true }) def!: CrudResource;
  @Input({ required: true }) row!: CrudRow;

  abaAtiva = 0;
  totais: Record<number, number> = {};

  get titulo(): string {
    return String(this.row[this.def.titleField ?? ''] ?? this.chave);
  }

  get chave(): string {
    return this.def.fields.filter(f => f.key).map(f => this.row[f.property]).join(' / ');
  }

  rotulo(filho: CrudResource, i: number): string {
    // Aba de registro único não mostra contador.
    return filho.single || this.totais[i] === undefined ? filho.title : `${filho.title} (${this.totais[i]})`;
  }
}

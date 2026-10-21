import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  Output
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { PoModule } from '@po-ui/ng-components';

export interface ThlFilterTab {
  value: string;
  label: string;
  /** Desenha o número dentro de um cronômetro ou calendário, em vez do texto.
   *  O `label` continua obrigatório: vira tooltip e `aria-label`. */
  glifo?: { forma: 'timer' | 'calendario'; valor: string };
  /** Ícone da fonte Animalia **no lugar** do texto (`Personalizado` do período). */
  icone?: string;
  /** Texto do tooltip e do `aria-label` quando a opção é só ícone. Sem ele, vale o `label`. */
  tooltip?: string;
}

@Component({
  selector: 'thl-filter-tabs',
  standalone: true,
  imports: [CommonModule, PoModule],
  templateUrl: './thl-filter-tabs.component.html',
  styleUrls: ['./thl-filter-tabs.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlFilterTabsComponent {

  /** Rótulo fixo à esquerda das opções. Com ele, a barra diz do que trata sem
   *  depender de hover — que não existe em toque. Vira também o nome do grupo
   *  para o leitor de tela. */
  @Input() rotulo = '';
  @Input() rotuloIcone = '';

  @Input() options: ThlFilterTab[] = [];
  @Input() selected: string = '';
  @Input() showRefresh: boolean = false;

  @Output() selectedChange = new EventEmitter<string>();
  @Output() refresh = new EventEmitter<void>();

  onSelect(value: string): void {
    if (value === this.selected) return;
    this.selected = value;
    this.selectedChange.emit(value);
  }

  onRefresh(): void {
    this.refresh.emit();
  }
}

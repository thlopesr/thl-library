import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';

// Botão de alternar só com ícone, no mesmo visual dos atalhos de período:
// reaproveita o stylesheet do `thl-filter-tabs` em vez de copiar as regras, para
// os dois não divergirem (as classes `.thl-filter-tab*` vêm de lá).
//
// Fundo sempre branco, sem estado de seleção: o escuro é dos atalhos de período, e um
// botão que se acende no meio deles pareceria mais um atalho escolhido. **O ícone mostra
// o estado** e o **tooltip diz a ação**; `aria-pressed` leva o estado a quem não vê o ícone.
// Sem rótulo visível, o tooltip e o `aria-label` são a única descrição — por isso obrigatórios.
@Component({
  selector: 'thl-icon-toggle',
  standalone: true,
  imports: [PoModule],
  templateUrl: './thl-icon-toggle.component.html',
  styleUrls: ['../thl-filter-tabs/thl-filter-tabs.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlIconToggleComponent {
  @Input() ativo = false;

  /** Ícone do estado ligado e do desligado. */
  @Input() icone = 'an an-eye';
  @Input() iconeInativo = 'an an-eye-slash';

  /** O que o clique faz — texto do tooltip e do `aria-label`, nunca o estado atual. */
  @Input({ required: true }) rotuloLigar!: string;
  @Input({ required: true }) rotuloDesligar!: string;

  @Output() ativoChange = new EventEmitter<boolean>();

  get rotulo(): string {
    return this.ativo ? this.rotuloDesligar : this.rotuloLigar;
  }

  alternar(): void {
    this.ativoChange.emit(!this.ativo);
  }
}

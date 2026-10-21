import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnChanges, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PoModule } from '@po-ui/ng-components';
import { ThlFilterTabsComponent } from '../thl-filter-tabs';
import { ATALHOS_PERIODO, FaixaPeriodo, PeriodoAtalho, faixaDoAtalho, formatarDataHora } from '../../domain/periodo';

// Período das telas de métricas: atalhos para o caminho comum e faixa com hora
// para investigar incidente. Só as rotas de métricas aceitam hora no filtro.
@Component({
  selector: 'thl-period-filter',
  standalone: true,
  imports: [FormsModule, PoModule, ThlFilterTabsComponent],
  templateUrl: './thl-period-filter.component.html',
  styleUrls: ['./thl-period-filter.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlPeriodFilterComponent implements OnChanges {
  @Input() atalho: PeriodoAtalho = '24h';
  @Output() faixaChange = new EventEmitter<{ atalho: PeriodoAtalho; faixa: FaixaPeriodo }>();
  @Output() refresh = new EventEmitter<void>();

  readonly opcoes = ATALHOS_PERIODO;

  /** `datetime-local` usa o mesmo formato do backend: `yyyy-MM-ddTHH:mm`. */
  ini = '';
  fin = '';
  erro = '';

  /** Os campos nascem no período em uso: abrir em 7d e ver 24h nos campos induz a encurtar sem querer. */
  ngOnChanges(): void {
    if (this.atalho === 'personalizado') return;
    const faixa = faixaDoAtalho(this.atalho);
    this.ini = faixa.ini;
    this.fin = faixa.fin;
  }

  onAtalho(valor: string): void {
    this.atalho = valor as PeriodoAtalho;
    this.erro = '';
    if (this.atalho === 'personalizado') {
      return;
    }
    const faixa = faixaDoAtalho(this.atalho);
    this.ini = faixa.ini;
    this.fin = faixa.fin;
    this.faixaChange.emit({ atalho: this.atalho, faixa });
  }

  aplicarFaixa(): void {
    if (!this.ini || !this.fin) {
      this.erro = 'Informe o início e o fim do período.';
      return;
    }
    if (this.ini > this.fin) {
      this.erro = 'O início precisa ser anterior ao fim.';
      return;
    }
    this.erro = '';
    this.faixaChange.emit({ atalho: 'personalizado', faixa: { ini: this.ini, fin: this.fin } });
  }
}

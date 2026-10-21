import { Component, EventEmitter, Output, ViewChild, ElementRef, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PoModalComponent, PoModalAction, PoModule } from '@po-ui/ng-components';
import { AuditoriaFiltro } from '../../models/auditoria.model';
import { AtalhoData, FaixaPeriodo, faixaDoAtalhoData, mesmaDataHora, paraFaixa, textoDigitadoParaFaixa } from '../../../shared/domain/periodo';
import { ThlDateShortcutsComponent } from '../../../shared/components/thl-date-shortcuts';

@Component({
  selector: 'app-auditoria-filtro-avancado',
  standalone: true,
  imports: [PoModule, FormsModule, ThlDateShortcutsComponent],
  templateUrl: './auditoria-filtro-avancado.component.html'
})
export class AuditoriaFiltroAvancadoComponent {
  private host = inject(ElementRef);

  @ViewChild('modal', { static: true }) modal!: PoModalComponent;
  @Output() filtrar = new EventEmitter<AuditoriaFiltro>();

  filtro: AuditoriaFiltro = {};
  dtCriacaoIni = '';
  dtCriacaoFin = '';

  /** Atalho em destaque; `personalizado` assim que o usuário mexe nos campos. */
  atalho: AtalhoData | '' = '';

  aplicarAtalho(faixa: FaixaPeriodo): void {
    this.dtCriacaoIni = faixa.ini;
    this.dtCriacaoFin = faixa.fin;
  }

  /** Data digitada na mão desfaz o destaque do atalho — senão a pílula afirmaria uma
   *  faixa que não é mais a dos campos. Comparar com a faixa do atalho (em vez de usar
   *  um sinalizador) resolve também o eco do próprio `aplicarAtalho`: preencher os dois
   *  campos dispara `ngModelChange` duas vezes, e o atalho se apagaria sozinho. */
  aoDigitarData(): void {
    if (!this.atalho || this.atalho === 'personalizado') return;
    const faixa = faixaDoAtalhoData(this.atalho);
    if (faixa && mesmaDataHora(this.dtCriacaoIni, faixa.ini) && mesmaDataHora(this.dtCriacaoFin, faixa.fin)) return;
    this.atalho = 'personalizado';
  }


  primaryAction: PoModalAction = {
    label: 'Filtrar',
    action: () => this.aplicar()
  };

  secondaryAction: PoModalAction = {
    label: 'Limpar',
    action: () => this.limpar()
  };

  open(): void {
    this.modal.open();
  }

  /** Faixa do campo de período. O `po-datetimepicker` só preenche o modelo com data **e**
   *  hora completas — incompleto, ele grava a string "Data/hora inválida" no modelo e não
   *  marca erro algum. Sem data utilizável no modelo, vale o que está escrito no campo:
   *  data sozinha cobre o dia inteiro. */
  private faixaDoCampo(nome: string, valor: unknown, limite: 'inicio' | 'fim'): string {
    const doModelo = paraFaixa(valor, limite);
    if (doModelo) return doModelo;

    const input: HTMLInputElement | null =
      this.host.nativeElement.querySelector(`po-datetimepicker input[name="${nome}"]`);
    return textoDigitadoParaFaixa(input?.value ?? '', limite);
  }

  private aplicar(): void {
    const filtroEmitido: AuditoriaFiltro = { ...this.filtro };

    const ini = this.faixaDoCampo('dtCriacaoIni', this.dtCriacaoIni, 'inicio');
    const fin = this.faixaDoCampo('dtCriacaoFin', this.dtCriacaoFin, 'fim');
    if (ini) filtroEmitido.dtCriacaoInicial = ini;
    if (fin) filtroEmitido.dtCriacaoFinal = fin;

    this.filtrar.emit(filtroEmitido);
    this.modal.close();
  }

  private limpar(): void {
    this.filtro = {};
    this.atalho = '';
    this.dtCriacaoIni = '';
    this.dtCriacaoFin = '';
  }
}

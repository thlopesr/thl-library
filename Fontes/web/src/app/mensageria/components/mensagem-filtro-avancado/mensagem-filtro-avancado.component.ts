import { Component, EventEmitter, Output, ViewChild, ElementRef, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PoModalComponent, PoModalAction, PoModule } from '@po-ui/ng-components';
import { MensagemFiltro } from '../../models/mensagem.model';
import { AtalhoData, FaixaPeriodo, faixaDoAtalhoData, mesmaDataHora, paraFaixa, textoDigitadoParaFaixa } from '../../../shared/domain/periodo';
import { LimiteRetencao, ThlDateShortcutsComponent } from '../../../shared/components/thl-date-shortcuts';

@Component({
  selector: 'app-mensagem-filtro-avancado',
  standalone: true,
  imports: [PoModule, FormsModule, ThlDateShortcutsComponent],
  templateUrl: './mensagem-filtro-avancado.component.html',
  styleUrls: ['../../../shared/styles/thl-filtro.scss']
})
export class MensagemFiltroAvancadoComponent {
  private host = inject(ElementRef);

  @ViewChild('modal', { static: true }) modal!: PoModalComponent;
  @Output() filtrar = new EventEmitter<MensagemFiltro>();

  filtro: MensagemFiltro = {};
  dtIntegracaoIni = '';
  dtIntegracaoFin = '';
  dtCriacaoIni = '';
  dtCriacaoFin = '';

  /** Retenção padrão do objeto: 21 dias para sucesso, 42 para erro (ADR de métricas).
   *  É por objeto e configurável, então o aviso fala em "pode", não em "foi". */
  readonly limiteRetencao: LimiteRetencao = {
    dias: 21,
    texto: 'Sucessos anteriores a {data} podem já ter sido expurgados; erros ficam 42 dias. '
      + 'A retenção é por objeto e pode estar diferente no seu ambiente.'
  };

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


  /** Com o filtro em abas, o que está preenchido na aba oculta precisa aparecer no
   *  rótulo — senão o usuário filtra sem lembrar do que deixou do outro lado.
   *  A string "Data/hora inválida" que o `po-datetimepicker` grava num campo
   *  incompleto não conta: ela não vira filtro. */
  get rotuloAbaPrincipal(): string {
    return this.comContador('Principal', [
      this.dtCriacaoIni, this.dtCriacaoFin, this.dtIntegracaoIni, this.dtIntegracaoFin,
      this.filtro.aplicacaoIni, this.filtro.aplicacaoFin,
      this.filtro.objetoIni, this.filtro.objetoFin,
      this.filtro.operacaoIni, this.filtro.operacaoFin
    ]);
  }

  get rotuloAbaAvancado(): string {
    return this.comContador('Avançado', [
      this.filtro.codMsgIni, this.filtro.codMsgFin,
      this.filtro.dispositivo, this.filtro.metodo,
      this.filtro.statusRequisicao, this.filtro.statusProcessamento,
      this.filtro.statusRetorno, this.filtro.codStatusRetorno
    ]);
  }

  private comContador(titulo: string, valores: Array<unknown>): string {
    const preenchidos = valores.filter(
      v => v !== undefined && v !== null && v !== '' && v !== 'Data/hora inválida'
    ).length;
    return preenchidos ? `${titulo} (${preenchidos})` : titulo;
  }

  metodoOptions = [
    { label: 'GET', value: 'GET' },
    { label: 'POST', value: 'POST' },
    { label: 'PUT', value: 'PUT' },
    { label: 'DELETE', value: 'DELETE' },
    { label: 'PATCH', value: 'PATCH' }
  ];

  dispositivoOptions = [
    { label: 'Entrada', value: 'Entrada' },
    { label: 'Saída', value: 'Saida' }
  ];

  statusOptions = [
    { label: 'Todos', value: '' },
    { label: 'Sucesso', value: 'Sucesso' },
    { label: 'Erro', value: 'Erro' },
    { label: 'Pendente', value: 'Pendente' },
    { label: 'N/A', value: 'N/A' }
  ];

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
    const filtroEmitido: MensagemFiltro = { ...this.filtro };

    const intIni = this.faixaDoCampo('dtIntegracaoIni', this.dtIntegracaoIni, 'inicio');
    const intFin = this.faixaDoCampo('dtIntegracaoFin', this.dtIntegracaoFin, 'fim');
    if (intIni) filtroEmitido.dtIntegracaoInicial = intIni;
    if (intFin) filtroEmitido.dtIntegracaoFinal = intFin;

    const crIni = this.faixaDoCampo('dtCriacaoIni', this.dtCriacaoIni, 'inicio');
    const crFin = this.faixaDoCampo('dtCriacaoFin', this.dtCriacaoFin, 'fim');
    if (crIni) filtroEmitido.dtCriacaoInicial = crIni;
    if (crFin) filtroEmitido.dtCriacaoFinal = crFin;

    this.filtrar.emit(filtroEmitido);
    this.modal.close();
  }

  private limpar(): void {
    this.filtro = {};
    this.atalho = '';
    this.dtIntegracaoIni = '';
    this.dtIntegracaoFin = '';
    this.dtCriacaoIni = '';
    this.dtCriacaoFin = '';
  }
}

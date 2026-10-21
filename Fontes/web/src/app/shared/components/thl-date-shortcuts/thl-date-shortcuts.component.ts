import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { ATALHOS_DATA, AtalhoData, FaixaPeriodo, diasAtras, faixaDoAtalhoData } from '../../domain/periodo';

/** Aviso de retenção da tela: acima de `dias`, o texto aparece com `{data}` trocado
 *  pela data-limite. Serve para dizer que o período pedido alcança dado já expurgado. */
export interface LimiteRetencao {
  dias: number;
  texto: string;
}

// Atalhos de período dos filtros avançados. **Preenchem os campos de data à vista** em vez
// de filtrar escondido: o usuário vê a faixa que escolheu e pode corrigi-la antes de aplicar.
//
// São links discretos encostados no campo, e não as pílulas dos atalhos das métricas: aqui
// eles dividem espaço com um formulário inteiro, e a pílula pesava demais. O lugar ideal
// seria o rodapé do calendário, junto de "Limpar | Hoje", mas o `po-calendar-footer` do PO UI
// é interno e não projeta conteúdo — chegar lá exigiria injetar DOM no overlay da biblioteca.
@Component({
  selector: 'thl-date-shortcuts',
  standalone: true,
  imports: [],
  templateUrl: './thl-date-shortcuts.component.html',
  styleUrls: ['./thl-date-shortcuts.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlDateShortcutsComponent {
  /** Atalho em destaque. Volta para `personalizado` quando o usuário digita a data na mão. */
  @Input() selecionado: AtalhoData | '' = '';

  /** Valor atual do campo inicial — é com ele que o aviso de retenção é calculado,
   *  então o aviso aparece tanto no atalho quanto na data digitada. */
  @Input() ini = '';

  @Input() limite?: LimiteRetencao;

  @Output() selecionadoChange = new EventEmitter<AtalhoData>();
  @Output() faixaChange = new EventEmitter<FaixaPeriodo>();

  opcoes = ATALHOS_DATA;

  aoEscolher(valor: string): void {
    const atalho = valor as AtalhoData;
    this.selecionado = atalho;
    this.selecionadoChange.emit(atalho);

    // `personalizado` não mexe nos campos: mantém o que está lá para o usuário ajustar,
    // em vez de apagar o trabalho dele por ter clicado na pílula.
    const faixa = faixaDoAtalhoData(atalho);
    if (faixa) this.faixaChange.emit(faixa);
  }

  get aviso(): string | null {
    if (!this.limite || !this.ini) return null;
    const dias = diasAtras(this.ini);
    if (dias === null || dias <= this.limite.dias) return null;

    const corte = new Date();
    corte.setDate(corte.getDate() - this.limite.dias);
    const data = corte.toLocaleDateString('pt-BR');
    return this.limite.texto.replace('{data}', data);
  }
}

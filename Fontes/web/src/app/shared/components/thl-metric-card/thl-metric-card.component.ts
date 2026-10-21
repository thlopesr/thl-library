import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { MetricCard, MetricCor, MetricFase, MetricLinha } from './thl-metric-card.model';

/** Chave, ícone e cor de cada coluna da tabela de fases. */
interface ColunaFase {
  chave: keyof Pick<MetricFase, 'sucesso' | 'pendente' | 'erro' | 'na'>;
  icone: string;
  cor: MetricCor;
  titulo: string;
}

// Cartão de métrica das telas `<feature>/metricas`. Mesma estrutura nas três:
// título e total no topo, contagens no meio, barra e ação embaixo — quem aprende
// uma lê as outras. A barra é proporção (auditoria) ou percentual (mensageria, e-mail).
@Component({
  selector: 'thl-metric-card',
  standalone: true,
  imports: [PoModule],
  templateUrl: './thl-metric-card.component.html',
  styleUrls: ['./thl-metric-card.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlMetricCardComponent {
  @Input({ required: true }) card!: MetricCard;

  /** Cartão da tela geral: tipografia e ícones maiores, porque lá são só três. */
  @Input() grande = false;

  @Output() acaoClick = new EventEmitter<MetricCard>();

  /** `acento` manda na moldura quando existe; senão vale o estado. */
  get classeDaMoldura(): string {
    if (this.card.acento) return 'thl-metric--acento';
    return this.card.estado ? `thl-metric--estado-${this.card.estado}` : '';
  }

  /** Mesmos ícones dos chips das telas de métricas — é o que dispensa legenda. */
  readonly colunas: ColunaFase[] = [
    { chave: 'sucesso', icone: 'an an-check-circle', cor: 'sucesso', titulo: 'Sucesso' },
    { chave: 'pendente', icone: 'an an-clock', cor: 'alerta', titulo: 'Pendente' },
    { chave: 'erro', icone: 'an an-x-circle', cor: 'erro', titulo: 'Erro' },
    { chave: 'na', icone: 'an an-minus-circle', cor: 'neutro', titulo: 'Não se aplica' }
  ];

  valorDaFase(fase: MetricFase, chave: ColunaFase['chave']): number {
    return fase[chave];
  }

  /** O ícone não chega ao leitor de tela: a linha inteira leva os quatro valores escritos. */
  descricaoDaFase(fase: MetricFase): string {
    const partes = this.colunas
      .filter(c => fase[c.chave] > 0)
      .map(c => `${fase[c.chave]} ${c.titulo.toLowerCase()}`);
    return `${fase.label}: ${partes.length ? partes.join(', ') : 'sem mensagens'}`;
  }

  get percentual(): number | null {
    const barra = this.card.barra;
    return barra && 'percentual' in barra ? barra.percentual : null;
  }

  get proporcao(): MetricLinha[] {
    const barra = this.card.barra;
    if (!barra || !('proporcao' in barra)) return [];
    return this.card.linhas.filter(l => l.valor > 0);
  }

  largura(linha: MetricLinha): number {
    const soma = this.card.linhas.reduce((t, l) => t + l.valor, 0);
    return soma > 0 ? Math.round((linha.valor / soma) * 100) : 0;
  }

  classe(cor: MetricCor | undefined): string {
    return `thl-metric--${cor ?? 'neutro'}`;
  }
}

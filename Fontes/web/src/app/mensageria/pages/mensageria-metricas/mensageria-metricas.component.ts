import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription, finalize } from 'rxjs';
import { PoModule } from '@po-ui/ng-components';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlPeriodFilterComponent } from '../../../shared/components/thl-period-filter';
import { ThlIconToggleComponent } from '../../../shared/components/thl-icon-toggle';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { ThlMetricCardComponent, MetricCard, MetricFase } from '../../../shared/components/thl-metric-card';
import { FaixaPeriodo, PeriodoAtalho, RETENCAO_DIAS, excedeRetencao, faixaDoAtalho, periodoDaUrl, periodoParaUrl, rotuloDoPeriodo } from '../../../shared/domain/periodo';
import { MetricasService } from '../../../shared/domain/metricas.service';
import { MensageriaMetrica, MensageriaMetricaItem } from '../../models/mensageria-metrica.model';

type Fase = 'sitRequisicao' | 'sitProcessamento' | 'sitRetorno';

/** Chaves dos chips: o filtro precisa cobrir todas, senão um chip faz o que o outro promete. */
type SituacaoMensagem = 'todos' | 'Sucesso' | 'Erro' | 'Pendente';

// Mensageria tem três fases e reprocesso: aqui a barra é saúde (percentual sem erro),
// porque existe falha para corrigir. `interna` separa o tráfego do próprio THL.
@Component({
  selector: 'app-mensageria-metricas',
  standalone: true,
  imports: [
    PoModule, ThlPageHeaderComponent, ThlStatChipsComponent,
    ThlPeriodFilterComponent, ThlIconToggleComponent, ThlMetricCardComponent,
    ThlErrorStateComponent, ThlEmptyStateComponent
  ],
  templateUrl: './mensageria-metricas.component.html',
  styleUrls: ['../../../shared/styles/thl-metricas.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MensageriaMetricasComponent implements OnInit {
  private service = inject(MetricasService);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  carregando = false;
  /** Busca em andamento: a troca de período cancela a anterior (a resposta lenta venceria). */
  private inscricao?: Subscription;
  atualizadoEm = '';
  erro: string | null = null;
  atalho: PeriodoAtalho = '24h';
  faixa: FaixaPeriodo = faixaDoAtalho('24h');
  rotuloPeriodo = rotuloDoPeriodo('24h', this.faixa);

  private dados: MensageriaMetrica[] = [];
  cards: MetricCard[] = [];
  mostrarTodos = false;
  readonly limiteCards = 12;
  chips: StatChip[] = [];
  filtroAtivo: SituacaoMensagem = 'todos';
  mostrarInternas = false;

  /** Faixa longa demais mostra queda que é expurgo, não queda de tráfego. */
  get avisoRetencao(): string | null {
    return excedeRetencao(this.faixa)
      ? `Mensagens concluídas com sucesso são expurgadas após ${RETENCAO_DIAS} dias: o início deste período pode aparecer incompleto.`
      : null;
  }

  /** Cartões já vêm ordenados por volume; o resto fica atrás do "Ver todos". */
  get cardsVisiveis(): MetricCard[] {
    return this.mostrarTodos ? this.cards : this.cards.slice(0, this.limiteCards);
  }

  get ocultos(): number {
    return Math.max(0, this.cards.length - this.limiteCards);
  }

  verTodos(): void {
    this.mostrarTodos = true;
    this.guardarNaUrl();
  }

  ngOnInit(): void {
    const daUrl = periodoDaUrl(this.route.snapshot.queryParams);
    if (daUrl) {
      this.atalho = daUrl.atalho;
      this.faixa = daUrl.faixa;
      this.rotuloPeriodo = rotuloDoPeriodo(daUrl.atalho, daUrl.faixa);
    }

    const params = this.route.snapshot.queryParams;
    if (params['chip']) this.filtroAtivo = params['chip'] as SituacaoMensagem;
    this.mostrarTodos = params['todos'] === '1';
    this.mostrarInternas = this.route.snapshot.queryParams['internas'] === '1';
    this.carregar();
  }

  aoMudarPeriodo(evento: { atalho: PeriodoAtalho; faixa: FaixaPeriodo }): void {
    this.atalho = evento.atalho;
    this.faixa = evento.faixa;
    this.rotuloPeriodo = rotuloDoPeriodo(evento.atalho, evento.faixa);
    this.guardarNaUrl();
    this.carregar();
  }

  aoClicarChip(chip: StatChip): void {
    this.filtroAtivo = chip.key as SituacaoMensagem;
    this.chips = this.chips.map(c => ({ ...c, active: c.key === chip.key }));
    this.guardarNaUrl();
    this.montarCards();
    this.cdr.markForCheck();
  }

  alternarInternas(): void {
    this.mostrarInternas = !this.mostrarInternas;
    this.guardarNaUrl();
    this.montarChips();
    this.montarCards();
    this.cdr.markForCheck();
  }

  verMensagens(card: MetricCard): void {
    const [aplicacao, objeto] = card.id.split('|');
    this.router.navigate(['/mensageria'], {
      queryParams: {
        aplicacao,
        objeto,
        // A listagem lê com `getDateTime` desde 2026-10-13: a faixa vai inteira, com hora.
        dtCriacaoIni: this.faixa.ini,
        dtCriacaoFin: this.faixa.fin
      }
    });
  }

  /** Período na URL (sem empilhar histórico a cada troca): voltar para a tela
   *  restaura o que estava escolhido, em vez de cair no padrão. */
  private guardarNaUrl(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        ...periodoParaUrl(this.atalho, this.faixa),
        // null remove o parâmetro da URL quando o tráfego interno volta a ficar oculto.
        internas: this.mostrarInternas ? '1' : null,
        chip: this.filtroAtivo === 'todos' ? null : this.filtroAtivo,
        todos: this.mostrarTodos ? '1' : null
      },
      replaceUrl: true
    });
  }

  carregar(): void {
    this.inscricao?.unsubscribe();
    this.carregando = true;
    this.cdr.markForCheck();

    this.inscricao = this.service.buscar<MensageriaMetrica>('mensageria', 'dtCriacao', this.faixa).pipe(
      finalize(() => {
        this.carregando = false;
        this.cdr.markForCheck();
      })
    ).subscribe({
      next: dados => {
        this.erro = null;
        this.atualizadoEm = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        this.dados = dados ?? [];
        this.montarChips();
        this.montarCards();
      },
      error: (err: unknown) => {
        this.dados = [];
        this.cards = [];
        this.chips = [];
        const corpo = (err as { error?: { message?: string } } | null)?.error;
        this.erro = corpo?.message || 'Não foi possível carregar as métricas da mensageria.';
      }
    });
  }

  private visiveis(): MensageriaMetrica[] {
    return this.mostrarInternas ? this.dados : this.dados.filter(l => !l.interna);
  }

  private erros(msg: MensageriaMetricaItem): number {
    return [msg.sitRequisicao, msg.sitProcessamento, msg.sitRetorno].filter(s => s === 'Erro').length;
  }

  private contarFase(linha: MensageriaMetrica, fase: Fase, situacao: string): number {
    return linha.mensagens.filter(m => m[fase] === situacao).length;
  }

  private montarChips(): void {
    const linhas = this.visiveis();
    const total = linhas.reduce((t, l) => t + l.mensagens.length, 0);
    const comErro = linhas.reduce((t, l) => t + l.mensagens.filter(m => this.erros(m) > 0).length, 0);
    const pendentes = linhas.reduce(
      (t, l) => t + l.mensagens.filter(m => [m.sitRequisicao, m.sitProcessamento, m.sitRetorno].includes('Pendente')).length, 0);
    this.chips = [
      { key: 'todos', label: 'Mensagens', value: total, icon: 'an an-list-dashes', color: '#3B82F6', active: this.filtroAtivo === 'todos' },
      { key: 'Sucesso', label: 'Sem erro', value: total - comErro, icon: 'an an-check-circle', color: '#0f7346', active: this.filtroAtivo === 'Sucesso' },
      { key: 'Erro', label: 'Com erro', value: comErro, icon: 'an an-x-circle', color: '#c23934', active: this.filtroAtivo === 'Erro' },
      { key: 'Pendente', label: 'Pendentes', value: pendentes, icon: 'an an-clock', color: '#d4a017', active: this.filtroAtivo === 'Pendente' }
    ];
  }

  private montarCards(): void {
    // Mostra os objetos que têm ao menos uma mensagem na situação escolhida.
    let linhas = this.visiveis();
    if (this.filtroAtivo === 'Erro') {
      linhas = linhas.filter(l => l.mensagens.some(m => this.erros(m) > 0));
    } else if (this.filtroAtivo === 'Sucesso') {
      linhas = linhas.filter(l => l.mensagens.some(m => this.erros(m) === 0));
    } else if (this.filtroAtivo === 'Pendente') {
      linhas = linhas.filter(l => l.mensagens.some(
        m => [m.sitRequisicao, m.sitProcessamento, m.sitRetorno].includes('Pendente')));
    }

    this.cards = linhas
      .map(linha => {
        const total = linha.mensagens.length;
        const comErro = linha.mensagens.filter(m => this.erros(m) > 0).length;
        const saude = total > 0 ? Math.round(((total - comErro) / total) * 100) : 0;
        const ultima = linha.mensagens.map(m => m.dtCriacao).sort().at(-1);
        const sentidos = new Set(linha.mensagens.map(m => m.dispositivo));
        const fases = [
          this.faseDe(linha, 'Requisição', 'sitRequisicao'),
          this.faseDe(linha, 'Processamento', 'sitProcessamento'),
          this.faseDe(linha, 'Retorno', 'sitRetorno')
        ];
        return {
          id: `${linha.aplicacao}|${linha.objeto}`,
          titulo: `${linha.aplicacao} · ${linha.objeto}`,
          etiquetas: [
            // Decolagem sai, pouso chega — a metáfora é mais imediata que a seta diagonal.
            // O texto fica: a 11px os dois desenhos viram a mesma mancha (medido em 16/10).
            ...[...sentidos].map(s => ({
              texto: s === 'Saida' ? 'Saída' : 'Entrada',
              cor: (s === 'Saida' ? 'alerta' : 'info') as 'alerta' | 'info',
              icone: s === 'Saida' ? 'an an-airplane-takeoff' : 'an an-airplane-landing'
            })),
            ...(linha.interna ? [{ texto: 'Interna', cor: 'neutro' as const }] : [])
          ],
          total,
          linhas: [],
          fases,
          barra: { rotulo: 'Saúde', percentual: saude, cor: this.corDaSaude(saude) },
          rodape: ultima ? `última ${ultima.substring(8, 10)}/${ultima.substring(5, 7)} ${ultima.substring(11, 16)}` : 'sem mensagem',
          acao: 'Ver mensagens',
          estado: this.estadoDe(fases)
        };
      })
      .sort((a, b) => a.total - b.total).reverse();
  }

  /** Reparte a fase entre as quatro situações. As quatro somam o total do cartão, então
   *  as três fases ficam na mesma régua e dá para comparar uma com a outra.
   *  Tudo o que não for Sucesso, Pendente ou Erro conta como "não se aplica" — é o caso
   *  do retorno numa mensagem de entrada, que o backend devolve como `N/A`. */
  private faseDe(linha: MensageriaMetrica, label: string, campo: keyof MensageriaMetricaItem): MetricFase {
    const fase: MetricFase = { label, sucesso: 0, pendente: 0, erro: 0, na: 0 };
    for (const msg of linha.mensagens) {
      const valor = msg[campo];
      if (valor === 'Sucesso') fase.sucesso++;
      else if (valor === 'Pendente') fase.pendente++;
      else if (valor === 'Erro') fase.erro++;
      else fase.na++;
    }
    return fase;
  }

  /** Cor da borda pelo pior estado presente, na mesma escala dos chips. */
  private estadoDe(fases: MetricFase[]): 'erro' | 'alerta' | 'sucesso' {
    if (fases.some(f => f.erro > 0)) return 'erro';
    if (fases.some(f => f.pendente > 0)) return 'alerta';
    return 'sucesso';
  }

  private corDaSaude(saude: number): 'sucesso' | 'alerta' | 'erro' {
    if (saude >= 95) return 'sucesso';
    return saude >= 80 ? 'alerta' : 'erro';
  }
}

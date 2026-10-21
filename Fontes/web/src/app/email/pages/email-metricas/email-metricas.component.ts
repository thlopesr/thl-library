import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription, finalize } from 'rxjs';
import { PoModule } from '@po-ui/ng-components';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlPeriodFilterComponent } from '../../../shared/components/thl-period-filter';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { ThlMetricCardComponent, MetricCard, MetricFase } from '../../../shared/components/thl-metric-card';
import { FaixaPeriodo, PeriodoAtalho, RETENCAO_DIAS, excedeRetencao, faixaDoAtalho, periodoDaUrl, periodoParaUrl, rotuloDoPeriodo } from '../../../shared/domain/periodo';
import { MetricasService } from '../../../shared/domain/metricas.service';
import { EmailMetrica } from '../../models/email-metrica.model';

/** Chaves dos chips: o filtro precisa cobrir todas, senão um chip faz o que o outro promete. */
type SituacaoEmail = 'todos' | 'Sucesso' | 'Erro' | 'Pendente';

// E-mail tem uma fase só (o envio), então a barra é taxa de entrega — saúde de verdade.
// A unidade é programa + parâmetro de ambiente: o `thl-email` não guarda o parâmetro de e-mail.
@Component({
  selector: 'app-email-metricas',
  standalone: true,
  imports: [
    PoModule, ThlPageHeaderComponent, ThlStatChipsComponent,
    ThlPeriodFilterComponent, ThlMetricCardComponent,
    ThlErrorStateComponent, ThlEmptyStateComponent
  ],
  templateUrl: './email-metricas.component.html',
  styleUrls: ['../../../shared/styles/thl-metricas.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EmailMetricasComponent implements OnInit {
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

  private dados: EmailMetrica[] = [];
  cards: MetricCard[] = [];
  mostrarTodos = false;
  readonly limiteCards = 12;
  chips: StatChip[] = [];
  filtroAtivo: SituacaoEmail = 'todos';

  /** Faixa longa demais mostra queda que é expurgo, não queda de tráfego. */
  get avisoRetencao(): string | null {
    return excedeRetencao(this.faixa)
      ? `Período acima de ${RETENCAO_DIAS} dias: o início pode aparecer incompleto, conforme o expurgo configurado.`
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
    if (params['chip']) this.filtroAtivo = params['chip'] as SituacaoEmail;
    this.mostrarTodos = params['todos'] === '1';
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
    this.filtroAtivo = chip.key as SituacaoEmail;
    this.chips = this.chips.map(c => ({ ...c, active: c.key === chip.key }));
    this.guardarNaUrl();
    this.montarCards();
    this.cdr.markForCheck();
  }

  verEmails(card: MetricCard): void {
    const [programa] = card.id.split('|');
    this.router.navigate(['/email'], {
      queryParams: {
        // `codProgDtsul` é o nome do filtro na rota de e-mail (EmailMessage).
        codProgDtsul: programa,
        // A listagem lê com `getDateTime` desde 2026-10-13: a faixa vai inteira, com hora.
        dtEnvioIni: this.faixa.ini,
        dtEnvioFin: this.faixa.fin
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
        // null tira o parâmetro da URL quando volta ao padrão, em vez de sujá-la.
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

    this.inscricao = this.service.buscar<EmailMetrica>('email', 'dtEnvio', this.faixa).pipe(
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
        this.erro = corpo?.message || 'Não foi possível carregar as métricas de e-mail.';
      }
    });
  }

  private contar(linha: EmailMetrica, situacao: string): number {
    return linha.emails.filter(e => e.situacao === situacao).length;
  }

  private montarChips(): void {
    const soma = (s: string) => this.dados.reduce((t, l) => t + this.contar(l, s), 0);
    const total = this.dados.reduce((t, l) => t + l.emails.length, 0);
    this.chips = [
      { key: 'todos', label: 'Envios', value: total, icon: 'an an-envelope-simple', color: '#3B82F6', active: this.filtroAtivo === 'todos' },
      { key: 'Sucesso', label: 'Entregues', value: soma('Sucesso'), icon: 'an an-check-circle', color: '#0f7346', active: this.filtroAtivo === 'Sucesso' },
      { key: 'Erro', label: 'Falhas', value: soma('Erro'), icon: 'an an-x-circle', color: '#c23934', active: this.filtroAtivo === 'Erro' },
      { key: 'Pendente', label: 'Pendentes', value: soma('Pendente'), icon: 'an an-clock', color: '#d4a017', active: this.filtroAtivo === 'Pendente' }
    ];
  }

  private montarCards(): void {
    // Mostra os programas que têm ao menos um envio na situação escolhida.
    const visiveis = this.filtroAtivo === 'todos'
      ? this.dados
      : this.dados.filter(l => this.contar(l, this.filtroAtivo) > 0);

    this.cards = visiveis
      .map(linha => {
        const total = linha.emails.length;
        const entregues = this.contar(linha, 'Sucesso');
        const ultimo = linha.emails.map(e => e.dtEnvio).sort().at(-1);
        const taxa = total > 0 ? Math.round((entregues / total) * 100) : 0;
        const falhas = this.contar(linha, 'Erro');
        const pendentes = this.contar(linha, 'Pendente');
        const fase: MetricFase = {
          label: 'Envio',
          sucesso: entregues,
          pendente: pendentes,
          erro: falhas,
          na: total - entregues - pendentes - falhas
        };
        return {
          id: `${linha.programa}|${linha.paramAmbiente}`,
          titulo: linha.programa || '(sem programa)',
          etiquetas: linha.paramAmbiente ? [{ texto: linha.paramAmbiente, cor: 'neutro' as const }] : [],
          total,
          linhas: [],
          // Uma fase só: no e-mail o que existe é o envio. Mesmo cabeçalho de ícones da
          // mensageria, para as duas telas se lerem igual.
          fases: [fase],
          barra: { rotulo: 'Entrega', percentual: taxa, cor: this.corDaTaxa(taxa) },
          rodape: ultimo ? `último ${ultimo.substring(8, 10)}/${ultimo.substring(5, 7)} ${ultimo.substring(11, 16)}` : 'sem envio',
          acao: 'Ver e-mails',
          estado: falhas > 0 ? ('erro' as const) : pendentes > 0 ? ('alerta' as const) : ('sucesso' as const)
        };
      })
      .sort((a, b) => b.total - a.total);
  }

  private corDaTaxa(taxa: number): 'sucesso' | 'alerta' | 'erro' {
    if (taxa >= 95) return 'sucesso';
    return taxa >= 80 ? 'alerta' : 'erro';
  }
}

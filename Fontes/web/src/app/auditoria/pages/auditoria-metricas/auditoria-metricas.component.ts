import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription, finalize } from 'rxjs';
import { PoModule } from '@po-ui/ng-components';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlPeriodFilterComponent } from '../../../shared/components/thl-period-filter';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { ThlMetricCardComponent, MetricCard } from '../../../shared/components/thl-metric-card';
import { FaixaPeriodo, PeriodoAtalho, RETENCAO_DIAS, excedeRetencao, faixaDoAtalho, periodoDaUrl, periodoParaUrl, rotuloDoPeriodo } from '../../../shared/domain/periodo';
import { MetricasService } from '../../../shared/domain/metricas.service';
import { AuditoriaMetrica } from '../../models/auditoria-metrica.model';

type Operacao = 'Criacao' | 'Atualizacao' | 'Delecao';

// Auditoria não tem falha: todo registro é um evento gravado. A métrica é volume por
// tabela, repartido em criação, alteração e deleção — por isso a barra é proporção,
// não saúde, e o chip de deleções filtra o que é raro e irreversível.
@Component({
  selector: 'app-auditoria-metricas',
  standalone: true,
  imports: [
    PoModule, ThlPageHeaderComponent, ThlStatChipsComponent,
    ThlPeriodFilterComponent, ThlMetricCardComponent,
    ThlErrorStateComponent, ThlEmptyStateComponent
  ],
  templateUrl: './auditoria-metricas.component.html',
  styleUrls: ['../../../shared/styles/thl-metricas.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AuditoriaMetricasComponent implements OnInit {
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

  private dados: AuditoriaMetrica[] = [];
  cards: MetricCard[] = [];
  mostrarTodos = false;
  readonly limiteCards = 12;
  chips: StatChip[] = [];
  filtroAtivo: 'todos' | Operacao = 'todos';

  /** Faixa longa demais mostra queda que é expurgo, não queda de tráfego. */
  get avisoRetencao(): string | null {
    return excedeRetencao(this.faixa)
      ? `Período acima de ${RETENCAO_DIAS} dias: o início pode aparecer incompleto, conforme a retenção de cada tabela auditada.`
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
    if (params['chip']) this.filtroAtivo = params['chip'] as 'todos' | Operacao;
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
    const chave = chip.key;
    this.filtroAtivo = chave as 'todos' | Operacao;
    this.chips = this.chips.map(c => ({ ...c, active: c.key === chave }));
    this.guardarNaUrl();
    this.montarCards();
    this.cdr.markForCheck();
  }

  /** Abre a consulta de auditoria já na tabela do cartão. */
  verRegistros(card: MetricCard): void {
    const [banco, tabela] = card.id.split('|');
    this.router.navigate(['/auditoria'], {
      queryParams: { banco, tabela, ...this.faixaEmData() }
    });
  }

  /** A listagem lê com `getDateTime` desde 2026-10-13: a faixa vai inteira, com hora. */
  private faixaEmData(): { dtCriacaoIni: string; dtCriacaoFin: string } {
    return { dtCriacaoIni: this.faixa.ini, dtCriacaoFin: this.faixa.fin };
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

    this.inscricao = this.service.buscar<AuditoriaMetrica>('auditoria', 'dtCriacao', this.faixa).pipe(
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
        this.erro = corpo?.message || 'Não foi possível carregar as métricas da auditoria.';
      }
    });
  }

  private contar(linha: AuditoriaMetrica, tipo: Operacao): number {
    return linha.registros.filter(r => r.tipo === tipo).length;
  }

  private montarChips(): void {
    const soma = (tipo: Operacao) => this.dados.reduce((t, l) => t + this.contar(l, tipo), 0);
    const total = this.dados.reduce((t, l) => t + l.registros.length, 0);
    this.chips = [
      { key: 'todos', label: 'Interações', value: total, icon: 'an an-list-dashes', color: '#3B82F6', active: this.filtroAtivo === 'todos' },
      { key: 'Criacao', label: 'Criações', value: soma('Criacao'), icon: 'an an-plus-circle', color: '#0f7346', active: this.filtroAtivo === 'Criacao' },
      { key: 'Atualizacao', label: 'Alterações', value: soma('Atualizacao'), icon: 'an an-pencil-simple', color: '#d4a017', active: this.filtroAtivo === 'Atualizacao' },
      { key: 'Delecao', label: 'Deleções', value: soma('Delecao'), icon: 'an an-trash', color: '#c23934', active: this.filtroAtivo === 'Delecao' }
    ];
  }

  private montarCards(): void {
    const visiveis = this.filtroAtivo === 'todos'
      ? this.dados
      : this.dados.filter(l => this.contar(l, this.filtroAtivo as Operacao) > 0);

    this.cards = visiveis
      .map(linha => {
        const ultima = linha.registros.map(r => r.dtCriacao).sort().at(-1);
        return {
          id: `${linha.banco}|${linha.tabela}`,
          titulo: `${linha.banco} · ${linha.tabela}`,
          etiquetas: this.etiquetaSensibilidade(linha.nivelSensibilidade),
          total: linha.registros.length,
          linhas: [
            { label: 'Criação', valor: this.contar(linha, 'Criacao'), cor: 'sucesso' as const },
            { label: 'Alteração', valor: this.contar(linha, 'Atualizacao'), cor: 'alerta' as const },
            { label: 'Deleção', valor: this.contar(linha, 'Delecao'), cor: 'erro' as const }
          ],
          barra: { rotulo: 'Proporção', proporcao: true as const },
          rodape: this.rodape(linha, ultima),
          acao: 'Ver registros',
          estado: this.corDaPredominante(linha)
        };
      })
      .sort((a, b) => b.total - a.total);
  }

  /** Na auditoria a borda **não** é severidade: é a ação predominante na tabela, nas
   *  mesmas cores já usadas nas linhas e nos chips (criação verde, alteração âmbar,
   *  deleção vermelha). Empate fica com a mais destrutiva, que é a que merece o olhar. */
  private corDaPredominante(linha: AuditoriaMetrica): 'sucesso' | 'alerta' | 'erro' | undefined {
    const contagens: Array<{ cor: 'sucesso' | 'alerta' | 'erro'; valor: number }> = [
      { cor: 'erro', valor: this.contar(linha, 'Delecao') },
      { cor: 'alerta', valor: this.contar(linha, 'Atualizacao') },
      { cor: 'sucesso', valor: this.contar(linha, 'Criacao') }
    ];
    const maior = contagens.reduce((a, b) => (b.valor > a.valor ? b : a));
    return maior.valor > 0 ? maior.cor : undefined;
  }

  private rodape(linha: AuditoriaMetrica, ultima?: string): string {
    const porUsuario = new Map<string, number>();
    for (const r of linha.registros) {
      porUsuario.set(r.usuario, (porUsuario.get(r.usuario) ?? 0) + 1);
    }
    const maisAtivo = [...porUsuario.entries()].sort((a, b) => b[1] - a[1])[0]?.[0];
    const quando = ultima ? `última ${ultima.substring(8, 10)}/${ultima.substring(5, 7)} ${ultima.substring(11, 16)}` : 'sem evento';
    return maisAtivo ? `${quando} · mais ativo: ${maisAtivo}` : quando;
  }

  /** Domínio 1/5/9. Valor fora dele aparece cru, como no motor de cadastro:
   *  rotular de "Normal" esconderia cadastro inválido de quem audita. */
  private etiquetaSensibilidade(nivel: number) {
    switch (nivel) {
      case 9: return [{ texto: 'Restrito', cor: 'erro' as const }];
      case 5: return [{ texto: 'Crítico', cor: 'alerta' as const }];
      case 1: return [{ texto: 'Normal', cor: 'neutro' as const }];
      default: return [{ texto: `Nível ${nivel}`, cor: 'neutro' as const }];
    }
  }
}

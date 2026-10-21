import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { PoModule } from '@po-ui/ng-components';
import { Subscription, finalize } from 'rxjs';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlPeriodFilterComponent } from '../../../shared/components/thl-period-filter';
import { ThlIconToggleComponent } from '../../../shared/components/thl-icon-toggle';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { MetricCard, MetricCor, ThlMetricCardComponent } from '../../../shared/components/thl-metric-card';
import {
  FaixaPeriodo, PeriodoAtalho, excedeRetencao, faixaDoAtalho, periodoDaUrl, periodoParaUrl, rotuloDoPeriodo
} from '../../../shared/domain/periodo';
import { MetricasResumo } from '../../models/metricas.model';
import { MetricasService } from '../../services/metricas.service';

// Tela de entrada: um bloco por assunto com o número principal e o atalho para a
// tela de métricas correspondente. O detalhe fica nas telas `<assunto>/metricas` —
// repetir aqui criava duas respostas para a mesma pergunta, que divergiam.
@Component({
  selector: 'app-metricas',
  standalone: true,
  imports: [
    PoModule, ThlPageHeaderComponent, ThlPeriodFilterComponent, ThlIconToggleComponent,
    ThlMetricCardComponent, ThlErrorStateComponent, ThlEmptyStateComponent
  ],
  templateUrl: './metricas.component.html',
  styleUrls: ['../../../shared/styles/thl-metricas.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MetricasComponent implements OnInit {
  private service = inject(MetricasService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private cdr = inject(ChangeDetectorRef);

  atalho: PeriodoAtalho = '24h';
  faixa: FaixaPeriodo = faixaDoAtalho('24h');
  rotuloPeriodo = rotuloDoPeriodo('24h', this.faixa);

  /** Mesmo botão da tela de métricas da mensageria, e mesmo padrão: começa oculto. */
  mostrarInternas = false;

  dados: MetricasResumo | null = null;
  cards: MetricCard[] = [];
  carregando = false;
  erro: string | null = null;
  atualizadoEm = '';

  /** Busca em andamento: a troca de período cancela a anterior (a resposta lenta venceria). */
  private inscricao?: Subscription;

  get avisoRetencao(): string {
    return excedeRetencao(this.faixa)
      ? 'O período passa de 21 dias, a retenção das mensagens com sucesso: o começo da faixa pode vir incompleto por expurgo.'
      : '';
  }

  get totalGeral(): number {
    const d = this.dados;
    return d ? d.mensagem.total + d.email.total + d.auditoria.total : 0;
  }

  ngOnInit(): void {
    this.mostrarInternas = this.route.snapshot.queryParams['internas'] === '1';
    const daUrl = periodoDaUrl(this.route.snapshot.queryParams);
    if (daUrl) {
      this.atalho = daUrl.atalho;
      this.faixa = daUrl.faixa;
      this.rotuloPeriodo = rotuloDoPeriodo(daUrl.atalho, daUrl.faixa);
    }
    this.carregar();
  }

  aoMudarPeriodo(evento: { atalho: PeriodoAtalho; faixa: FaixaPeriodo }): void {
    this.atalho = evento.atalho;
    this.faixa = evento.faixa;
    this.rotuloPeriodo = rotuloDoPeriodo(this.atalho, this.faixa);
    this.guardarNaUrl();
    this.carregar();
  }

  /** O resumo é montado no servidor a cada busca, então alternar refaz a consulta —
   *  é o mesmo caminho da troca de período. */
  alternarInternas(): void {
    this.mostrarInternas = !this.mostrarInternas;
    this.guardarNaUrl();
    this.carregar();
  }

  /** O cartão leva para a tela de métricas do assunto, onde há o detalhe por unidade. */
  abrirMetricas(card: MetricCard): void {
    this.router.navigate([`/${card.id}/metricas`]);
  }

  verErros(): void {
    this.router.navigate(['/mensageria'], {
      queryParams: {
        statusProcessamento: 'Erro',
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
        internas: this.mostrarInternas ? '1' : null
      },
      replaceUrl: true
    });
  }

  carregar(): void {
    this.inscricao?.unsubscribe();
    this.carregando = true;
    this.erro = null;
    this.cdr.markForCheck();

    this.inscricao = this.service.getMetricas(this.faixa, this.mostrarInternas).pipe(
      finalize(() => {
        this.carregando = false;
        this.cdr.markForCheck();
      })
    ).subscribe({
      next: (resumo) => {
        this.erro = null;
        this.dados = resumo;
        this.atualizadoEm = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        this.montarCards();
      },
      error: (err: unknown) => {
        this.dados = null;
        this.cards = [];
        const corpo = (err as { error?: { message?: string } } | null)?.error;
        this.erro = corpo?.message || 'Não foi possível obter as métricas. Verifique a conexão com o servidor.';
      }
    });
  }

  private montarCards(): void {
    const d = this.dados;
    if (!d) {
      this.cards = [];
      return;
    }

    const percentual = (parte: number, total: number) => (total > 0 ? Math.round((parte / total) * 100) : 0);
    // 97% em amarelo parece alarme: a cor acompanha a faixa, não a simples existência de erro.
    const corDoPercentual = (pct: number): MetricCor => (pct >= 95 ? 'sucesso' : pct >= 80 ? 'alerta' : 'erro');

    this.cards = [
      {
        // O id é a rota do assunto: o cartão abre `/<id>/metricas`.
        id: 'mensageria',
        titulo: 'Mensageria',
        // Mesmo ícone do item no menu lateral: quem clica aqui reencontra a tela lá.
        icone: 'an an-arrows-left-right',
        // A cor aqui **não** é estado: separa um assunto do outro. Por isso nenhuma das
        // três é verde, vermelha ou âmbar — essas três já significam sucesso, erro e
        // pendência dentro do próprio cartão.
        acento: '#2c6fb5',
        total: d.mensagem.total,
        linhas: [
          { label: 'Sucesso', valor: d.mensagem.sucesso, cor: 'sucesso', icone: 'an an-check-circle' },
          { label: 'Erro', valor: d.mensagem.erro, cor: 'erro', icone: 'an an-x-circle' },
          { label: 'Pendente', valor: d.mensagem.pendente, cor: 'alerta', icone: 'an an-clock' }
        ],
        barra: {
          rotulo: 'Processadas sem erro',
          percentual: percentual(d.mensagem.total - d.mensagem.erro, d.mensagem.total),
          cor: corDoPercentual(percentual(d.mensagem.total - d.mensagem.erro, d.mensagem.total))
        },
        rodape: 'Por objeto',
        acao: 'Ver métricas'
      },
      {
        id: 'email',
        titulo: 'E-mail',
        icone: 'an an-envelope-simple',
        acento: '#6b4fa8',
        total: d.email.total,
        linhas: [
          { label: 'Enviados', valor: d.email.sucesso, cor: 'sucesso', icone: 'an an-check-circle' },
          { label: 'Erro', valor: d.email.erro, cor: 'erro', icone: 'an an-x-circle' }
        ],
        barra: {
          rotulo: 'Entregues',
          percentual: percentual(d.email.sucesso, d.email.total),
          cor: corDoPercentual(percentual(d.email.sucesso, d.email.total))
        },
        rodape: 'Por programa',
        acao: 'Ver métricas'
      },
      {
        id: 'auditoria',
        titulo: 'Auditoria',
        icone: 'an an-magnifying-glass',
        acento: '#17807a',
        total: d.auditoria.total,
        // Mesmos ícones dos chips da tela de métricas da auditoria.
        linhas: [
          { label: 'Criação', valor: d.auditoria.criacao, cor: 'info', icone: 'an an-plus-circle' },
          { label: 'Alteração', valor: d.auditoria.atualizacao, cor: 'alerta', icone: 'an an-pencil-simple' },
          { label: 'Deleção', valor: d.auditoria.delecao, cor: 'erro', icone: 'an an-trash' }
        ],
        // Auditoria não tem falha: a barra é proporção entre as operações, não saúde.
        barra: { rotulo: 'Operações', proporcao: true },
        rodape: 'Por tabela',
        acao: 'Ver métricas'
      }
    ];
  }
}

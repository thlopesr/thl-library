import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs';
import {
  PoTableColumn,
  PoPopupAction,
  PoTableColumnSort,
  PoTableColumnSortType,
  PoNotificationService,
  PoDisclaimer,
  PoDisclaimerGroup,
  PoModule
} from '@po-ui/ng-components';
import { EmailService } from '../../services/email.service';
import { Email, EmailFiltro } from '../../models/email.model';
import { EmailFiltroAvancadoComponent } from '../../components/email-filtro-avancado/email-filtro-avancado.component';
import { EmailDetailModalComponent } from '../../components/email-detail-modal/email-detail-modal.component';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlSearchBarComponent } from '../../../shared/components/thl-search-bar';
import { ThlRowActionsComponent } from '../../../shared/components/thl-row-actions';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { STATUS_EMAIL_LABELS, maisRecentePrimeiro } from '../../../shared/domain';
import { rotuloDeDataHora } from '../../../shared/domain/periodo';
import { filtroDaUrl, filtroParaUrl } from '../../../shared/domain/filtro-url';

type StatusFilter = 'todos' | 'sucesso' | 'erro' | 'pendente';

@Component({
  selector: 'app-email-list',
  standalone: true,
  imports: [CommonModule, PoModule, EmailFiltroAvancadoComponent, EmailDetailModalComponent, ThlPageHeaderComponent, ThlStatChipsComponent, ThlSearchBarComponent, ThlRowActionsComponent, ThlErrorStateComponent, ThlEmptyStateComponent],
  templateUrl: './email-list.component.html',
  styles: [`
    .thl-erro {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 8px;
      padding: 24px;
      border: 1px solid var(--color-neutral-light-20);
      border-radius: 4px;
      background: var(--color-neutral-light-00);
    }
    .thl-erro__titulo { font-weight: 600; }
    .thl-erro__detalhe { color: var(--color-neutral-mid-60); }
    .empty-container {
      padding: 40px 0;
      text-align: center;
    }
    .thl-disclaimers {
      display: block;
      margin-bottom: 12px;
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EmailListComponent implements OnInit {
  @ViewChild('emailDetailModal') emailDetailModal!: EmailDetailModalComponent;

  private service = inject(EmailService);
  private poNotification = inject(PoNotificationService);
  private cdr = inject(ChangeDetectorRef);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  items: Email[] = [];
  isLoading = false;
  /** Mensagem do backend quando o carregamento falha: erro e lista vazia não podem se parecer. */
  erro: string | null = null;

  tentarNovamente(): void {
    this.carregar();
  }

  protected mensagemDeErro(err: unknown, padrao: string): string {
    // Só a mensagem do backend; a do HttpErrorResponse é técnica demais para o usuário.
    const corpo = (err as { error?: { message?: string } } | null)?.error;
    return corpo?.message || padrao;
  }

  hasNext = false;
  private allItems: Email[] = [];
  private filteredItems: Email[] = [];
  private page = 1;
  private readonly pageSize = 20;

  filtro: EmailFiltro = {};
  activeStatusFilter: StatusFilter = 'todos';
  lastUpdateLabel = 'agora';

  disclaimerGroup: PoDisclaimerGroup = {
    title: 'Filtros',
    disclaimers: [],
    change: (disclaimers: PoDisclaimer[]) => this.onChangeDisclaimers(disclaimers)
  };

  private readonly statusLabels = STATUS_EMAIL_LABELS;

  filterChips: StatChip[] = [
    { key: 'todos',   label: 'Todos',   value: 0, icon: 'an an-list-dashes',  color: '#3B82F6', active: true },
    { key: 'sucesso', label: 'Enviado', value: 0, icon: 'an an-check-circle', color: '#16A34A', active: false },
    { key: 'erro',    label: 'Erro',    value: 0, icon: 'an an-x-circle',     color: '#EF4444', active: false },
    { key: 'pendente', label: 'Pendente', value: 0, icon: 'an an-clock',      color: '#D97706', active: false },
  ];

  columns: PoTableColumn[] = [
    { property: 'acoes', label: 'Ação', type: 'cellTemplate', width: '88px', sortable: false },
    { property: 'dtEnvio', label: 'Dt. Envio', type: 'dateTime', format: 'dd/MM/yyyy HH:mm:ss' },
    { property: 'logEnvio', label: 'Status', type: 'label', labels: this.statusLabels },
    { property: 'assunto', label: 'Assunto' },
    { property: 'remetente', label: 'Remetente' },
    { property: 'destino', label: 'Destino' },
    { property: 'codProgDtsul', label: 'Programa', visible: false },
    { property: 'codParamAmbiente', label: 'Ambiente', visible: false },
    { property: 'arqAnexo', label: 'Anexo', visible: false },
    { property: 'id', label: 'Cód. E-mail', visible: false }
  ];

  rowActions: PoPopupAction[] = [
    { label: 'Informação', action: (row: Email) => this.abrirAba(row, 0), icon: 'an an-info' },
    { label: 'Mensagem', action: (row: Email) => this.abrirAba(row, 1), icon: 'an an-envelope-simple' },
    { label: 'Retorno', action: (row: Email) => this.abrirAba(row, 2), icon: 'an an-arrow-u-up-left' },
    { label: 'Parâmetro', action: (row: Email) => this.abrirAba(row, 3), icon: 'an an-gear' }
  ];

  ngOnInit(): void {
    this.aplicarFiltroDaUrl();
    this.paginaRestaurar = this.paginaDaUrl(this.route.snapshot.queryParams);
    this.carregar();
  }

  /** Atalho "Ver e-mails" das métricas chega como `?codProgDtsul=`. */
  private aplicarFiltroDaUrl(): void {
    const params = this.route.snapshot.queryParams;

    // Filtro completo gravado pela própria tela. Os parâmetros curtos abaixo são o
    // contrato dos atalhos vindos das métricas e prevalecem.
    this.filtro = filtroDaUrl<EmailFiltro>(params, this.chavesDoFiltro);
    if (params['chip']) {
      this.activeStatusFilter = params['chip'] as StatusFilter;
      this.filterChips.forEach(c => c.active = c.key === params['chip']);
    }

    if (params['codProgDtsul']) {
      this.filtro.codProgDtsulIni = params['codProgDtsul'];
      this.filtro.codProgDtsulFin = params['codProgDtsul'];
    }
    if (params['dtEnvioIni']) {
      this.filtro.dtEnvioInicial = params['dtEnvioIni'];
    }
    if (params['dtEnvioFin']) {
      this.filtro.dtEnvioFinal = params['dtEnvioFin'];
    }
    this.sincronizarDisclaimers();
  }

  buscaRapida(termo: string): void {
    this.paginaRestaurar = null;
    this.filtro = { ...this.filtro, texto: termo };
    this.sincronizarDisclaimers();
    this.aplicarFiltrosLocais();
    // A busca rápida é local e não passa por carregar(): grava a URL aqui.
    this.guardarFiltroNaUrl();
  }

  onFiltroAvancado(filtro: EmailFiltro): void {
    this.paginaRestaurar = null;
    this.filtro = filtro;
    this.sincronizarDisclaimers();
    this.carregar();
  }

  carregarMais(): void {
    this.page++;
    this.atualizarPagina();
    this.guardarFiltroNaUrl();
  }

  onSort(sort: PoTableColumnSort): void {
    if (!sort.column) return;
    const prop = sort.column.property as keyof Email;
    const dir = sort.type === PoTableColumnSortType.Descending ? -1 : 1;
    this.filteredItems.sort((a, b) => {
      const va = a[prop] ?? '';
      const vb = b[prop] ?? '';
      if (va < vb) return -1 * dir;
      if (va > vb) return 1 * dir;
      return 0;
    });
    this.page = 1;
    this.atualizarPagina();
  }

  abrirAba(row: Email, tab: number): void {
    this.emailDetailModal.open(row, tab);
  }

  onChipClick(chip: StatChip): void {
    this.paginaRestaurar = null;
    this.activeStatusFilter = chip.key as StatusFilter;
    this.aplicarFiltrosLocais();
    this.guardarFiltroNaUrl();
  }

  /** Assinatura da última lista de disclaimers que a própria tela montou.
   *
   *  O `po-disclaimer-group` emite `(p-change)` tanto quando o usuário remove um
   *  filtro quanto quando a lista é preenchida pela tela — é o mesmo evento. Sem
   *  distinguir os dois, abrir o monitor com filtro na URL disparava **duas**
   *  consultas idênticas: uma do `ngOnInit` e outra do handler de remoção.
   *  Lista igual à que acabamos de montar = ninguém removeu nada. */
  private assinaturaDisclaimers = '';

  private assinaturaDe(disclaimers: PoDisclaimer[]): string {
    return disclaimers.map(d => `${d.property}=${d.value}`).sort().join('|');
  }

  private sincronizarDisclaimers(): void {
    const d: PoDisclaimer[] = [];

    if (this.filtro.dtEnvioInicial && this.filtro.dtEnvioFinal) {
      d.push({ property: 'periodo', label: `Período: ${rotuloDeDataHora(this.filtro.dtEnvioInicial ?? '')} a ${rotuloDeDataHora(this.filtro.dtEnvioFinal ?? '')}`, value: 'periodo' });
    }
    if (this.filtro.idIni || this.filtro.idFin) {
      d.push({ property: 'id', label: `Cód. E-mail: ${this.filtro.idIni || '*'} a ${this.filtro.idFin || '*'}`, value: 'id' });
    }
    if (this.filtro.codProgDtsulIni || this.filtro.codProgDtsulFin) {
      d.push({ property: 'codProgDtsul', label: `Programa: ${this.filtro.codProgDtsulIni || '*'} a ${this.filtro.codProgDtsulFin || '*'}`, value: 'codProgDtsul' });
    }
    if (this.filtro.texto) {
      d.push({ property: 'texto', label: `Busca: ${this.filtro.texto}`, value: this.filtro.texto });
    }

    this.disclaimerGroup.disclaimers = d;
    this.assinaturaDisclaimers = this.assinaturaDe(d);
  }

  private onChangeDisclaimers(disclaimers: PoDisclaimer[]): void {
    // Evento disparado pela própria sincronização: nada a refazer.
    if (this.assinaturaDe(disclaimers) === this.assinaturaDisclaimers) return;
    this.assinaturaDisclaimers = this.assinaturaDe(disclaimers);

    const activeProperties = new Set(disclaimers.map(d => d.property));
    const novoFiltro: EmailFiltro = {};

    if (activeProperties.has('periodo')) {
      novoFiltro.dtEnvioInicial = this.filtro.dtEnvioInicial;
      novoFiltro.dtEnvioFinal = this.filtro.dtEnvioFinal;
    }
    if (activeProperties.has('id')) {
      novoFiltro.idIni = this.filtro.idIni;
      novoFiltro.idFin = this.filtro.idFin;
    }
    if (activeProperties.has('codProgDtsul')) {
      novoFiltro.codProgDtsulIni = this.filtro.codProgDtsulIni;
      novoFiltro.codProgDtsulFin = this.filtro.codProgDtsulFin;
    }

    disclaimers.forEach(d => {
      if (d.property === 'periodo' || d.property === 'id' || d.property === 'codProgDtsul') return;
      (novoFiltro as any)[d.property!] = d.value;
    });

    this.filtro = novoFiltro;
    this.carregar();
  }

  /** Chaves do filtro que vão e voltam pela URL. São os nomes do modelo, não os
   *  query params da API — quem traduz para a API é o service. */
  private readonly chavesDoFiltro = [
    'dtEnvioInicial',
    'dtEnvioFinal',
    'idIni',
    'idFin',
    'codProgDtsulIni',
    'codProgDtsulFin',
    'texto'
  ] as const;

  /** Filtro na URL (sem empilhar histórico): sair da tela e voltar devolvia o monitor
   *  limpo, porque a rota é lazy e o componente nasce de novo. */
  private guardarFiltroNaUrl(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        ...filtroParaUrl(this.filtro as unknown as Record<string, unknown>),
        chip: this.activeStatusFilter === 'todos' ? null : this.activeStatusFilter,
        pagina: this.paginaDesejada > 1 ? String(this.paginaDesejada) : null
      },
      replaceUrl: true
    });
  }

  /** Página restaurada da URL, aplicada no primeiro desenho da lista com dados. Morre
   *  quando o usuário mexe no filtro (busca, avançado, chip): a página só faz sentido
   *  para o resultado que estava na tela quando o link foi gerado.
   *  Só é consumida quando há o que mostrar — senão uma falha de carga (lista vazia)
   *  gastaria a restauração antes de a lista existir. */
  private paginaRestaurar: number | null = null;

  /** O que a URL deve dizer agora: a página restaurada ainda pendente ou a atual. */
  private get paginaDesejada(): number {
    return this.paginaRestaurar ?? this.page;
  }

  /** Nenhuma requisição a mais: a lista inteira já veio e a paginação é fatiada aqui,
   *  então restaurar a página é só cortar no ponto certo. */
  private paginaDaUrl(params: Record<string, string>): number | null {
    const valor = Number(params['pagina']);
    return Number.isInteger(valor) && valor > 1 ? valor : null;
  }

  private carregar(): void {
    this.guardarFiltroNaUrl();
    this.page = 1;
    this.items = [];
    this.isLoading = true;
    this.cdr.markForCheck();
    this.service.getAll(this.filtro).pipe(
      finalize(() => {
        this.isLoading = false;
        this.cdr.markForCheck();
      })
    ).subscribe({
      next: (data) => {
        this.erro = null;
        this.allItems = data ?? [];
        this.lastUpdateLabel = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        this.aplicarFiltrosLocais();
      },
      error: (err: unknown) => {
        this.allItems = [];
        this.erro = this.mensagemDeErro(err, 'Não foi possível carregar os e-mails.');
        this.aplicarFiltrosLocais();
      }
    });
  }

  private aplicarFiltrosLocais(): void {
    this.updateChipCounts();
    let filtered = [...this.allItems];

    if (this.activeStatusFilter === 'sucesso') {
      filtered = filtered.filter(e => e.logEnvio === 'Sucesso');
    } else if (this.activeStatusFilter === 'erro') {
      filtered = filtered.filter(e => e.logEnvio === 'Erro');
    } else if (this.activeStatusFilter === 'pendente') {
      filtered = filtered.filter(e => e.logEnvio === 'Pendente');
    }

    if (this.filtro.texto) {
      const termo = this.filtro.texto.toLowerCase();
      filtered = filtered.filter(e =>
        e.assunto?.toLowerCase().includes(termo) ||
        e.destino?.toLowerCase().includes(termo) ||
        e.remetente?.toLowerCase().includes(termo) ||
        e.codProgDtsul?.toLowerCase().includes(termo) ||
        e.codParamAmbiente?.toLowerCase().includes(termo)
      );
    }

    // Mais recente primeiro: a resposta da API vem agrupada (por aplicação, por
    // programa, por tabela), nunca por data. Ordena a lista inteira, que é o que
    // está carregado — não há paginação no servidor.
    this.filteredItems = maisRecentePrimeiro(filtered, 'dtEnvio');
    if (this.paginaRestaurar && this.filteredItems.length) {
      this.page = this.paginaRestaurar;
      this.paginaRestaurar = null;
    } else {
      this.page = 1;
    }
    this.atualizarPagina();
  }

  private updateChipCounts(): void {
    const all = this.allItems;
    this.filterChips[0].value = all.length;
    this.filterChips[1].value = all.filter(e => e.logEnvio === 'Sucesso').length;
    this.filterChips[2].value = all.filter(e => e.logEnvio === 'Erro').length;
    this.filterChips[3].value = all.filter(e => e.logEnvio === 'Pendente').length;
    // Nova referencia para disparar o OnPush do thl-stat-chips
    this.filterChips = [...this.filterChips];
  }

  private atualizarPagina(): void {
    const fim = this.page * this.pageSize;
    this.items = this.filteredItems.slice(0, fim);
    this.hasNext = fim < this.filteredItems.length;
  }
}

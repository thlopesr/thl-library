import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild, inject } from '@angular/core';
import {
  PoTableColumn,
  PoPopupAction,
  PoTableColumnSort,
  PoTableColumnSortType,
  PoNotificationService,
  PoDisclaimer,
  PoDisclaimerGroup,
  PoModalComponent,
  PoModule
} from '@po-ui/ng-components';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { AuditoriaService } from '../../services/auditoria.service';
import { Auditoria, AuditoriaFiltro } from '../../models/auditoria.model';
import { AuditoriaFiltroAvancadoComponent } from '../../components/auditoria-filtro-avancado/auditoria-filtro-avancado.component';
import { AuditoriaDetailComponent } from '../auditoria-detail/auditoria-detail.component';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlSearchBarComponent } from '../../../shared/components/thl-search-bar';
import { ThlRowActionsComponent } from '../../../shared/components/thl-row-actions';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { OPERACAO_LABELS, maisRecentePrimeiro } from '../../../shared/domain';
import { rotuloDeDataHora } from '../../../shared/domain/periodo';
import { filtroDaUrl, filtroParaUrl } from '../../../shared/domain/filtro-url';

type OperacaoFilter = 'todos' | 'criacao' | 'atualizacao' | 'delecao';

@Component({
  selector: 'app-auditoria-list',
  standalone: true,
  imports: [CommonModule, PoModule, AuditoriaFiltroAvancadoComponent, AuditoriaDetailComponent, ThlPageHeaderComponent, ThlStatChipsComponent, ThlSearchBarComponent, ThlRowActionsComponent, ThlErrorStateComponent, ThlEmptyStateComponent],
  templateUrl: './auditoria-list.component.html',
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
    ::ng-deep .po-table td[data-column="campos"] span {
      display: block;
      max-width: 200px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .referencia-header {
      display: inline-flex;
      align-items: center;
      gap: 4px;
    }
    .referencia-help {
      cursor: help;
      font-size: 14px;
      color: var(--color-neutral-dark-40, #718096);
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AuditoriaListComponent implements OnInit {
  @ViewChild('detailModal') detailModal!: PoModalComponent;

  private service = inject(AuditoriaService);
  private poNotification = inject(PoNotificationService);
  private cdr = inject(ChangeDetectorRef);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  items: Auditoria[] = [];
  loading = false;
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
  private allItems: Auditoria[] = [];
  private filteredItems: Auditoria[] = [];
  private page = 1;
  private readonly pageSize = 20;

  filtro: AuditoriaFiltro = {};
  activeOperacaoFilter: OperacaoFilter = 'todos';
  lastUpdateLabel = 'agora';
  selectedAuditoria: Auditoria | null = null;
  detailTitle = 'Detalhes Auditoria';
  activeTab = 0;

  disclaimerGroup: PoDisclaimerGroup = {
    title: 'Filtros',
    disclaimers: [],
    change: (disclaimers: PoDisclaimer[]) => this.onChangeDisclaimers(disclaimers)
  };

  private readonly operacaoLabels = OPERACAO_LABELS;

  filterChips: StatChip[] = [
    { key: 'todos',       label: 'Todos',        value: 0, icon: 'an an-list-dashes',  color: '#3B82F6', active: true },
    { key: 'criacao',     label: 'Criação',      value: 0, icon: 'an an-plus-circle',  color: '#16A34A', active: false },
    { key: 'atualizacao', label: 'Atualização',  value: 0, icon: 'an an-pencil-simple', color: '#F59E0B', active: false },
    { key: 'delecao',     label: 'Deleção',      value: 0, icon: 'an an-trash',        color: '#EF4444', active: false },
  ];

  readonly referenciaTooltip = 'Chave do registro auditado. Campos compostos separados por |. Ex: 4836825|0';

  columns: PoTableColumn[] = [
    { property: 'acoes', label: 'Ação', type: 'cellTemplate', width: '88px', sortable: false },
    // Largura só nas colunas de tamanho previsível, **em px**: o po-table ignora
    // porcentagem (medido em 15/10/2026 — `5%` e `20%` deram exatamente a mesma
    // largura de antes). Quem fica elástica é Campos, sem `width`: ela absorve a
    // sobra e cresce junto com a janela, que é o comportamento pedido.
    // Larguras medidas contra o conteúdo real do ambiente (16/10/2026): com 110/175/110 o
    // cabeçalho saía cortado ("Oper...", "Usuár...") e a data perdia os segundos
    // ("15:1..."). A tag "Atualização" e o usuário "ext.reginal" são os piores casos.
    { property: 'tabela', label: 'Tabela', width: '160px' },
    { property: 'operacao', label: 'Operação', type: 'label', labels: this.operacaoLabels, width: '160px' },
    { property: 'dtCriacao', label: 'Dt. Criação', type: 'dateTime', width: '200px' },
    { property: 'banco', label: 'Banco', visible: false },
    { property: 'usuario', label: 'Usuário', width: '150px' },
    { property: 'campos', label: 'Campos' },
    { property: 'referencia', label: 'Referência', tooltip: this.referenciaTooltip, width: '150px' },
    { property: 'id', label: 'ID', visible: false }
  ];

  rowActions: PoPopupAction[] = [
    { label: 'Informação', action: (row: Auditoria) => this.abrirAba(row, 0), icon: 'an an-info' },
    { label: 'Snapshot', action: (row: Auditoria) => this.abrirAba(row, 1), icon: 'an an-camera' },
    { label: 'Programa', action: (row: Auditoria) => this.abrirAba(row, 2), icon: 'an an-code' }
  ];

  ngOnInit(): void {
    this.aplicarFiltroDaUrl();
    this.paginaRestaurar = this.paginaDaUrl(this.route.snapshot.queryParams);
    this.carregar();
  }

  /** Atalho "Ver registros" das métricas chega como `?banco=&tabela=`. */
  private aplicarFiltroDaUrl(): void {
    const params = this.route.snapshot.queryParams;

    // Filtro completo gravado pela própria tela. Os parâmetros curtos abaixo são o
    // contrato dos atalhos vindos das métricas e prevalecem.
    this.filtro = filtroDaUrl<AuditoriaFiltro>(params, this.chavesDoFiltro);
    if (params['chip']) {
      this.activeOperacaoFilter = params['chip'] as OperacaoFilter;
      this.filterChips.forEach(c => c.active = c.key === params['chip']);
    }

    if (params['banco']) {
      this.filtro.bancoIni = params['banco'];
      this.filtro.bancoFin = params['banco'];
    }
    if (params['tabela']) {
      this.filtro.tabelaIni = params['tabela'];
      this.filtro.tabelaFin = params['tabela'];
    }
    if (params['dtCriacaoIni']) {
      this.filtro.dtCriacaoInicial = params['dtCriacaoIni'];
    }
    if (params['dtCriacaoFin']) {
      this.filtro.dtCriacaoFinal = params['dtCriacaoFin'];
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

  onFiltroAvancado(filtro: AuditoriaFiltro): void {
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
    const prop = sort.column.property as keyof Auditoria;
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

  abrirAba(row: Auditoria, tab: number): void {
    this.selectedAuditoria = row;
    this.activeTab = tab;
    this.detailTitle = `Detalhes Auditoria - ${row.tabela} (${row.operacao})`;
    this.detailModal.open();
  }

  onChipClick(chip: StatChip): void {
    this.paginaRestaurar = null;
    this.activeOperacaoFilter = chip.key as OperacaoFilter;
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

    if (this.filtro.dtCriacaoInicial || this.filtro.dtCriacaoFinal) {
      d.push({ property: 'periodoCriacao', label: `Dt. Criação: ${rotuloDeDataHora(this.filtro.dtCriacaoInicial ?? '') || '*'} a ${rotuloDeDataHora(this.filtro.dtCriacaoFinal ?? '') || '*'}`, value: 'periodoCriacao' });
    }
    if (this.filtro.bancoIni || this.filtro.bancoFin) {
      d.push({ property: 'banco', label: `Banco: ${this.filtro.bancoIni || '*'} a ${this.filtro.bancoFin || '*'}`, value: 'banco' });
    }
    if (this.filtro.tabelaIni || this.filtro.tabelaFin) {
      d.push({ property: 'tabela', label: `Tabela: ${this.filtro.tabelaIni || '*'} a ${this.filtro.tabelaFin || '*'}`, value: 'tabela' });
    }
    if (this.filtro.usuarioIni || this.filtro.usuarioFin) {
      d.push({ property: 'usuario', label: `Usuário: ${this.filtro.usuarioIni || '*'} a ${this.filtro.usuarioFin || '*'}`, value: 'usuario' });
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
    const novoFiltro: AuditoriaFiltro = {};

    if (activeProperties.has('periodoCriacao')) {
      novoFiltro.dtCriacaoInicial = this.filtro.dtCriacaoInicial;
      novoFiltro.dtCriacaoFinal = this.filtro.dtCriacaoFinal;
    }
    if (activeProperties.has('banco')) {
      novoFiltro.bancoIni = this.filtro.bancoIni;
      novoFiltro.bancoFin = this.filtro.bancoFin;
    }
    if (activeProperties.has('tabela')) {
      novoFiltro.tabelaIni = this.filtro.tabelaIni;
      novoFiltro.tabelaFin = this.filtro.tabelaFin;
    }
    if (activeProperties.has('usuario')) {
      novoFiltro.usuarioIni = this.filtro.usuarioIni;
      novoFiltro.usuarioFin = this.filtro.usuarioFin;
    }

    disclaimers.forEach(d => {
      if (['periodoCriacao', 'banco', 'tabela', 'usuario'].includes(d.property!)) return;
      (novoFiltro as any)[d.property!] = d.value;
    });

    this.filtro = novoFiltro;
    this.carregar();
  }

  /** Chaves do filtro que vão e voltam pela URL. São os nomes do modelo, não os
   *  query params da API — quem traduz para a API é o service. */
  private readonly chavesDoFiltro = [
    'bancoIni',
    'bancoFin',
    'tabelaIni',
    'tabelaFin',
    'dtCriacaoInicial',
    'dtCriacaoFinal',
    'usuarioIni',
    'usuarioFin',
    'texto'
  ] as const;

  /** Filtro na URL (sem empilhar histórico): sair da tela e voltar devolvia o monitor
   *  limpo, porque a rota é lazy e o componente nasce de novo. */
  private guardarFiltroNaUrl(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        ...filtroParaUrl(this.filtro as unknown as Record<string, unknown>),
        chip: this.activeOperacaoFilter === 'todos' ? null : this.activeOperacaoFilter,
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
    this.loading = true;
    this.cdr.markForCheck();
    this.service.getAll(this.filtro).subscribe({
      next: (data) => {
        this.erro = null;
        this.allItems = data;
        this.lastUpdateLabel = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        this.aplicarFiltrosLocais();
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.allItems = [];
        this.erro = this.mensagemDeErro(err, 'Não foi possível carregar a auditoria.');
        this.aplicarFiltrosLocais();
        this.loading = false;
        this.cdr.markForCheck();
      }
    });
  }

  private aplicarFiltrosLocais(): void {
    this.updateChipCounts();
    let filtered = [...this.allItems];

    if (this.activeOperacaoFilter !== 'todos') {
      const map: Record<string, string> = {
        criacao: 'Criacao', atualizacao: 'Atualizacao', delecao: 'Delecao'
      };
      const operacao = map[this.activeOperacaoFilter];
      filtered = filtered.filter(a => a.operacao === operacao);
    }

    if (this.filtro.texto) {
      const termo = this.filtro.texto.toLowerCase();
      filtered = filtered.filter(a =>
        a.tabela?.toLowerCase().includes(termo) ||
        a.operacao?.toLowerCase().includes(termo) ||
        a.banco?.toLowerCase().includes(termo) ||
        a.usuario?.toLowerCase().includes(termo) ||
        a.campos?.toLowerCase().includes(termo) ||
        a.referencia?.toLowerCase().includes(termo)
      );
    }

    // Mais recente primeiro: a resposta da API vem agrupada (por aplicação, por
    // programa, por tabela), nunca por data. Ordena a lista inteira, que é o que
    // está carregado — não há paginação no servidor.
    this.filteredItems = maisRecentePrimeiro(filtered, 'dtCriacao');
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
    this.filterChips[1].value = all.filter(a => a.operacao === 'Criacao').length;
    this.filterChips[2].value = all.filter(a => a.operacao === 'Atualizacao').length;
    this.filterChips[3].value = all.filter(a => a.operacao === 'Delecao').length;
    // Nova referencia para disparar o OnPush do thl-stat-chips
    this.filterChips = [...this.filterChips];
  }

  private atualizarPagina(): void {
    const fim = this.page * this.pageSize;
    this.items = this.filteredItems.slice(0, fim);
    this.hasNext = fim < this.filteredItems.length;
  }
}

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
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
import { MensagemService } from '../../services/mensagem.service';
import { Mensagem, MensagemFiltro } from '../../models/mensagem.model';
import { MensagemFiltroAvancadoComponent } from '../../components/mensagem-filtro-avancado/mensagem-filtro-avancado.component';
import { MessageDetailModalComponent } from '../../components/message-detail-modal/message-detail-modal.component';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import { ThlStatChipsComponent, StatChip } from '../../../shared/components/thl-stat-chips';
import { ThlSearchBarComponent } from '../../../shared/components/thl-search-bar';
import { ThlRowActionsComponent } from '../../../shared/components/thl-row-actions';
import { ThlErrorStateComponent } from '../../../shared/components/thl-error-state';
import { ThlEmptyStateComponent } from '../../../shared/components/thl-empty-state';
import { STATUS_LABELS } from '../../../shared/domain';
import { maisRecentePrimeiro } from '../../../shared/domain';
import { rotuloDeDataHora } from '../../../shared/domain/periodo';
import { filtroDaUrl, filtroParaUrl } from '../../../shared/domain/filtro-url';

type StatusFilter = 'todos' | 'sucesso' | 'erro' | 'pendente' | 'na';

/** Opção do seletor de sentido. Tipo próprio em vez do `ThlFilterTab`: aqui tooltip e
 *  ícone são obrigatórios — sem texto na tela, são eles que carregam o significado. */
interface OpcaoSentido {
  value: string;
  tooltip: string;
  icone: string;
}

@Component({
  selector: 'app-mensagem-list',
  standalone: true,
  imports: [CommonModule, PoModule, MensagemFiltroAvancadoComponent, MessageDetailModalComponent, ThlPageHeaderComponent, ThlStatChipsComponent, ThlSearchBarComponent, ThlRowActionsComponent, ThlErrorStateComponent, ThlEmptyStateComponent],
  templateUrl: './mensagem-list.component.html',
  styles: [`
    /* A faixa da engrenagem do po-table tem 60px e só o botão à direita — sobra quase a
       largura toda. O controle ocupa esse vazio em vez de criar outra linha, e é
       posicionado em relação à tabela, não ao fluxo da página: assim o alinhamento
       sobrevive ao disclaimer aparecer ou sumir (duas tentativas com deslocamento fixo
       falharam exatamente por isso).
       Sem crase neste bloco: ele vive dentro de um template literal. */
    .thl-area-tabela {
      position: relative;
      min-height: 60px;
    }

    .thl-sentido {
      position: absolute;
      top: 10px;
      /* Encostado na engrenagem, que ocupa 60px na ponta direita da faixa. */
      right: 60px;
      z-index: 1;
      display: flex;
      gap: 2px;
    }

    /* Mesmo molde do botão da engrenagem, medido no navegador: 44px de altura, fundo e
       borda transparentes, raio 4px e ícone de 24px na cor de ação do tema. O ativo fica
       nessa cor; os outros em cinza, que é o único sinal possível sem borda nem fundo. */
    .thl-sentido__botao {
      width: 44px;
      height: 44px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 0;
      border: none;
      border-radius: 4px;
      background: none;
      cursor: pointer;
      font-size: 24px;
      /* Mesma cor da engrenagem nos três. Sem borda, sem texto e sem diferença de cor,
         o que marca o escolhido é o fundo suave — e os desenhos (ambos, decolagem,
         pouso) já se distinguem entre si. */
      color: #045b8f;
      transition: background-color 150ms ease;
    }

    .thl-sentido__botao:hover {
      background: rgba(4, 91, 143, 0.08);
    }

    .thl-sentido__botao:focus-visible {
      outline: 2px solid #045b8f;
      outline-offset: 1px;
    }

    .thl-sentido__botao--ativo {
      background: rgba(4, 91, 143, 0.14);
    }

    .thl-dispositivo {
      display: inline-flex;
      align-items: center;
      gap: 7px;
    }

    .thl-dispositivo .an {
      font-size: 17px;
      color: #4a5568;
    }

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
    ::ng-deep .po-table td[data-column="destino"] span {
      display: block;
      max-width: 160px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MensagemListComponent implements OnInit {
  @ViewChild('messageDetailModal') messageDetailModal!: MessageDetailModalComponent;

  private service = inject(MensagemService);
  private poNotification = inject(PoNotificationService);
  private cdr = inject(ChangeDetectorRef);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  items: Mensagem[] = [];
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
  private allItems: Mensagem[] = [];
  private filteredItems: Mensagem[] = [];
  private page = 1;
  private readonly pageSize = 20;

  filtro: MensagemFiltro = {};
  activeStatusFilter: StatusFilter = 'todos';
  lastUpdateLabel = 'agora';

  disclaimerGroup: PoDisclaimerGroup = {
    title: 'Filtros',
    disclaimers: [],
    change: (disclaimers: PoDisclaimer[]) => this.onChangeDisclaimers(disclaimers)
  };

  private readonly statusLabels = STATUS_LABELS;

  filterChips: StatChip[] = [
    { key: 'todos',    label: 'Todos',    value: 0, icon: 'an an-list-dashes',  color: '#3B82F6', active: true },
    { key: 'sucesso',  label: 'Sucesso',  value: 0, icon: 'an an-check-circle', color: '#16A34A', active: false },
    { key: 'erro',     label: 'Erro',     value: 0, icon: 'an an-x-circle',     color: '#EF4444', active: false },
    { key: 'pendente', label: 'Pendente', value: 0, icon: 'an an-clock',        color: '#F59E0B', active: false },
    { key: 'na',       label: 'N/A',      value: 0, icon: 'an an-minus-circle', color: '#9CA3AF', active: false },
  ];

  columns: PoTableColumn[] = [
    { property: 'acoes', label: 'Ação', type: 'cellTemplate', width: '88px', sortable: false },
    { property: 'aplicacao', label: 'Aplicação' },
    { property: 'objeto', label: 'Objeto' },
    { property: 'operacao', label: 'Operação' },
    { property: 'metodo', label: 'Método' },
    // `columnTemplate` é obrigatório para a diretiva `p-table-column-template` entrar
    // (está na doc do próprio po-table). Sem ele, a célula volta a ser texto puro.
    { property: 'dispositivo', label: 'Dispositivo', type: 'columnTemplate' },
    { property: 'statusRequisicao', label: 'Requisição', type: 'label', labels: this.statusLabels },
    { property: 'statusRetorno', label: 'Retorno', type: 'label', labels: this.statusLabels },
    { property: 'statusProcessamento', label: 'Processamento', type: 'label', labels: this.statusLabels },
    { property: 'dtCriacao', label: 'Dt. Criação', type: 'dateTime', format: 'dd/MM/yyyy HH:mm:ss' },
    { property: 'dtIntegracao', label: 'Dt. Integração', type: 'dateTime', format: 'dd/MM/yyyy HH:mm:ss' },
    { property: 'destino', label: 'Destino', width: '160px' },
    { property: 'codStatusRetorno', label: 'Código do status', type: 'number', visible: false },
    { property: 'descrRetorno', label: 'Descrição do retorno', visible: false },
    { property: 'codMsg', label: 'Cód. Msg', visible: false },
    { property: 'modelo', label: 'Modelo', visible: false }
  ];

  rowActions: PoPopupAction[] = [
    { label: 'Informação', action: (row: Mensagem) => this.abrirAba(row, 0), icon: 'an an-list-dashes' },
    { label: 'Retorno', action: (row: Mensagem) => this.abrirAba(row, 1), icon: 'an an-arrow-u-up-left' },
    { label: 'Conteúdo Saída', action: (row: Mensagem) => this.abrirAba(row, 2), icon: 'an an-arrow-square-out', disabled: (row: Mensagem) => !row.conteudo?.temRequisicao },
    { label: 'Conteúdo Entrada', action: (row: Mensagem) => this.abrirAba(row, 3), icon: 'an an-arrow-square-in', disabled: (row: Mensagem) => !row.conteudo?.temResposta }
  ];

  ngOnInit(): void {
    const params = this.route.snapshot.queryParams;

    // Filtro completo gravado pela própria tela. Os parâmetros curtos logo abaixo
    // (`aplicacao`, `objeto`, `dispositivo`…) são o contrato dos atalhos vindos das
    // métricas e prevalecem, por serem a intenção explícita de quem clicou.
    this.filtro = filtroDaUrl<MensagemFiltro>(params, this.chavesDoFiltro, ['codStatusRetorno']);
    if (params['chip']) {
      this.activeStatusFilter = params['chip'] as StatusFilter;
      this.filterChips.forEach(c => c.active = c.key === params['chip']);
    }

    if (params['aplicacao']) {
      this.filtro.aplicacaoIni = params['aplicacao'];
      this.filtro.aplicacaoFin = params['aplicacao'];
    }
    if (params['objeto']) {
      this.filtro.objetoIni = params['objeto'];
      this.filtro.objetoFin = params['objeto'];
    }
    if (params['dispositivo']) {
      this.filtro.dispositivo = params['dispositivo'];
    }
    if (params['dtCriacaoIni']) {
      this.filtro.dtCriacaoInicial = params['dtCriacaoIni'];
    }
    if (params['dtCriacaoFin']) {
      this.filtro.dtCriacaoFinal = params['dtCriacaoFin'];
    }
    if (params['statusProcessamento']) {
      this.filtro.statusProcessamento = params['statusProcessamento'];
      if (params['statusProcessamento'] === 'Erro') {
        this.activeStatusFilter = 'erro';
        // Por chave, não por índice: reordenar os chips acenderia o chip errado.
        this.filterChips.forEach(c => c.active = c.key === 'erro');
      }
    }
    this.paginaRestaurar = this.paginaDaUrl(params);
    this.sincronizarDisclaimers();
    this.carregar();
  }

  buscaRapida(termo: string): void {
    this.paginaRestaurar = null;
    this.filtro = { ...this.filtro, texto: termo };
    this.sincronizarDisclaimers();
    this.aplicarFiltrosLocais();
    // A busca rápida é local e não passa por carregar(): grava a URL aqui.
    this.guardarFiltroNaUrl();
  }

  onFiltroAvancado(filtro: MensagemFiltro): void {
    this.paginaRestaurar = null;
    this.filtro = filtro;
    this.sincronizarDisclaimers();
    this.carregar();
  }

  /** Sentido do fluxo: eixo **separado** dos chips de situação, para os dois se
   *  combinarem ("erros de saída"). Se fosse mais um chip, escolher o sentido apagaria
   *  a situação, já que os chips são mutuamente exclusivos.
   *  ⚠️ `dispositivo` **não vai para a API** (o `MensagemService` não o envia): filtra o
   *  que já foi carregado, como o mesmo campo no filtro avançado. */
  readonly opcoesSentido: OpcaoSentido[] = [
    // Só os símbolos: o controle mora na faixa da engrenagem do `po-table`, que já existe
    // e estava vazia — texto ali competiria com a tabela logo abaixo. O rótulo "Sentido"
    // fica, porque é ele que torna os três ícones legíveis; o significado de cada um vai
    // no tooltip e no `aria-label`.
    { value: '', tooltip: 'Entrada e saída', icone: 'an an-arrows-left-right' },
    { value: 'Saida', tooltip: 'Só saída', icone: 'an an-airplane-takeoff' },
    { value: 'Entrada', tooltip: 'Só entrada', icone: 'an an-airplane-landing' }
  ];

  /** Derivado do filtro, não um estado à parte: mudar pelo filtro avançado ou tirar o
   *  disclaimer move o segmento junto, sem precisar sincronizar nada. */
  get sentidoSelecionado(): string {
    return this.filtro.dispositivo ?? '';
  }

  aoMudarSentido(valor: string): void {
    this.paginaRestaurar = null;
    this.filtro = { ...this.filtro, dispositivo: valor || undefined };
    this.sincronizarDisclaimers();
    this.aplicarFiltrosLocais();
    this.guardarFiltroNaUrl();
  }

  carregarMais(): void {
    this.page++;
    this.atualizarPagina();
    this.guardarFiltroNaUrl();
  }

  recarregar(): void {
    this.carregar();
  }

  onSort(sort: PoTableColumnSort): void {
    if (!sort.column) return;
    const prop = sort.column.property as keyof Mensagem;
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

  abrirAba(row: Mensagem, tab: number): void {
    this.messageDetailModal.open(row, tab);
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

    if (this.filtro.dtIntegracaoInicial || this.filtro.dtIntegracaoFinal) {
      d.push({ property: 'periodoIntegracao', label: `Dt. Integração: ${this.filtro.dtIntegracaoInicial || '*'} a ${this.filtro.dtIntegracaoFinal || '*'}`, value: 'periodoIntegracao' });
    }
    if (this.filtro.dtCriacaoInicial || this.filtro.dtCriacaoFinal) {
      d.push({ property: 'periodoCriacao', label: `Dt. Criação: ${rotuloDeDataHora(this.filtro.dtCriacaoInicial ?? '') || '*'} a ${rotuloDeDataHora(this.filtro.dtCriacaoFinal ?? '') || '*'}`, value: 'periodoCriacao' });
    }
    if (this.filtro.codMsgIni || this.filtro.codMsgFin) {
      d.push({ property: 'codMsg', label: `Cód. Msg: ${this.filtro.codMsgIni || '*'} a ${this.filtro.codMsgFin || '*'}`, value: 'codMsg' });
    }
    if (this.filtro.objetoIni || this.filtro.objetoFin) {
      d.push({ property: 'objeto', label: `Objeto: ${this.filtro.objetoIni || '*'} a ${this.filtro.objetoFin || '*'}`, value: 'objeto' });
    }
    if (this.filtro.operacaoIni || this.filtro.operacaoFin) {
      d.push({ property: 'operacao', label: `Operação: ${this.filtro.operacaoIni || '*'} a ${this.filtro.operacaoFin || '*'}`, value: 'operacao' });
    }
    if (this.filtro.aplicacaoIni || this.filtro.aplicacaoFin) {
      d.push({ property: 'aplicacao', label: `Aplicação: ${this.filtro.aplicacaoIni || '*'} a ${this.filtro.aplicacaoFin || '*'}`, value: 'aplicacao' });
    }
    if (this.filtro.metodo) {
      d.push({ property: 'metodo', label: `Método: ${this.filtro.metodo}`, value: this.filtro.metodo });
    }
    if (this.filtro.dispositivo) {
      d.push({ property: 'dispositivo', label: `Dispositivo: ${this.filtro.dispositivo}`, value: this.filtro.dispositivo });
    }
    if (this.filtro.statusRequisicao) {
      d.push({ property: 'statusRequisicao', label: `Requis.: ${this.filtro.statusRequisicao}`, value: this.filtro.statusRequisicao });
    }
    if (this.filtro.statusRetorno) {
      d.push({ property: 'statusRetorno', label: `Retorno: ${this.filtro.statusRetorno}`, value: this.filtro.statusRetorno });
    }
    if (this.filtro.statusProcessamento) {
      d.push({ property: 'statusProcessamento', label: `Proces.: ${this.filtro.statusProcessamento}`, value: this.filtro.statusProcessamento });
    }
    if (this.filtro.codStatusRetorno) {
      d.push({ property: 'codStatusRetorno', label: `Cód. Status: ${this.filtro.codStatusRetorno}`, value: String(this.filtro.codStatusRetorno) });
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
    const novoFiltro: MensagemFiltro = {};

    if (activeProperties.has('periodoIntegracao')) {
      novoFiltro.dtIntegracaoInicial = this.filtro.dtIntegracaoInicial;
      novoFiltro.dtIntegracaoFinal = this.filtro.dtIntegracaoFinal;
    }
    if (activeProperties.has('periodoCriacao')) {
      novoFiltro.dtCriacaoInicial = this.filtro.dtCriacaoInicial;
      novoFiltro.dtCriacaoFinal = this.filtro.dtCriacaoFinal;
    }

    if (activeProperties.has('codMsg')) {
      novoFiltro.codMsgIni = this.filtro.codMsgIni;
      novoFiltro.codMsgFin = this.filtro.codMsgFin;
    }
    if (activeProperties.has('objeto')) {
      novoFiltro.objetoIni = this.filtro.objetoIni;
      novoFiltro.objetoFin = this.filtro.objetoFin;
    }
    if (activeProperties.has('operacao')) {
      novoFiltro.operacaoIni = this.filtro.operacaoIni;
      novoFiltro.operacaoFin = this.filtro.operacaoFin;
    }
    if (activeProperties.has('aplicacao')) {
      novoFiltro.aplicacaoIni = this.filtro.aplicacaoIni;
      novoFiltro.aplicacaoFin = this.filtro.aplicacaoFin;
    }

    disclaimers.forEach(d => {
      if (['periodoIntegracao', 'periodoCriacao', 'codMsg', 'objeto', 'operacao', 'aplicacao'].includes(d.property!)) return;
      if (d.property === 'codStatusRetorno') {
        novoFiltro.codStatusRetorno = Number(d.value);
      } else {
        (novoFiltro as any)[d.property!] = d.value;
      }
    });

    this.filtro = novoFiltro;
    this.carregar();
  }

  /** Chaves do filtro que vão e voltam pela URL. São os nomes do modelo, não os
   *  query params da API — quem traduz para a API é o service. */
  private readonly chavesDoFiltro = [
    'dtIntegracaoInicial',
    'dtIntegracaoFinal',
    'dtCriacaoInicial',
    'dtCriacaoFinal',
    'codMsgIni',
    'codMsgFin',
    'objetoIni',
    'objetoFin',
    'operacaoIni',
    'operacaoFin',
    'aplicacaoIni',
    'aplicacaoFin',
    'metodo',
    'dispositivo',
    'statusRequisicao',
    'statusRetorno',
    'statusProcessamento',
    'codStatusRetorno',
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
    this.loading = true;
    this.cdr.markForCheck();
    this.service.getAll(this.filtro).pipe(
      finalize(() => {
        this.loading = false;
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
        this.erro = this.mensagemDeErro(err, 'Não foi possível carregar as mensagens.');
        this.aplicarFiltrosLocais();
      }
    });
  }

  private aplicarFiltrosLocais(): void {
    this.updateChipCounts();
    let filtered = [...this.allItems];

    if (this.activeStatusFilter === 'sucesso') {
      filtered = filtered.filter(m =>
        m.statusRequisicao === 'Sucesso' &&
        m.statusRetorno === 'Sucesso' &&
        m.statusProcessamento === 'Sucesso'
      );
    } else if (this.activeStatusFilter === 'erro') {
      filtered = filtered.filter(m =>
        m.statusRequisicao === 'Erro' ||
        m.statusRetorno === 'Erro' ||
        m.statusProcessamento === 'Erro'
      );
    } else if (this.activeStatusFilter === 'pendente') {
      filtered = filtered.filter(m =>
        m.statusRequisicao === 'Pendente' ||
        m.statusRetorno === 'Pendente' ||
        m.statusProcessamento === 'Pendente'
      );
    } else if (this.activeStatusFilter === 'na') {
      filtered = filtered.filter(m =>
        m.statusRequisicao === 'N/A' ||
        m.statusRetorno === 'N/A' ||
        m.statusProcessamento === 'N/A'
      );
    }

    if (this.filtro.metodo) {
      filtered = filtered.filter(m => m.metodo === this.filtro.metodo);
    }
    if (this.filtro.dispositivo) {
      filtered = filtered.filter(m => m.dispositivo === this.filtro.dispositivo);
    }
    if (this.filtro.statusRequisicao) {
      filtered = filtered.filter(m => m.statusRequisicao === this.filtro.statusRequisicao);
    }
    if (this.filtro.statusRetorno) {
      filtered = filtered.filter(m => m.statusRetorno === this.filtro.statusRetorno);
    }
    if (this.filtro.statusProcessamento) {
      filtered = filtered.filter(m => m.statusProcessamento === this.filtro.statusProcessamento);
    }
    if (this.filtro.codStatusRetorno) {
      filtered = filtered.filter(m => m.codStatusRetorno === this.filtro.codStatusRetorno);
    }
    if (this.filtro.texto) {
      const termo = this.filtro.texto.toLowerCase();
      filtered = filtered.filter(m =>
        m.codMsg?.toLowerCase().includes(termo) ||
        m.descrRetorno?.toLowerCase().includes(termo) ||
        m.objeto?.toLowerCase().includes(termo) ||
        m.operacao?.toLowerCase().includes(termo) ||
        m.destino?.toLowerCase().includes(termo)
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
    this.filterChips[1].value = all.filter(m =>
      m.statusRequisicao === 'Sucesso' && m.statusRetorno === 'Sucesso' && m.statusProcessamento === 'Sucesso'
    ).length;
    this.filterChips[2].value = all.filter(m =>
      m.statusRequisicao === 'Erro' || m.statusRetorno === 'Erro' || m.statusProcessamento === 'Erro'
    ).length;
    this.filterChips[3].value = all.filter(m =>
      m.statusRequisicao === 'Pendente' || m.statusRetorno === 'Pendente' || m.statusProcessamento === 'Pendente'
    ).length;
    this.filterChips[4].value = all.filter(m =>
      m.statusRequisicao === 'N/A' || m.statusRetorno === 'N/A' || m.statusProcessamento === 'N/A'
    ).length;
    // Nova referencia para disparar o OnPush do thl-stat-chips
    this.filterChips = [...this.filterChips];
  }

  private atualizarPagina(): void {
    const fim = this.page * this.pageSize;
    this.items = this.filteredItems.slice(0, fim);
    this.hasNext = fim < this.filteredItems.length;
  }
}

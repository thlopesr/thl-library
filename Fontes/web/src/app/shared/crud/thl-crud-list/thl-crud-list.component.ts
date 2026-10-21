import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnChanges, OnInit, Output,
  QueryList, SimpleChanges, TemplateRef, ViewChild, ViewChildren, inject
} from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { finalize, forkJoin, map, of } from 'rxjs';
import {
  ForceOptionComponentEnum, PoButtonGroupItem, PoDialogService, PoDynamicFormComponent, PoDynamicFormField,
  PoModalAction, PoModalComponent, PoModule, PoNotificationService, PoPopupAction, PoRichTextToolbarActions,
  PoTableColumn, PoTableColumnLabel, PoTagType
} from '@po-ui/ng-components';
import { ThlRowActionsComponent } from '../../components/thl-row-actions';
import { ThlErrorStateComponent } from '../../components/thl-error-state';
import { ThlEmptyStateComponent } from '../../components/thl-empty-state';
import { CrudField, CrudLink, CrudOption, CrudResource, CrudRow } from '../crud.model';
import { CrudService } from '../crud.service';

const SUFIXO_ROTULO = '__rotulo';

interface Aba<T> {
  titulo: string;
  fields: T[];
}

interface CampoEditor {
  campo: CrudField;
  /** O valor estava em texto puro e foi convertido para HTML ao abrir o editor. */
  convertido: boolean;
}

interface CampoHtml {
  label: string;
  conteudo: string;
  /** Texto puro preserva as quebras; HTML não, senão as quebras entre tags viram espaços. */
  textoPuro: boolean;
  /** Alternador do bloco: conteúdo renderizado ou código-fonte. Só existe quando há marcação. */
  modo: 'visual' | 'codigo';
  botoes: PoButtonGroupItem[];
}

@Component({
  selector: 'thl-crud-list',
  standalone: true,
  imports: [FormsModule, NgTemplateOutlet, PoModule, ThlRowActionsComponent,
    ThlErrorStateComponent, ThlEmptyStateComponent],
  templateUrl: './thl-crud-list.component.html',
  styleUrls: ['../../styles/thl-vinculos.scss'],
  // As linhas do grid PO UI têm margem negativa e criavam rolagem horizontal dentro do modal.
  styles: [`
    .thl-crud-form { overflow-x: hidden; padding: 0 8px; }
    .thl-crud-html__cabecalho { display: flex; align-items: center; justify-content: flex-end; gap: 8px; margin: 8px 0 4px; }
    .thl-crud-html__titulo { color: var(--color-neutral-mid-60); }
    .thl-crud-html {
      padding: 12px;
      border: 1px solid var(--color-neutral-light-20);
      border-radius: 4px;
      background: var(--color-neutral-light-00);
      overflow-x: auto;
    }
    .thl-crud-html--texto { white-space: pre-wrap; }
    .thl-crud-html--codigo {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      font-family: monospace;
      font-size: 12px;
      color: var(--color-neutral-dark-70);
    }
    .thl-crud-html--vazio { color: var(--color-neutral-mid-60); }
    .thl-crud-erro {
      display: flex; flex-direction: column; align-items: flex-start; gap: 8px;
      padding: 24px; border: 1px solid var(--color-neutral-light-20); border-radius: 4px;
      background: var(--color-neutral-light-00);
    }
    .thl-crud-erro__titulo { font-weight: 600; }
    .thl-crud-erro__detalhe { color: var(--color-neutral-mid-60); }
    .thl-crud-aviso { margin-top: 8px; color: var(--color-neutral-mid-60); font-size: 12px; }
    .thl-crud-editor__aviso {
      margin: 8px 0;
      padding: 8px 12px;
      border-left: 3px solid var(--color-warning);
      background: var(--color-neutral-light-05);
      color: var(--color-neutral-dark-70);
      font-size: 12px;
    }
    /* ::ng-deep porque o conteúdo vem por [innerHTML] e não recebe o escopo do componente. */
    .thl-crud-html ::ng-deep :is(img, table) { max-width: 100%; }
    /* O tema zera o recuo das listas: sem isto os marcadores ficam fora do bloco. */
    .thl-crud-html ::ng-deep :is(ul, ol) { padding-left: 24px; list-style-position: outside; }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlCrudListComponent implements OnInit, OnChanges {
  @Input({ required: true }) def!: CrudResource;
  /** Registro pai (abas de filhos): fornece a chave herdada e o filtro. */
  @Input() parent: CrudRow | null = null;
  /** 'pagina' = browse principal; 'aba' = filhos dentro da linha expandida. */
  @Input() modo: 'pagina' | 'aba' = 'aba';
  /** Busca local (modo página). */
  @Input() termo = '';
  /** Filtro vindo da URL (`?aplicacao=THL`), aplicado no GET como `<campo>Ini/Fin`. */
  @Input() filtroUrl: Record<string, string> = {};
  // O po-table criado dentro de um po-tab oculto fica em branco; só renderiza com a aba visível.
  @Input() visivel = true;
  /** Conteúdo da linha expandida; sem ele a tabela não tem seta. */
  @Input() expandTemplate: TemplateRef<unknown> | null = null;
  @Output() countChange = new EventEmitter<number>();

  @ViewChild('modalForm') modalForm!: PoModalComponent;
  @ViewChild('modalDetalhe') modalDetalhe!: PoModalComponent;
  @ViewChildren(PoDynamicFormComponent) dynamicForms?: QueryList<PoDynamicFormComponent>;

  private service = inject(CrudService);
  private poNotification = inject(PoNotificationService);
  private poDialog = inject(PoDialogService);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);

  items: CrudRow[] = [];
  /** Mensagem do backend quando o carregamento falha: erro e lista vazia não podem se parecer. */
  erro: string | null = null;
  /** A API devolveu mais registros do que os carregados. */
  temMais = false;
  visiveis: CrudRow[] = [];
  isLoading = false;

  columns: PoTableColumn[] = [];
  rowActions: PoPopupAction[] = [];

  editando = false;
  formAberto = false;
  formFields: PoDynamicFormField[] = [];
  registro: CrudRow = {};

  abasForm: Aba<PoDynamicFormField>[] = [];
  /** Campos `richText` do formulário, por título de aba (toda aba tem entrada, mesmo vazia). */
  editoresForm: Record<string, CampoEditor[]> = {};
  /** O `po-rich-text` não desenha dentro de aba oculta: só renderiza o da aba aberta. */
  abaFormAtiva = '';
  abasDetalhe: Aba<PoDynamicFormField>[] = [];
  /** Esconder todas as ações faz o `po-rich-text` omitir a barra: fica só a moldura, em leitura. */
  readonly semBarraEdicao = Object.values(PoRichTextToolbarActions);
  /** Campos `html` do Detalhar, por título de aba (toda aba tem entrada, mesmo vazia). */
  htmlDetalhe: Record<string, CampoHtml[]> = {};
  detalhe: CrudRow = {};

  readonly salvarAction: PoModalAction = { label: 'Salvar', action: () => this.salvar() };
  readonly cancelarAction: PoModalAction = { label: 'Cancelar', action: () => this.fecharForm() };
  readonly fecharDetalheAction: PoModalAction = { label: 'Fechar', action: () => this.modalDetalhe.close() };

  /** Borda só no browse principal; nas abas a tabela fica sem container. */
  get containerTabela(): string {
    return this.modo === 'pagina' ? 'border' : (undefined as unknown as string);
  }

  get podeAdicionar(): boolean {
    return !(this.def.single && this.items.length > 0);
  }

  get tituloForm(): string {
    const novo = this.def.feminine ? 'Nova' : 'Novo';
    return `${this.editando ? 'Editar' : novo} ${this.def.singular}`;
  }

  get textoVinculos(): string {
    const vinculado = this.def.feminine ? 'vinculada' : 'vinculado';
    return `${this.def.title} ${this.def.single ? vinculado : vinculado + 's'}`;
  }

  /** Vazio por filtro e vazio por cadastro novo pedem orientações diferentes:
   *  um pede ajustar o filtro, o outro pede criar o primeiro registro. */
  get vazioFiltrado(): boolean {
    return !!this.termo.trim() || Object.keys(this.filtroUrl).length > 0;
  }

  get vazioTitulo(): string {
    if (this.vazioFiltrado) {
      return 'Nenhum registro corresponde ao filtro';
    }
    const f = this.def.feminine;
    return (f ? 'Nenhuma ' : 'Nenhum ') + this.def.singular.toLowerCase() + (f ? ' cadastrada' : ' cadastrado');
  }

  get vazioDescricao(): string {
    return this.vazioFiltrado
      ? 'Ajuste o texto do filtro ou limpe-o para ver todos os registros carregados.'
      : 'Use "Adicionar" para criar o primeiro registro.';
  }

  get textoVazio(): string {
    const nenhum = this.def.feminine ? 'Nenhuma' : 'Nenhum';
    const vinculado = this.def.feminine ? 'vinculada' : 'vinculado';
    return `${nenhum} ${this.def.singular} ${vinculado}.`;
  }

  ngOnInit(): void {
    this.columns = [
      { property: 'acoes', label: 'Ação', type: 'cellTemplate', width: '88px', sortable: false },
      ...this.def.fields.filter(f => f.column).map(f => this.toColumn(f))
    ];

    const temOcultos = this.def.fields.some(f => !f.column);
    this.rowActions = [
      ...(temOcultos ? [{ label: 'Detalhar', icon: 'an an-eye', action: (row: CrudRow) => this.abrirDetalhe(row) }] : []),
      ...(this.def.noUpdate ? [] : [{ label: 'Editar', icon: 'an an-pencil-simple', action: (row: CrudRow) => this.abrirEdicao(row) }]),
      { label: 'Excluir', icon: 'an an-trash', type: 'danger', action: (row: CrudRow) => this.confirmarExclusao(row) },
      ...(this.def.links ?? []).map(link => ({
        label: link.label,
        icon: link.icon,
        action: (row: CrudRow) => this.abrirLink(link, row)
      }))
    ];

    this.carregar();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['termo'] && !changes['termo'].firstChange) {
      this.filtrar();
    }
    if (changes['filtroUrl'] && !changes['filtroUrl'].firstChange) {
      this.carregar();
    }
  }

  abrirNovo(): void {
    this.editando = false;
    this.registro = {};
    for (const f of this.def.fields) {
      this.registro[f.property] = f.default ?? (f.type === 'boolean' ? false : f.type === 'number' ? 0 : '');
    }
    this.abrirForm();
  }

  private abrirEdicao(row: CrudRow): void {
    this.editando = true;
    this.registro = {};
    for (const f of this.def.fields) {
      this.registro[f.property] = row[f.property];
    }
    this.abrirForm();
  }

  private abrirForm(): void {
    const zooms = this.def.fields.filter(f => f.optionsFrom);
    const carregar = zooms.length
      ? forkJoin(zooms.map(f => this.service.list(f.optionsFrom!.resource).pipe(map(res => this.toOptions(f, res.items)))))
      : of([] as CrudOption[][]);

    carregar.subscribe({
      next: listas => this.montarForm(zooms, listas),
      // Sem o zoom o campo vira texto livre; o backend valida ao salvar.
      error: () => this.montarForm([], [])
    });
  }

  private montarForm(zooms: CrudField[], listas: CrudOption[][]): void {
    // Campos com editor saem do formulário dinâmico e viram um bloco próprio na mesma aba.
    const editores = this.def.fields.filter(f => f.richText);
    const comuns = this.def.fields.filter(f => !f.richText);

    this.editoresForm = {};
    for (const f of editores) {
      const aba = f.tab ?? 'Geral';
      const conteudo = String(this.registro[f.property] ?? '');
      const textoPuro = !!conteudo && !/<[a-z][^>]*>/i.test(conteudo);
      // Texto puro no editor viraria uma linha só: as quebras precisam virar marcação.
      if (textoPuro) {
        this.registro[f.property] = conteudo.replace(/\r?\n/g, '<br>');
      }
      this.editoresForm[aba] = [...(this.editoresForm[aba] ?? []), { campo: f, convertido: textoPuro }];
    }

    let grupoAnterior: string | undefined;
    const campos = comuns.map(f => {
      const i = zooms.indexOf(f);
      const options = i >= 0 ? [...(f.optionsFromExtra ?? []), ...listas[i]] : f.options;
      const divider = f.group && f.group !== grupoAnterior ? f.group : undefined;
      grupoAnterior = f.group;
      return {
        property: f.property,
        label: f.label,
        type: f.type === 'number' ? 'number' : f.type === 'boolean' ? 'boolean' : 'string',
        required: !!(f.required || f.key),
        disabled: this.editando && !!f.key,
        secret: f.type === 'password',
        rows: f.type === 'textarea' ? 4 : undefined,
        booleanTrue: 'Sim',
        booleanFalse: 'Não',
        maxLength: f.maxLength,
        pattern: f.pattern,
        errorMessage: f.errorMessage,
        options,
        // Sem isto o formulário dinâmico usa botões de rádio quando há até 3 opções.
        forceOptionsComponentType: options ? ForceOptionComponentEnum.select : undefined,
        help: f.help,
        icon: f.icon,
        placeholder: f.placeholder,
        clean: f.clean,
        divider,
        gridColumns: f.gridColumns ?? (f.type === 'textarea' ? 12 : 6)
      } as PoDynamicFormField;
    });

    // O `tab` pode estar só no campo com editor (ex.: a aba Mensagem do e-mail).
    this.abasForm = this.agrupar(comuns, campos, this.def.fields.some(f => f.tab));
    for (const aba of Object.keys(this.editoresForm)) {
      if (!this.abasForm.some(a => a.titulo === aba)) {
        this.abasForm.push({ titulo: aba, fields: [] });
      }
    }
    for (const aba of this.abasForm) {
      this.editoresForm[aba.titulo] ??= [];
    }
    this.abaFormAtiva = this.abasForm[0]?.titulo ?? '';
    this.formAberto = true;
    this.cdr.markForCheck();
    this.modalForm.open();
  }

  private fecharForm(): void {
    this.modalForm.close();
    this.formAberto = false;
    this.cdr.markForCheck();
  }

  private salvar(): void {
    // Uma instância por aba: o campo pendente pode estar numa aba ainda não aberta.
    if (this.dynamicForms?.some(f => !!f.form?.invalid)) {
      this.poNotification.warning('Preencha os campos obrigatórios. Verifique todas as abas.');
      return;
    }
    const corpo = { ...this.chavePai(), ...this.registro };
    const op = this.editando
      ? this.service.update(this.def.resource, corpo)
      : this.service.create(this.def.resource, corpo);

    op.subscribe({
      next: () => {
        this.poNotification.success(this.editando ? 'Registro atualizado.' : 'Registro incluído.');
        this.fecharForm();
        this.carregar();
      },
      error: () => this.poNotification.error(`Erro ao salvar ${this.def.singular}.`)
    });
  }

  private abrirDetalhe(row: CrudRow): void {
    // Campos `html` saem do po-dynamic-view e vão para um bloco próprio na mesma aba.
    const comuns = this.def.fields.filter(f => !f.html);
    let grupoAnterior: string | undefined;
    const campos = comuns.map(f => {
      const divider = f.group && f.group !== grupoAnterior ? f.group : undefined;
      grupoAnterior = f.group;
      // Mesma moldura do formulário: campo de texto em leitura, com o valor já traduzido por `exibir`.
      return {
        property: f.property,
        label: f.label,
        type: 'string',
        readonly: true,
        icon: f.icon,
        rows: f.type === 'textarea' ? 4 : undefined,
        divider,
        gridColumns: f.gridColumns ?? (f.type === 'textarea' ? 12 : 6)
      } as PoDynamicFormField;
    });

    this.htmlDetalhe = {};
    for (const f of this.def.fields.filter(campo => campo.html)) {
      const aba = f.tab ?? 'Geral';
      const conteudo = String(row[f.property] ?? '');
      const campo: CampoHtml = {
        label: f.label, conteudo, textoPuro: !/<[a-z][^>]*>/i.test(conteudo), modo: 'visual', botoes: []
      };
      campo.botoes = [
        { label: 'Visualizar', icon: 'an an-eye', selected: true, action: () => this.verHtml(campo, 'visual') },
        { label: 'Código', icon: 'an an-code', action: () => this.verHtml(campo, 'codigo') }
      ];
      this.htmlDetalhe[aba] = [...(this.htmlDetalhe[aba] ?? []), campo];
    }

    // O `tab` pode estar só num campo html (ex.: a aba Mensagem do e-mail).
    this.abasDetalhe = this.agrupar(comuns, campos, this.def.fields.some(f => f.tab));
    for (const aba of Object.keys(this.htmlDetalhe)) {
      if (!this.abasDetalhe.some(a => a.titulo === aba)) {
        this.abasDetalhe.push({ titulo: aba, fields: [] });
      }
    }
    for (const aba of this.abasDetalhe) {
      this.htmlDetalhe[aba.titulo] ??= [];
    }

    this.detalhe = {};
    for (const f of this.def.fields) {
      this.detalhe[f.property] = this.exibir(f, row[f.property]);
    }
    this.cdr.markForCheck();
    this.modalDetalhe.open();
  }

  /** Alterna entre o conteúdo renderizado e o código-fonte no Detalhar. */
  verHtml(campo: CampoHtml, modo: 'visual' | 'codigo'): void {
    campo.modo = modo;
    this.cdr.markForCheck();
  }

  private confirmarExclusao(row: CrudRow): void {
    const chave = this.chaveDe(row);
    const descricao = this.def.fields.filter(f => f.key).map(f => row[f.property]).join(' / ') || this.def.singular;
    const cascata = this.def.cascadeDelete ? ` Também serão excluídos: ${this.def.cascadeDelete}.` : '';
    this.poDialog.confirm({
      title: 'Confirmar exclusão',
      message: `Excluir ${this.def.singular} "${descricao}"?${cascata}`,
      confirm: () => this.service.delete(this.def.resource, chave).subscribe({
        next: () => {
          this.poNotification.success('Registro excluído.');
          this.carregar();
        },
        // A mensagem do backend diz o motivo (vínculo em outra tabela, por exemplo); a nossa seria um palpite.
        error: (err: unknown) => this.poNotification.error(
          this.mensagemDeErro(err, `Não foi possível excluir ${this.def.singular}.`)
        )
      })
    });
  }

  /** Recarrega depois de uma falha, pelo botão do estado de erro. */
  tentarNovamente(): void {
    this.carregar();
  }

  /** Mensagem do backend quando houver; senão uma frase que diz o que fazer. */
  private mensagemDeErro(err: unknown, padrao: string): string {
    // Só a mensagem do backend; a do HttpErrorResponse é técnica demais para o usuário.
    const corpo = (err as { error?: { message?: string } } | null)?.error;
    return corpo?.message || padrao;
  }

  private carregar(): void {
    this.isLoading = true;
    this.cdr.markForCheck();
    this.service.list(this.def.resource, this.filtroPai()).pipe(
      finalize(() => {
        this.isLoading = false;
        this.cdr.markForCheck();
      })
    ).subscribe({
      next: res => {
        this.erro = null;
        this.items = res.items.map(row => this.comRotulos(row));
        this.temMais = !!res.hasNext || (res.total ?? 0) > this.items.length;
        this.completarTags(this.items);
        this.filtrar();
        this.countChange.emit(this.items.length);
      },
      error: (err: unknown) => {
        this.items = [];
        this.temMais = false;
        this.erro = this.mensagemDeErro(err, `Não foi possível carregar ${this.def.title.toLowerCase()}.`);
        this.filtrar();
      }
    });
  }

  private filtrar(): void {
    const termo = this.termo.trim().toLowerCase();
    const campos = this.def.fields.filter(f => f.column)
      .flatMap(f => (f.options ? [f.property, `${f.property}${SUFIXO_ROTULO}`] : [f.property]));
    this.visiveis = termo
      ? this.items.filter(row => campos.some(c => String(row[c] ?? '').toLowerCase().includes(termo)))
      : [...this.items];
    this.cdr.markForCheck();
  }

  private chavePai(): CrudRow {
    const chave: CrudRow = {};
    for (const campo of this.def.parentKeys ?? []) {
      chave[campo] = this.parent?.[campo];
    }
    return chave;
  }

  /** Distribui os campos nas abas (`tab`), preservando a ordem da definição. Sem `tab`, uma aba só. */
  private agrupar<T>(definicao: CrudField[], campos: T[], forcarAbas = false): Aba<T>[] {
    if (!forcarAbas && !definicao.some(f => f.tab)) {
      return [{ titulo: '', fields: campos }];
    }
    const abas: Aba<T>[] = [];
    definicao.forEach((f, i) => {
      const titulo = f.tab ?? 'Geral';
      const aba = abas.find(a => a.titulo === titulo) ?? (abas.push({ titulo, fields: [] }), abas[abas.length - 1]);
      aba.fields.push(campos[i]);
    });
    return abas;
  }

  /** Rótulo dos domínios em campo auxiliar; valor fora do domínio aparece como veio do banco. */
  private comRotulos(row: CrudRow): CrudRow {
    const copia = { ...row };
    for (const f of this.def.fields) {
      if (f.column && f.options) {
        copia[`${f.property}${SUFIXO_ROTULO}`] = f.options.find(o => o.value === row[f.property])?.label ?? row[f.property];
      }
    }
    return copia;
  }

  private filtroPai(): CrudRow {
    const filtro: CrudRow = { ...this.filtroUrl };
    for (const campo of this.def.parentKeys ?? []) {
      filtro[this.def.parentFilter?.[campo] ?? campo] = this.parent?.[campo];
    }
    return filtro;
  }

  /** Abre outra tela do cadastro já filtrada pelo valor desta linha. */
  private abrirLink(link: CrudLink, row: CrudRow): void {
    this.router.navigate([link.rota], { queryParams: { [link.campo]: row[link.campo] } });
  }

  private chaveDe(row: CrudRow): CrudRow {
    const chave = this.chavePai();
    for (const f of this.def.fields.filter(campo => campo.key)) {
      chave[f.property] = row[f.property];
    }
    return chave;
  }

  /** Esconde o gerenciador de colunas onde ele não tem o que gerenciar. */
  get semGerenciadorColunas(): boolean {
    return this.columns.length - 1 < 3;
  }

  private toColumn(f: CrudField): PoTableColumn {
    const label = f.columnLabel ?? f.label;
    if (f.type === 'boolean' && !f.options) {
      return { property: f.property, label, type: 'boolean', width: f.columnWidth };
    }
    // Tag colorida: `type: 'label'` esconde a célula quando o valor não está no domínio,
    // por isso `completarTags` acrescenta os valores inesperados como tag neutra.
    if (f.options && f.tagColumn) {
      return {
        property: f.property,
        label,
        type: 'label',
        width: f.columnWidth,
        labels: f.options.map(o => this.toLabel(o))
      };
    }
    // Domínio sem tag: texto do rótulo, num campo auxiliar preenchido no carregar.
    if (f.options) {
      return { property: `${f.property}${SUFIXO_ROTULO}`, label, width: f.columnWidth };
    }
    return { property: f.property, label, width: f.columnWidth };
  }

  private toLabel(o: CrudOption): PoTableColumnLabel {
    const base = { value: o.value as string | number, label: o.label };
    // `type` sobrepõe cor e ícone pelo padrão do tipo semântico; `color` preserva o ícone.
    return o.tagColor
      ? { ...base, color: o.tagColor, ...(o.icon ? { icon: o.icon } : {}) }
      : { ...base, type: (o.tag ?? 'neutral') as PoTagType };
  }

  /** Valor fora do domínio viraria célula vazia: entra como tag neutra com o valor cru. */
  private completarTags(rows: CrudRow[]): void {
    const comTag = this.def.fields.filter(f => f.column && f.options && f.tagColumn);
    if (!comTag.length) return;

    let mudou = false;
    for (const f of comTag) {
      const coluna = this.columns.find(c => c.property === f.property);
      if (!coluna) continue;
      for (const row of rows) {
        const valor = row[f.property];
        if (valor === null || valor === undefined) continue;
        if (coluna.labels!.some(l => l.value === valor)) continue;
        coluna.labels = [...coluna.labels!, { value: valor as string | number, label: String(valor), type: 'neutral' as PoTagType }];
        mudou = true;
      }
    }
    if (mudou) this.columns = [...this.columns];
  }

  private toOptions(f: CrudField, rows: CrudRow[]): CrudOption[] {
    const { value, label } = f.optionsFrom!;
    const vistos = new Set<string>();
    const opcoes: CrudOption[] = [];
    for (const row of rows) {
      const valor = String(row[value] ?? '');
      if (!valor || vistos.has(valor)) continue;
      vistos.add(valor);
      opcoes.push({ value: valor, label: label && row[label] ? `${valor} - ${row[label]}` : valor });
    }
    return opcoes;
  }

  private exibir(f: CrudField, valor: unknown): string {
    const opcao = f.options?.find(o => o.value === valor);
    if (opcao) return opcao.label;
    if (f.type === 'boolean') return valor ? 'Sim' : 'Não';
    return valor === null || valor === undefined || valor === '' ? '—' : String(valor);
  }
}

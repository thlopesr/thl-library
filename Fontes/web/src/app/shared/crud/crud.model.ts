export type CrudRow = Record<string, unknown>;

/** Cor da tag no browse, quando o campo usa `tagColumn`. */
export type CrudTagTipo = 'success' | 'warning' | 'danger' | 'info' | 'neutral';

/** Resposta da listagem: a API devolve `{ total, hasNext, items }` ou um array puro. */
export interface CrudListResult {
  items: CrudRow[];
  total?: number;
  hasNext?: boolean;
}

export interface CrudOption {
  label: string;
  value: string | number | boolean;
  /** Cor semântica da tag no browse. Sem isto (e sem `tagColor`) a tag fica neutra. */
  tag?: CrudTagTipo;
  /** Cor do tema PO UI (`color-01`…`color-12`), para valores sem valência semântica.
   *  Só assim a tag aceita `icon`: `tag` sobrepõe a cor e o ícone pelo padrão do tipo. */
  tagColor?: string;
  /** Ícone dentro da tag (biblioteca Animalia). */
  icon?: string;
}

export interface CrudField {
  property: string;
  label: string;
  type?: 'string' | 'number' | 'boolean' | 'password' | 'textarea';
  /** Parte da chave: obrigatório e bloqueado na edição. */
  key?: boolean;
  required?: boolean;
  maxLength?: number;
  /** Valores fixos (combo no formulário, rótulo no browse e no detalhe). */
  options?: CrudOption[];
  /** No browse, mostra o valor como tag colorida em vez de texto. Exige `options`. */
  tagColumn?: boolean;
  /** Zoom: opções carregadas de outro recurso da API ao abrir o formulário. */
  optionsFrom?: { resource: string; value: string; label?: string };
  /** Opções fixas somadas às do zoom (ex.: `*` = todos). */
  optionsFromExtra?: CrudOption[];
  /** Aparece no browse. O que não aparece fica só no formulário e no "Detalhar". */
  column?: boolean;
  /** Rótulo curto só para o cabeçalho da coluna; o `label` continua no formulário e no detalhe. */
  columnLabel?: string;
  /** Largura fixa. Só para colunas curtas e previsíveis; as de texto ficam livres. */
  columnWidth?: string;
  /** No Detalhar, mostra o conteúdo renderizado como HTML (o Angular sanitiza a marcação). */
  html?: boolean;
  /** No formulário, edita em `po-rich-text` em vez de textarea. O conteúdo gravado passa a ser HTML. */
  richText?: boolean;
  /** Aba do modal (formulário e detalhe). Sem `tab` em nenhum campo, o modal não tem abas. */
  tab?: string;
  /** Divisor dentro da aba. */
  group?: string;
  help?: string;
  /** Ícone à esquerda do campo no formulário (biblioteca Animalia, ex.: `an an-envelope`). */
  icon?: string;
  /** Texto de exemplo dentro do campo vazio. */
  placeholder?: string;
  /** Botão de limpar o campo. */
  clean?: boolean;
  /** Validação por expressão regular (ex.: formato de e-mail). */
  pattern?: string;
  /** Mensagem exibida quando o valor não casa com `pattern`. */
  errorMessage?: string;
  /** Largura no formulário, em colunas do grid PO UI (padrão 6 de 12). */
  gridColumns?: number;
  default?: unknown;
}

/** Atalho do "⋯" para outra tela do cadastro, levando o valor da linha como filtro. */
export interface CrudLink {
  label: string;
  icon: string;
  /** Caminho da rota de destino, sem `#/`. */
  rota: string;
  /** Campo da linha que vira o filtro (`?<campo>=<valor>`) na tela de destino. */
  campo: string;
}

export interface CrudResource {
  /** Rota da API: `/api/thl/integration/v1/resourcen/<resource>`. */
  resource: string;
  /** Título da página ou rótulo da aba. */
  title: string;
  subtitle?: string;
  /** Nome do registro no singular, para "Novo …", "Editar …" e mensagens. */
  singular: string;
  /** Gênero do singular, para concordância ("Novo"/"Nova", "vinculado"/"vinculada"). */
  feminine?: boolean;
  fields: CrudField[];
  /** Campos da chave herdados do pai (filtro `<campo>Ini/Fin` e valor fixo no corpo). */
  parentKeys?: string[];
  /** Prefixo do filtro quando difere do nome do campo (ex.: `{ codParametro: 'parametro' }` → `parametroIni/Fin`). */
  parentFilter?: Record<string, string>;
  /** No máximo um registro por pai: esconde "Adicionar" quando já existe. */
  single?: boolean;
  /** Recurso sem PATCH: só inclui e exclui. */
  noUpdate?: boolean;
  /** O que o backend elimina junto com o pai, em texto ("variáveis e programas").
   *  Entra na confirmação de exclusão; sem isto o usuário não sabe o que leva junto. */
  cascadeDelete?: string;
  /** Campo usado como título do card da linha expandida. */
  titleField?: string;
  /** Atalhos para outras telas, no menu "⋯" da linha. */
  links?: CrudLink[];
  children?: CrudResource[];
}

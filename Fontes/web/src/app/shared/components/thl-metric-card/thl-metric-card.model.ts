/** Cor semântica das linhas e dos segmentos do cartão. */
export type MetricCor = 'sucesso' | 'alerta' | 'erro' | 'neutro' | 'info';

export interface MetricLinha {
  label: string;
  valor: number;
  cor?: MetricCor;
  /** Ícone à esquerda do rótulo. Opcional: as telas de assunto não usam. */
  icone?: string;
}

export interface MetricEtiqueta {
  texto: string;
  cor?: MetricCor;
  icone?: string;
}

/** Uma fase da unidade, repartida entre as quatro situações. As quatro somam o total
 *  do cartão — é isso que torna as fases comparáveis entre si na mesma régua. */
export interface MetricFase {
  label: string;
  sucesso: number;
  pendente: number;
  erro: number;
  /** Fase que não se aplica (mensagem de entrada não tem retorno, por exemplo).
   *  Sem esta coluna, a fase apareceria como sucesso que nunca houve. */
  na: number;
}

/** Um cartão = uma unidade que se repete (rota, parâmetro de e-mail, tabela auditada). */
export interface MetricCard {
  id: string;
  titulo: string;
  /** Ícone ao lado do título — nas telas de resumo, o mesmo do item no menu lateral,
   *  para o cartão e a navegação falarem a mesma língua. */
  icone?: string;
  etiquetas?: MetricEtiqueta[];
  total: number;
  linhas: MetricLinha[];
  /** Barra do rodapé: proporção entre as linhas ou um percentual único. */
  /** Tabela de fases com cabeçalho de ícones. Quando vem preenchida, substitui `linhas`. */
  fases?: MetricFase[];
  barra?: { rotulo: string; percentual: number; cor: MetricCor } | { rotulo: string; proporcao: true };
  rodape?: string;
  acao?: string;
  /** Cor da borda, na mesma escala dos chips: erro > alerta (pendente) > sucesso.
   *  Ausente = unidade sem noção de situação. Usado nas telas de assunto. */
  estado?: 'erro' | 'alerta' | 'sucesso';

  /** Cor de destaque que **não** significa estado: separa um cartão do outro na tela
   *  geral. Quando vem preenchida, manda na moldura no lugar do `estado`. */
  acento?: string;
}

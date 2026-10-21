/** Resumo da tela raiz: um bloco por assunto, com o número principal e o atalho
 *  para a tela de métricas daquele assunto. O detalhe (por objeto, por programa,
 *  por tabela) mora nas telas `<assunto>/metricas`, não aqui. */
export interface MetricasResumo {
  mensagem: {
    total: number;
    sucesso: number;
    erro: number;
    pendente: number;
  };
  email: {
    total: number;
    sucesso: number;
    erro: number;
  };
  auditoria: {
    total: number;
    criacao: number;
    atualizacao: number;
    delecao: number;
  };
  /** Mensagens com erro em qualquer fase, dentro da faixa consultada. */
  errosNoPeriodo: number;
}

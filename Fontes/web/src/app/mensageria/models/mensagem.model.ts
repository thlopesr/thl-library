export interface MensagemConteudo {
  temRequisicao: boolean;
  temResposta: boolean;
}

export interface Mensagem {
  id: string;
  codMsg: string;
  objeto: string;
  operacao: string;
  aplicacao: string;
  modelo: string;
  metodo: string;
  dispositivo: string;
  dtIntegracao: string;
  dtCriacao: string;
  statusRequisicao: string;
  statusRetorno: string;
  statusProcessamento: string;
  destino: string;
  codStatusRetorno: number;
  descrRetorno: string;
  conteudo?: MensagemConteudo;
  dataCriacao?: string;
  horaCriacao?: string;
  dataIntegracao?: string;
  horaIntegracao?: string;
}

export interface MensagemFiltro {
  dtIntegracaoInicial?: string;
  dtIntegracaoFinal?: string;
  dtCriacaoInicial?: string;
  dtCriacaoFinal?: string;
  codMsgIni?: string;
  codMsgFin?: string;
  objetoIni?: string;
  objetoFin?: string;
  operacaoIni?: string;
  operacaoFin?: string;
  aplicacaoIni?: string;
  aplicacaoFin?: string;
  metodo?: string;
  dispositivo?: string;
  statusRequisicao?: string;
  statusRetorno?: string;
  statusProcessamento?: string;
  codStatusRetorno?: number;
  texto?: string;
}

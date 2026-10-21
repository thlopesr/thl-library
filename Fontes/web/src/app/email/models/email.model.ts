export interface Email {
  id: string;
  remetente: string;
  destino: string;
  assunto: string;
  dtEnvio: string;
  codParamAmbiente: string;
  mensagem: string;
  informacao: string;
  retorno: string;
  codProgDtsul: string;
  logEnvio: string;
  arqAnexo: string;
}

export interface EmailFiltro {
  dtEnvioInicial?: string;
  dtEnvioFinal?: string;
  idIni?: string;
  idFin?: string;
  codProgDtsulIni?: string;
  codProgDtsulFin?: string;
  texto?: string;
}

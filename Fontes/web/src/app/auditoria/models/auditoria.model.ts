export interface Auditoria {
  id: string;
  tabela: string;
  operacao: string;
  dtCriacao: string;
  banco: string;
  usuario: string;
  campos: string;
  referencia: string;
  programaExecutado: string;
  programaExecutadoX: string;
  snapshotAnterior: any;
  snapshotAtual: any;
}

export interface AuditoriaFiltro {
  bancoIni?: string;
  bancoFin?: string;
  tabelaIni?: string;
  tabelaFin?: string;
  dtCriacaoInicial?: string;
  dtCriacaoFinal?: string;
  usuarioIni?: string;
  usuarioFin?: string;
  texto?: string;
}

export interface SnapshotRow {
  campo: string;
  valorAnterior?: string;
  valorAtual?: string;
}

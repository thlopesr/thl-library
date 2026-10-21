/** `auditoria/metricas`: uma linha por banco + tabela, com os eventos do período. */
export interface AuditoriaMetricaRegistro {
  tipo: string;
  usuario: string;
  dtCriacao: string;
}

export interface AuditoriaMetrica {
  banco: string;
  tabela: string;
  nivelSensibilidade: number;
  registros: AuditoriaMetricaRegistro[];
}

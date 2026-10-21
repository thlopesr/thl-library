/** `email/metricas`: uma linha por programa + parâmetro de ambiente.
 *  O `thl-email` não guarda o parâmetro de e-mail nem o grupo — por isso a unidade é o programa. */
export interface EmailMetricaItem {
  situacao: string;
  destino: string;
  dtEnvio: string;
}

export interface EmailMetrica {
  programa: string;
  paramAmbiente: string;
  emails: EmailMetricaItem[];
}

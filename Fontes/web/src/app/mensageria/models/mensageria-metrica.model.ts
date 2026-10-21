/** `mensageria/metricas`: uma linha por aplicação + objeto, com as situações de cada fase. */
export interface MensageriaMetricaItem {
  dispositivo: string;
  sitRequisicao: string;
  sitProcessamento: string;
  sitRetorno: string;
  dtCriacao: string;
}

export interface MensageriaMetrica {
  aplicacao: string;
  objeto: string;
  interna: boolean;
  mensagens: MensageriaMetricaItem[];
}

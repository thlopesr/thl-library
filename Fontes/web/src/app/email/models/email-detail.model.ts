export type EmailStatusType = 'success' | 'error' | 'warning';

export interface EmailRetorno {
  status: string;
  messageId: string;
  timestamp: string;
  accepted: string[];
  rejected: string[];
  code: number;
  error?: string;
}

export interface EmailParametro {
  label: string;
  valor: string;
}

export interface EmailDetail {
  id: string;
  assunto: string;
  remetente: string;
  destinatario: string;
  programa: string;
  paramAmbiente: string;
  dataEnvio: Date;
  horaEnvio?: string;
  arquivoAnexo?: string;
  statusEnvio: EmailStatusType;
  statusDescricao: string;
  mensagemCorpo?: string;
  retorno?: EmailRetorno;
  parametros?: EmailParametro[];
}

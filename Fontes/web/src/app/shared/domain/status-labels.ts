import { PoTableColumnLabel } from '@po-ui/ng-components';

// Rótulos coloridos das colunas de situação, compartilhados pelos monitores.
// `value` é o que casa com o dado da linha; `label` é o texto exibido na célula.

/** Situação de requisição, retorno e processamento (mensageria) e de envio (e-mail). */
export const STATUS_LABELS: PoTableColumnLabel[] = [
  { value: 'Sucesso', label: 'Sucesso', color: 'color-11', icon: 'an an-check-circle' },
  { value: 'Erro', label: 'Erro', color: 'color-07', icon: 'an an-x-circle' },
  { value: 'Pendente', label: 'Pendente', color: 'color-08', icon: 'an an-clock' },
  { value: 'N/A', label: 'Não aplicável', color: 'color-12', icon: 'an an-minus-circle' }
];

/** Os três estados que o envio de e-mail registra: `thl-email.log-envio` 1/2/3.
 *  `Pendente` ficou de fora até 19/10/2026 e, como `type: 'label'` esconde a célula
 *  quando o valor não está no domínio, o e-mail pendente aparecia sem status nenhum. */
export const STATUS_EMAIL_LABELS: PoTableColumnLabel[] = STATUS_LABELS.filter(
  l => l.value === 'Sucesso' || l.value === 'Erro' || l.value === 'Pendente'
);

/** Operação registrada pela auditoria. */
export const OPERACAO_LABELS: PoTableColumnLabel[] = [
  { value: 'Criacao', label: 'Criação', color: 'color-11', icon: 'an an-plus-circle' },
  { value: 'Atualizacao', label: 'Atualização', color: 'color-08', icon: 'an an-pencil-simple' },
  { value: 'Delecao', label: 'Deleção', color: 'color-07', icon: 'an an-trash' }
];

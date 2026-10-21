// Dados de exemplo dos cadastros do motor genérico (só no build development).

export interface MockTable {
  keys: string[];
  rows: Record<string, any>[];
}

export const cadastrosMock: Record<string, MockTable> = {
  'conexao-rest': {
    keys: ['conexao'],
    rows: [
      { conexao: 'PEDIDOS-PRD', descricao: 'Integração de pedidos (produção)', urlBase: 'https://api.exemplo.invalid', indRequisitaAutenticacao: true, indRequisitaHeader: true },
      { conexao: 'PEDIDOS-HML', descricao: 'Integração de pedidos (homologação)', urlBase: 'https://hml.exemplo.invalid', indRequisitaAutenticacao: true, indRequisitaHeader: false },
      { conexao: 'PORTAL', descricao: 'Portal de fornecedores', urlBase: 'https://portal.exemplo.invalid/api', indRequisitaAutenticacao: false, indRequisitaHeader: false }
    ]
  },
  'conexao-rest/autenticacao': {
    keys: ['conexao'],
    rows: [
      {
        conexao: 'PEDIDOS-PRD', tipoAutenticacao: 'BEARER', indRequisitaToken: true, usuario: 'integracao', senha: 'segredo-mock',
        urlToken: 'https://api.exemplo.invalid/oauth/token', contentTypeToken: 'application/json', acceptToken: 'application/json',
        headersToken: '', parametersToken: 'grant_type=client_credentials',
        classeParserToken: 'thl-extensions.integration.exemplo.connectors.token.TokenProvider'
      },
      {
        conexao: 'PEDIDOS-HML', tipoAutenticacao: 'BASIC', indRequisitaToken: false, usuario: 'integracao-hml', senha: 'segredo-mock',
        urlToken: '', contentTypeToken: 'application/json', acceptToken: 'application/json',
        headersToken: '', parametersToken: '', classeParserToken: ''
      }
    ]
  },
  'conexao-rest/header': {
    keys: ['conexao'],
    rows: [
      { conexao: 'PEDIDOS-PRD', classeParser: 'thl-extensions.integration.exemplo.connectors.headers.HeaderProvider', parameters: 'x-origem=datasul' }
    ]
  },
  'conexao-rest-path': {
    keys: ['endpoint'],
    rows: [
      { endpoint: 'PEDIDO-CRIAR', descricao: 'Cria pedido', path: '/v1/pedidos', contentType: 'application/json', accept: 'application/json', timeout: 30, parameters: '', headers: '' },
      { endpoint: 'PEDIDO-CONSULTAR', descricao: 'Consulta pedido', path: '/v1/pedidos/{id}', contentType: 'application/json', accept: 'application/json', timeout: 30, parameters: '', headers: '' },
      { endpoint: 'EMBARQUE-ATUALIZAR', descricao: 'Atualiza embarque', path: '/v1/embarques/{id}', contentType: 'application/json', accept: 'application/json', timeout: 60, parameters: '', headers: '' }
    ]
  },
  'aplicacao': {
    keys: ['aplicacao'],
    rows: [
      { aplicacao: 'THL', descricao: 'Framework THL', indInterna: true },
      { aplicacao: 'EXEMPLO', descricao: 'Sistema de exemplo', indInterna: false }
    ]
  },
  'objeto': {
    keys: ['aplicacao', 'objeto'],
    rows: [
      { aplicacao: 'THL', objeto: 'AMBIENTE', classeObjeto: 'thl-extensions.integration.thl.messaging.inbound.message.AmbienteMessage', modeloIntegracao: 1, sentidoFluxo: false, indInativo: false, indGeraHistorico: false, programaConsulta: '' },
      { aplicacao: 'THL', objeto: 'PARAMETRO', classeObjeto: 'thl-extensions.integration.thl.messaging.inbound.message.ParametroAmbienteMessage', modeloIntegracao: 1, sentidoFluxo: false, indInativo: false, indGeraHistorico: false, programaConsulta: '' },
      { aplicacao: 'EXEMPLO', objeto: 'PEDIDO', classeObjeto: 'thl-extensions.integration.exemplo.messaging.outbound.message.PedidoMessage', modeloIntegracao: 1, sentidoFluxo: true, indInativo: false, indGeraHistorico: true, programaConsulta: 'thl0101' }
    ]
  },
  'objeto/parametro': {
    keys: ['estabelecimento', 'aplicacao', 'objeto', 'operacao'],
    rows: [
      {
        estabelecimento: '*', aplicacao: 'THL', objeto: 'AMBIENTE', operacao: 'GET', metodo: 5, formaExecucao: 1, indInativo: false, indGeraHistorico: false,
        indMensagemSimples: false, paramAmbiente: '', paramAmbienteDestino: '', indPersistente: false, frequenciaExecucao: 0, servidorExecucao: '',
        qtdTentativasPersist: 0, qtdDiasPersist: 0, tipoLogRequisicao: 1, tipoLogRetorno: 1
      },
      {
        estabelecimento: '*', aplicacao: 'THL', objeto: 'AMBIENTE', operacao: 'POST', metodo: 1, formaExecucao: 1, indInativo: false, indGeraHistorico: false,
        indMensagemSimples: false, paramAmbiente: '', paramAmbienteDestino: '', indPersistente: false, frequenciaExecucao: 0, servidorExecucao: '',
        qtdTentativasPersist: 0, qtdDiasPersist: 0, tipoLogRequisicao: 1, tipoLogRetorno: 1
      },
      {
        estabelecimento: '*', aplicacao: 'EXEMPLO', objeto: 'PEDIDO', operacao: 'ENVIAR', metodo: 1, formaExecucao: 1, indInativo: false, indGeraHistorico: true,
        indMensagemSimples: false, paramAmbiente: 'URL-BASE', paramAmbienteDestino: '', indPersistente: true, frequenciaExecucao: 5, servidorExecucao: 'RPW01',
        qtdTentativasPersist: 3, qtdDiasPersist: 7, tipoLogRequisicao: 1, tipoLogRetorno: 1
      }
    ]
  },
  'objeto/usuario': {
    keys: ['aplicacao', 'objeto', 'usuario'],
    rows: [
      { aplicacao: 'EXEMPLO', objeto: 'PEDIDO', usuario: 'super' },
      { aplicacao: 'EXEMPLO', objeto: 'PEDIDO', usuario: 'integracao' }
    ]
  },
  'objeto/rota': {
    keys: ['aplicacao', 'objeto', 'rotaPublica'],
    rows: [
      { aplicacao: 'THL', objeto: 'AMBIENTE', rotaPublica: 'ambiente', indAtivo: true, inicioOperacao: 0 },
      { aplicacao: 'THL', objeto: 'PARAMETRO', rotaPublica: 'parametro-ambiente', indAtivo: true, inicioOperacao: 0 }
    ]
  },
  'auditoria-tabela': {
    keys: ['banco', 'tabela'],
    rows: [
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', pk: '["cod-ambiente","cod-parametro","cod-variavel"]', indAtivoCreate: true, indAtivoUpdate: true, indAtivoDelete: true, nivelSensibilidade: 5, indAuditTabela: true },
      { banco: 'thl', tabela: 'thl-conexao-rest', pk: '["cod-conexao"]', indAtivoCreate: true, indAtivoUpdate: true, indAtivoDelete: false, nivelSensibilidade: 1, indAuditTabela: true }
    ]
  },
  'auditoria-tabela/campo': {
    keys: ['banco', 'tabela', 'campo'],
    rows: [
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', campo: 'valor', nivelSensibilidade: 9, indAtivo: true },
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', campo: 'descricao', nivelSensibilidade: 1, indAtivo: true }
    ]
  },
  'auditoria-tabela/acesso': {
    keys: ['banco', 'tabela', 'usuario'],
    rows: [
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', usuario: 'super', nivelAcesso: 9, indAtivo: true }
    ]
  },
  'auditoria-tabela/notificacao': {
    keys: ['banco', 'tabela', 'nivelSensibilidade'],
    rows: [
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', nivelSensibilidade: 9, grupoEmail: 'TI-INTEGRACAO', indAtivo: true }
    ]
  },
  'auditoria-tabela/expurgo': {
    keys: ['banco', 'tabela'],
    rows: [
      { banco: 'thl', tabela: 'thl-ambiente-param-variavel', retencaoDias: 365 }
    ]
  },
  'grupo-email': {
    keys: ['grupoEmail'],
    rows: [
      { grupoEmail: 'TI-INTEGRACAO', descricao: 'Equipe de integração' },
      { grupoEmail: 'AUDITORIA', descricao: 'Responsáveis pela auditoria' },
      { grupoEmail: 'FISCAL', descricao: 'Equipe fiscal' }
    ]
  },
  'grupo-email/usuario': {
    keys: ['grupoEmail', 'usuario', 'emailAlternativo'],
    rows: [
      { grupoEmail: 'TI-INTEGRACAO', usuario: 'super', emailAlternativo: '' },
      { grupoEmail: 'TI-INTEGRACAO', usuario: 'integracao', emailAlternativo: '' },
      // Mesmo usuário com um segundo endereço: a chave inclui o e-mail alternativo.
      { grupoEmail: 'TI-INTEGRACAO', usuario: 'integracao', emailAlternativo: 'plantao@exemplo.invalid' },
      { grupoEmail: 'AUDITORIA', usuario: 'super', emailAlternativo: 'auditoria@exemplo.invalid' }
    ]
  },
  'email-parametro': {
    keys: ['emailParam'],
    rows: [
      {
        emailParam: 'ERRO-INTEGRACAO', assunto: 'Erro em integração', grupoEmail: 'TI-INTEGRACAO',
        remetente: 'nao-responda@exemplo.invalid', copia: 'ti@exemplo.invalid, fiscal@exemplo.invalid', importancia: 1, logGerar: true,
        // Marcadores no formato que o EmailMessageFactory:applyPlaceholder substitui (#1#, #2#...).
        mensagem: '<h3>Falha na integração</h3><p>O objeto <b>#1#</b> retornou erro em <i>#2#</i>.</p>'
          + '<ul><li>Mensagem: #3#</li><li>Tentativas: #4#</li></ul>'
      },
      {
        emailParam: 'AUDITORIA', assunto: 'Alteração em tabela auditada', grupoEmail: 'AUDITORIA',
        remetente: 'nao-responda@exemplo.invalid', copia: '', importancia: 0, logGerar: true,
        // Texto puro: as quebras de linha são preservadas no Detalhar.
        mensagem: 'Registro alterado na tabela #1#.\n\nUsuário: #2#\nData: #3#'
      }
    ]
  }
};

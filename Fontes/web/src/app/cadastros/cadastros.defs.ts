import { CrudOption, CrudResource } from '../shared/crud';

// Definições dos cadastros atendidos pelo motor genérico (shared/crud).
// Campos, chaves e filtros conforme a coleção Nitro do Postman (pasta THL).

const METODOS: CrudOption[] = [
  { label: 'POST', value: 1 },
  { label: 'PUT', value: 2 },
  { label: 'PATCH', value: 3 },
  { label: 'DELETE', value: 4 },
  { label: 'GET', value: 5 }
];

// Decolagem sai, pouso chega — mesmos ícones da etiqueta de sentido nos cartões de
// métrica da consulta, para o mesmo conceito ter um desenho só nos dois apps.
const SENTIDOS: CrudOption[] = [
  { label: 'Entrada', value: false, tagColor: 'color-02', icon: 'an an-airplane-landing' },
  { label: 'Saída', value: true, tagColor: 'color-08', icon: 'an an-airplane-takeoff' }
];

// Situação do registro: mesma leitura nos dois sentidos do campo no banco
// (`ind-inativo` e `ind-ativo`), para o usuário nunca ler dupla negativa.
const SITUACAO_POR_INATIVO: CrudOption[] = [
  { label: 'Ativo', value: false, tag: 'success' },
  { label: 'Inativo', value: true, tag: 'neutral' }
];
const SITUACAO_POR_ATIVO: CrudOption[] = [
  { label: 'Ativo', value: true, tag: 'success' },
  { label: 'Inativo', value: false, tag: 'neutral' }
];

const MODELOS_INTEGRACAO: CrudOption[] = [
  { label: 'REST', value: 1 },
  { label: 'SOAP', value: 2 },
  { label: 'Database', value: 3 },
  { label: 'File', value: 4 }
];

const FORMAS_EXECUCAO: CrudOption[] = [
  { label: 'Online', value: 1 },
  { label: 'Agendar', value: 2 },
  { label: 'Batch', value: 3 }
];

const TIPOS_LOG: CrudOption[] = [
  { label: 'Pendente', value: 1 },
  { label: 'Erro', value: 2 },
  { label: 'Sucesso', value: 3 },
  { label: 'Não aplicável', value: 4 }
];

const NIVEIS_SENSIBILIDADE: CrudOption[] = [
  { label: 'Normal', value: 1, tag: 'neutral' },
  { label: 'Crítico', value: 5, tag: 'warning' },
  { label: 'Restrito', value: 9, tag: 'danger' }
];

const JSON_MIME = 'application/json';
const AJUDA_PARES = 'Um par chave=valor por linha.';
const AJUDA_MARCADORES = 'Os marcadores #1#, #2#… são trocados pelos valores pelo programa que dispara o e-mail.';
const CLASSE_MENSAGEM = 'thl-extensions.integration.sistema.messaging.inbound.message.PedidoMessage';
const CLASSE_TOKEN = 'thl-extensions.integration.sistema.connectors.token.TokenProvider';
const CLASSE_HEADER = 'thl-extensions.integration.sistema.connectors.headers.HeaderProvider';
// Valores tratados pelo RestConnector (case authentication:authenticationType).
const TIPOS_AUTENTICACAO: CrudOption[] = [
  { label: 'BASIC', value: 'BASIC' },
  { label: 'BEARER', value: 'BEARER' },
  { label: 'TOKEN', value: 'TOKEN' },
  { label: 'CUSTOM.BODY', value: 'CUSTOM.BODY' }
];
const AJUDA_AUTENTICACAO = 'BASIC usa usuário e senha; BEARER e TOKEN enviam o token no cabeçalho Authorization; CUSTOM.BODY envia o token no corpo.';

// thl-objeto-parametro.tipo-grava-conteudo (backend 2026-10-03)
const TIPOS_GRAVA_CONTEUDO: CrudOption[] = [
  { label: 'Sempre', value: 1 },
  { label: 'Somente em erro', value: 2 },
  { label: 'Nunca', value: 3 }
];

// thl-aplicacao.ind-interna: separa o trafego do proprio THL nas metricas
const ORIGENS_APLICACAO: CrudOption[] = [
  { label: 'Externa', value: false, tag: 'info' },
  { label: 'Interna', value: true, tag: 'neutral' }
];

const AJUDA_CLASSE = 'Nome completo da classe ABL (pacote em minúsculas). É carregada dinamicamente: um nome errado só falha na execução.';

// Um endereço por campo; o vazio é aceito (o `required` cuida do obrigatório).
const UM_EMAIL = '[^@\\s,;]+@[^@\\s,;]+\\.[^@\\s,;]+';
const EMAIL_PATTERN = `^$|^${UM_EMAIL}$`;
const EMAIL_ERRO = 'Informe um e-mail válido (exemplo: nome@empresa.com.br).';
// Lista de endereços: o separador é a vírgula, como o EmailParamRepository monta os destinatários.
const EMAILS_PATTERN = `^$|^\\s*${UM_EMAIL}\\s*(,\\s*${UM_EMAIL}\\s*)*$`;
const EMAILS_ERRO = 'Informe um ou mais e-mails válidos separados por vírgula.';
const EMAIL_PLACEHOLDER = 'nome@empresa.com.br';

export const aplicacaoDef: CrudResource = {
  resource: 'aplicacao',
  title: 'Aplicação',
  subtitle: 'Sistemas que trocam mensagens com o THL (thl0020)',
  singular: 'aplicação',
  feminine: true,
  // Sem cascata: o AplicacaoService bloqueia a exclusão quando há objeto cadastrado.
  links: [{ label: 'Ver objetos', icon: 'an an-cube', rota: 'objeto', campo: 'aplicacao' }],
  fields: [
    {
      property: 'aplicacao', label: 'Aplicação', key: true, column: true, maxLength: 40,
      gridColumns: 4, placeholder: 'THL'
    },
    {
      property: 'descricao', label: 'Descrição', required: true, column: true,
      gridColumns: 8, placeholder: 'Framework THL'
    },
    {
      property: 'indInterna', label: 'Origem', type: 'boolean', options: ORIGENS_APLICACAO,
      tagColumn: true, column: true, columnWidth: '140px',
      help: 'Interna separa o tráfego do próprio THL nas métricas da mensageria.'
    }
  ]
};

export const ambienteDef: CrudResource = {
  resource: 'ambiente',
  title: 'Ambiente',
  cascadeDelete: 'variáveis de ambiente',
  subtitle: 'Cadastro de ambientes',
  singular: 'ambiente',
  fields: [
    { property: 'codAmbiente', label: 'Código', key: true, column: true, maxLength: 20, gridColumns: 4, placeholder: 'PRD' },
    { property: 'nomeAmbiente', label: 'Nome', required: true, column: true, maxLength: 60, gridColumns: 8, placeholder: 'Produção' },
    { property: 'ip', label: 'IP', column: true, columnWidth: '160px', maxLength: 40, gridColumns: 4, placeholder: '192.168.0.10' }
  ]
};

export const parametroDef: CrudResource = {
  resource: 'parametro-ambiente',
  title: 'Parâmetro',
  cascadeDelete: 'variáveis e programas',
  subtitle: 'Parâmetros de ambiente e seus vínculos',
  singular: 'parâmetro',
  titleField: 'descricao',
  fields: [
    { property: 'codParametro', label: 'Código', key: true, column: true, maxLength: 20, gridColumns: 4, placeholder: 'EMAIL' },
    { property: 'descricao', label: 'Descrição', required: true, column: true, maxLength: 60, gridColumns: 8, placeholder: 'Parâmetros de envio de e-mail' }
  ],
  children: [
    {
      resource: 'parametro-ambiente/variavel',
      title: 'Variáveis',
      singular: 'variável',
      feminine: true,
      parentKeys: ['codParametro'],
      parentFilter: { codParametro: 'parametro' },
      fields: [
        {
          property: 'codAmbiente', label: 'Ambiente', key: true, column: true, columnWidth: '180px',
          optionsFrom: { resource: 'ambiente', value: 'codAmbiente', label: 'nomeAmbiente' },
          optionsFromExtra: [{ label: '* - Todos os ambientes', value: '*' }]
        },
        { property: 'codVariavel', label: 'Variável', key: true, column: true, maxLength: 40, placeholder: 'SMTP-SERVIDOR' },
        { property: 'descricao', label: 'Descrição', column: true, gridColumns: 12, maxLength: 60, placeholder: 'Servidor SMTP' },
        {
          property: 'valor', label: 'Valor', column: true, gridColumns: 12, placeholder: 'smtp.empresa.com.br',
          help: 'Valor sensível volta como ********; mantenha assim para não alterar.'
        }
      ]
    },
    {
      resource: 'parametro-ambiente/programa',
      title: 'Programas',
      singular: 'programa',
      noUpdate: true,
      parentKeys: ['codParametro'],
      parentFilter: { codParametro: 'parametro' },
      fields: [
        { property: 'codPrograma', label: 'Programa', key: true, column: true, maxLength: 40, placeholder: 'thl0010' }
      ]
    }
  ]
};

export const conexaoDef: CrudResource = {
  resource: 'conexao-rest',
  title: 'Conexão',
  cascadeDelete: 'autenticação e cabeçalhos',
  subtitle: 'Conexões REST, autenticação e header',
  singular: 'conexão',
  feminine: true,
  titleField: 'descricao',
  fields: [
    { property: 'conexao', label: 'Conexão', key: true, column: true, maxLength: 40, gridColumns: 4, placeholder: 'PEDIDOS-PRD' },
    { property: 'descricao', label: 'Descrição', column: true, gridColumns: 8, placeholder: 'Integração de pedidos' },
    {
      property: 'urlBase', label: 'URL base', required: true, column: true, gridColumns: 12,
      icon: 'an an-globe', clean: true, placeholder: 'https://api.empresa.com.br'
    },
    { property: 'indRequisitaAutenticacao', label: 'Requer autenticação', type: 'boolean' },
    { property: 'indRequisitaHeader', label: 'Requer header', type: 'boolean' }
  ],
  children: [
    {
      resource: 'conexao-rest/autenticacao',
      title: 'Autenticação',
      singular: 'autenticação',
      feminine: true,
      single: true,
      parentKeys: ['conexao'],
      fields: [
        { property: 'tipoAutenticacao', label: 'Tipo', required: true, column: true, columnWidth: '160px', tab: 'Acesso', options: TIPOS_AUTENTICACAO, help: AJUDA_AUTENTICACAO },
        { property: 'usuario', label: 'Usuário', column: true, tab: 'Acesso', icon: 'an an-user', clean: true, placeholder: 'integracao' },
        { property: 'senha', label: 'Senha', type: 'password', tab: 'Acesso' },
        { property: 'indRequisitaToken', label: 'Requer token', type: 'boolean', column: true, tab: 'Token' },
        {
          property: 'urlToken', label: 'URL do token', gridColumns: 12, tab: 'Token',
          icon: 'an an-globe', clean: true, placeholder: 'https://api.empresa.com.br/oauth/token'
        },
        { property: 'contentTypeToken', label: 'Content-Type', tab: 'Token', placeholder: JSON_MIME },
        { property: 'acceptToken', label: 'Accept', tab: 'Token', placeholder: JSON_MIME },
        { property: 'headersToken', label: 'Headers do token', type: 'password', tab: 'Token' },
        { property: 'parametersToken', label: 'Parâmetros do token', type: 'password', tab: 'Token', help: AJUDA_PARES },
        {
          property: 'classeParserToken', label: 'Classe do parser de token', gridColumns: 12,
          icon: 'an an-code', clean: true, placeholder: CLASSE_TOKEN, help: AJUDA_CLASSE, tab: 'Token'
        }
      ]
    },
    {
      resource: 'conexao-rest/header',
      title: 'Header',
      singular: 'header',
      single: true,
      parentKeys: ['conexao'],
      fields: [
        {
          property: 'classeParser', label: 'Classe do header', required: true, column: true, gridColumns: 12,
          icon: 'an an-code', clean: true, placeholder: CLASSE_HEADER, help: AJUDA_CLASSE
        },
        { property: 'parameters', label: 'Parâmetros', type: 'textarea', column: true, placeholder: 'x-origem=datasul', help: AJUDA_PARES }
      ]
    }
  ]
};

export const pathDef: CrudResource = {
  resource: 'conexao-rest-path',
  title: 'Path',
  subtitle: 'Endpoints REST, reutilizáveis entre conexões',
  singular: 'path',
  fields: [
    { property: 'endpoint', label: 'Endpoint', key: true, column: true, maxLength: 40, gridColumns: 4, placeholder: 'PEDIDO-CRIAR' },
    { property: 'descricao', label: 'Descrição', column: true, gridColumns: 8, placeholder: 'Cria pedido' },
    {
      property: 'path', label: 'Path', column: true, gridColumns: 12,
      icon: 'an an-path', clean: true, placeholder: '/v1/pedidos/{id}'
    },
    { property: 'contentType', label: 'Content-Type', default: 'application/json' },
    { property: 'accept', label: 'Accept', default: 'application/json' },
    { property: 'timeout', label: 'Timeout (s)', type: 'number', default: 30 },
    { property: 'parameters', label: 'Parâmetros', type: 'textarea', tab: 'Parâmetros', gridColumns: 12, placeholder: 'id=123', help: AJUDA_PARES },
    { property: 'headers', label: 'Headers', type: 'textarea', tab: 'Headers', gridColumns: 12, placeholder: 'x-origem=datasul', help: AJUDA_PARES }
  ]
};

export const objetoDef: CrudResource = {
  resource: 'objeto',
  title: 'Objeto',
  cascadeDelete: 'parâmetros, usuários e rota',
  subtitle: 'Objetos de integração, parâmetros e usuários',
  singular: 'objeto',
  fields: [
    {
      property: 'aplicacao', label: 'Aplicação', key: true, column: true, columnWidth: '160px', maxLength: 40,
      optionsFrom: { resource: 'aplicacao', value: 'aplicacao', label: 'descricao' }
    },
    { property: 'objeto', label: 'Objeto', key: true, column: true, maxLength: 40, placeholder: 'PEDIDO' },
    {
      property: 'classeObjeto', label: 'Classe da mensagem', required: true, gridColumns: 12,
      icon: 'an an-code', clean: true, placeholder: CLASSE_MENSAGEM, help: AJUDA_CLASSE
    },
    { property: 'modeloIntegracao', label: 'Modelo de integração', type: 'number', options: MODELOS_INTEGRACAO, default: 1 },
    { property: 'sentidoFluxo', label: 'Sentido', type: 'boolean', options: SENTIDOS, tagColumn: true, column: true, columnWidth: '140px' },
    {
      property: 'indInativo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_INATIVO,
      tagColumn: true, column: true, columnWidth: '120px'
    },
    { property: 'indGeraHistorico', label: 'Gera histórico', type: 'boolean' },
    { property: 'programaConsulta', label: 'Programa de consulta', placeholder: 'thl0101' }
  ],
  children: [
    {
      resource: 'objeto/parametro',
      title: 'Parâmetros',
      singular: 'parâmetro',
      parentKeys: ['aplicacao', 'objeto'],
      fields: [
        { property: 'estabelecimento', label: 'Estabelecimento', columnLabel: 'Estab.', key: true, column: true, columnWidth: '110px', gridColumns: 4, icon: 'an an-buildings', default: '*', help: '* = todos', tab: 'Geral' },
        { property: 'operacao', label: 'Operação', key: true, column: true, columnWidth: '140px', gridColumns: 4, tab: 'Geral', placeholder: 'ENVIAR' },
        { property: 'metodo', label: 'Método', type: 'number', options: METODOS, column: true, columnWidth: '120px', gridColumns: 4, default: 5, tab: 'Geral' },
        { property: 'formaExecucao', label: 'Forma de execução', type: 'number', options: FORMAS_EXECUCAO, default: 1, tab: 'Geral' },
        {
          property: 'indInativo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_INATIVO,
          tagColumn: true, column: true, columnWidth: '120px', tab: 'Geral'
        },
        { property: 'indGeraHistorico', label: 'Gera histórico', type: 'boolean', tab: 'Geral' },
        { property: 'indMensagemSimples', label: 'Mensagem simples', type: 'boolean', tab: 'Geral' },
        { property: 'paramAmbiente', label: 'Parâmetro de ambiente', column: true, tab: 'Ambiente', placeholder: 'URL-BASE' },
        { property: 'paramAmbienteDestino', label: 'Parâmetro de ambiente (destino)', tab: 'Ambiente', placeholder: 'URL-DESTINO' },
        { property: 'indPersistente', label: 'Persistente', type: 'boolean', tab: 'Persistência' },
        { property: 'frequenciaExecucao', label: 'Frequência de execução', type: 'number', tab: 'Persistência' },
        { property: 'qtdTentativasPersist', label: 'Tentativas', type: 'number', tab: 'Persistência' },
        { property: 'qtdDiasPersist', label: 'Dias de persistência', type: 'number', tab: 'Persistência' },
        { property: 'tipoLogRequisicao', label: 'Tipo de log da requisição', type: 'number', options: TIPOS_LOG, default: 1, tab: 'Persistência', group: 'Log' },
        { property: 'tipoLogRetorno', label: 'Tipo de log do retorno', type: 'number', options: TIPOS_LOG, default: 1, tab: 'Persistência', group: 'Log' },
        {
          property: 'tipoGravaConteudo', label: 'Gravação do conteúdo', type: 'number',
          options: TIPOS_GRAVA_CONTEUDO, default: 1, tab: 'Persistência', group: 'Log'
        },
        { property: 'servidorExecucao', label: 'Servidor de execução', tab: 'Servidor', placeholder: 'RPW01' }
      ]
    },
    {
      resource: 'objeto/rota',
      title: 'Rotas',
      singular: 'rota',
      feminine: true,
      parentKeys: ['aplicacao', 'objeto'],
      fields: [
        {
          property: 'rotaPublica', label: 'Rota pública', key: true, column: true, gridColumns: 12,
          icon: 'an an-path', clean: true, placeholder: 'ambiente',
          help: 'Trecho da URL depois de /resourcen/. Único entre todas as rotas; o objeto pode ter várias. Para trocar o caminho, elimine a rota e crie outra.'
        },
        {
          property: 'indAtivo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_ATIVO,
          tagColumn: true, column: true, columnWidth: '120px', default: true
        },
        {
          property: 'inicioOperacao', label: 'Início da operação', type: 'number', column: true,
          columnWidth: '150px', default: 0,
          help: '0 = a operação é o último segmento da URL. Em rota de vários níveis, informe o segmento onde a operação começa (2 em diante).'
        }
      ]
    },
    {
      resource: 'objeto/usuario',
      title: 'Usuários',
      singular: 'usuário',
      noUpdate: true,
      parentKeys: ['aplicacao', 'objeto'],
      fields: [
        { property: 'usuario', label: 'Usuário', key: true, column: true, icon: 'an an-user', clean: true, placeholder: 'super', help: 'Usuário do Datasul' }
      ]
    }
  ]
};

export const auditoriaDef: CrudResource = {
  resource: 'auditoria-tabela',
  title: 'Auditoria',
  cascadeDelete: 'campos, acessos, notificações e expurgo',
  subtitle: 'Tabelas auditadas, campos, acessos, notificações e expurgo',
  singular: 'tabela auditada',
  feminine: true,
  fields: [
    { property: 'banco', label: 'Banco', key: true, column: true, columnWidth: '110px', gridColumns: 3, icon: 'an an-database', placeholder: 'thl' },
    { property: 'tabela', label: 'Tabela', key: true, column: true, gridColumns: 9, icon: 'an an-table', placeholder: 'thl-ambiente-param-variavel' },
    { property: 'pk', label: 'Chave primária', gridColumns: 12, placeholder: '["cod-ambiente","cod-parametro"]', help: 'Lista JSON dos campos, ex.: ["cod-chave"]' },
    { property: 'nivelSensibilidade', label: 'Nível de sensibilidade', columnLabel: 'Sensibilidade', type: 'number', options: NIVEIS_SENSIBILIDADE, tagColumn: true, column: true, columnWidth: '160px', default: 1 },
    { property: 'indAuditTabela', label: 'Audita tabela', columnLabel: 'Audita', type: 'boolean', column: true, columnWidth: '120px', default: true },
    { property: 'indAtivoCreate', label: 'Audita inclusão', type: 'boolean', default: true },
    { property: 'indAtivoUpdate', label: 'Audita alteração', type: 'boolean', default: true },
    { property: 'indAtivoDelete', label: 'Audita eliminação', type: 'boolean' }
  ],
  children: [
    {
      resource: 'auditoria-tabela/campo',
      title: 'Campos',
      singular: 'campo',
      parentKeys: ['banco', 'tabela'],
      fields: [
        { property: 'campo', label: 'Campo', key: true, column: true, placeholder: 'valor' },
        { property: 'nivelSensibilidade', label: 'Nível de sensibilidade', columnLabel: 'Sensibilidade', type: 'number', options: NIVEIS_SENSIBILIDADE, tagColumn: true, column: true, columnWidth: '160px', default: 1 },
        { property: 'indAtivo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_ATIVO, tagColumn: true, column: true, columnWidth: '120px', default: true }
      ]
    },
    {
      resource: 'auditoria-tabela/acesso',
      title: 'Acessos',
      singular: 'acesso',
      parentKeys: ['banco', 'tabela'],
      fields: [
        { property: 'usuario', label: 'Usuário', key: true, column: true, icon: 'an an-user', clean: true, placeholder: 'super', help: 'Usuário do Datasul' },
        { property: 'nivelAcesso', label: 'Nível de acesso', columnLabel: 'Acesso', type: 'number', options: NIVEIS_SENSIBILIDADE, tagColumn: true, column: true, columnWidth: '140px', default: 1 },
        { property: 'indAtivo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_ATIVO, tagColumn: true, column: true, columnWidth: '120px', default: true }
      ]
    },
    {
      resource: 'auditoria-tabela/notificacao',
      title: 'Notificações',
      singular: 'notificação',
      feminine: true,
      parentKeys: ['banco', 'tabela'],
      fields: [
        { property: 'nivelSensibilidade', label: 'Nível de sensibilidade', columnLabel: 'Sensibilidade', type: 'number', options: NIVEIS_SENSIBILIDADE, tagColumn: true, key: true, column: true, columnWidth: '160px', default: 1 },
        {
          property: 'grupoEmail', label: 'Grupo de e-mail', required: true, column: true,
          optionsFrom: { resource: 'grupo-email', value: 'grupoEmail', label: 'descricao' }
        },
        { property: 'indAtivo', label: 'Situação', type: 'boolean', options: SITUACAO_POR_ATIVO, tagColumn: true, column: true, columnWidth: '120px', default: true }
      ]
    },
    {
      resource: 'auditoria-tabela/expurgo',
      title: 'Expurgo',
      singular: 'expurgo',
      single: true,
      parentKeys: ['banco', 'tabela'],
      fields: [
        { property: 'retencaoDias', label: 'Retenção (dias)', type: 'number', column: true, default: 365, help: '0 = sem expurgo' }
      ]
    }
  ]
};

export const grupoEmailDef: CrudResource = {
  resource: 'grupo-email',
  title: 'Grupo de e-mail',
  cascadeDelete: 'destinatários do grupo',
  subtitle: 'Grupos de destinatários (thl0011)',
  singular: 'grupo',
  titleField: 'descricao',
  fields: [
    { property: 'grupoEmail', label: 'Grupo', key: true, column: true, maxLength: 20, gridColumns: 4, placeholder: 'TI-INTEGRACAO' },
    { property: 'descricao', label: 'Descrição', column: true, maxLength: 60, gridColumns: 8, placeholder: 'Equipe de integração' }
  ],
  children: [
    {
      resource: 'grupo-email/usuario',
      title: 'Destinatários',
      singular: 'destinatário',
      noUpdate: true,
      parentKeys: ['grupoEmail'],
      fields: [
        {
          property: 'usuario', label: 'Usuário', key: true, required: true, column: true,
          gridColumns: 5, icon: 'an an-user', clean: true, placeholder: 'super', help: 'Usuário do Datasul'
        },
        {
          property: 'emailAlternativo', label: 'E-mail alternativo', key: true, column: true,
          gridColumns: 7, icon: 'an an-envelope', clean: true, placeholder: EMAIL_PLACEHOLDER,
          pattern: EMAIL_PATTERN, errorMessage: EMAIL_ERRO,
          help: 'Em branco usa o e-mail do usuário. Preencha para incluir o mesmo usuário com outro endereço.'
        }
      ]
    }
  ]
};

export const emailDef: CrudResource = {
  resource: 'email-parametro',
  title: 'E-mail',
  subtitle: 'Parâmetros de envio de e-mail',
  singular: 'parâmetro de e-mail',
  fields: [
    { property: 'emailParam', label: 'Código', key: true, column: true, maxLength: 40, placeholder: 'ERRO-INTEGRACAO' },
    {
      property: 'grupoEmail', label: 'Grupo de e-mail', required: true, column: true,
      optionsFrom: { resource: 'grupo-email', value: 'grupoEmail', label: 'descricao' }
    },
    { property: 'assunto', label: 'Assunto', required: true, column: true, gridColumns: 12, placeholder: 'Erro em integração' },
    {
      property: 'remetente', label: 'Remetente', column: true, icon: 'an an-envelope', clean: true,
      placeholder: 'nao-responda@empresa.com.br', pattern: EMAIL_PATTERN, errorMessage: EMAIL_ERRO
    },
    {
      property: 'copia', label: 'Cópia', gridColumns: 12, icon: 'an an-envelope', clean: true,
      placeholder: 'fiscal@empresa.com.br, ti@empresa.com.br',
      pattern: EMAILS_PATTERN, errorMessage: EMAILS_ERRO, help: 'Endereços separados por vírgula.'
    },
    { property: 'importancia', label: 'Importância', type: 'number' },
    { property: 'logGerar', label: 'Gera log', type: 'boolean', default: true },
    {
      property: 'mensagem', label: 'Mensagem', tab: 'Mensagem', gridColumns: 12, html: true, richText: true,
      placeholder: 'Ex.: O objeto #1# retornou erro em #2#.', help: AJUDA_MARCADORES
    }
  ]
};

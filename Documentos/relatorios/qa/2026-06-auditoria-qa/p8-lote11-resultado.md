# P8-L11-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
MEDIA|EmailParamRepository|loadRecipients|B4|BAIXO|CIRURGICA|guard-groupCode-vazio-antes-FOR-EACH-sem-acesso-banco
MEDIA|EmailService|saveReturn|B1|BAIXO|CIRURGICA|error-status-error-incluir-parametro-success-emailLogger-save-escopo-reduzido
MEDIA|EmailParamRepository|loadEmailParameters-loadConnectionParameters|P3|BAIXO|CIRURGICA|prefixo-EmailParamRepository-3-AppError-escopo-reduzido
MEDIA|RestConnector|validateExecutionInput-executeTokenRequest|P3|BAIXO|CIRURGICA|prefixo-RestConnector-6-AppError-escopo-reduzido
MEDIA|MessageFactory|createStructureStrategy|P3|BAIXO|CIRURGICA|prefixo-MessageFactory-2-AppError-escopo-reduzido
MEDIA|MessageConfigLoader|load-loadForInbound|P3|BAIXO|CIRURGICA|prefixo-MessageConfigLoader-4-AppError-escopo-reduzido
MEDIA|ConnectorFactory|createConnector|P3|BAIXO|CIRURGICA|prefixo-ConnectorFactory-1-AppError-escopo-reduzido
MEDIA|ConnectorConfig|initialize|P3|BAIXO|CIRURGICA|prefixo-ConnectorConfig-4-AppError-escopo-reduzido
MEDIA|AuthenticationConfig|initialize|P3|BAIXO|CIRURGICA|prefixo-AuthenticationConfig-2-AppError-escopo-reduzido
MEDIA|OutboundMessage|appendPayloadObject-addPathParameter|P3|BAIXO|CIRURGICA|prefixo-OutboundMessage-3-AppError-escopo-reduzido
MEDIA|OutboundObjectContext|getAdditionalDataContent-getAdditionalData|P3|BAIXO|CIRURGICA|prefixo-OutboundObjectContext-2-AppError-escopo-reduzido
MEDIA|InboundMessage|validatePayload-appendPayloadObject-defaults|P3|BAIXO|CIRURGICA|prefixo-InboundMessage-8-AppError-escopo-reduzido
MEDIA|TokenProvider|parsingToken|P3|BAIXO|CIRURGICA|prefixo-TokenProvider-5-AppError-escopo-reduzido
MEDIA|JsonWriter|toJsonFromBuffer|P3|BAIXO|CIRURGICA|prefixo-JsonWriter-1-AppError-escopo-reduzido
MEDIA|RestConnector|execute|F3|MEDIO|CIRURGICA|validacao-HTTPS-URL-begins-https-apos-buildRequestUrl

# P8-L11-NOTAS
# Item 1 (B4 MEDIA): EmailParamRepository.loadRecipients - CIRURGICA BAIXO
#   - NOTA DE LOCALIZAÇÃO: item nomeado como EmailMessageFactory.loadRecipients na flag P4 (metodo
#     estava ali antes da refatoracao D*). No codigo atual, loadRecipients esta em EmailParamRepository.
#   - Problema: sem guard para groupCode vazio/null.
#     'for each ... where cod-grp-usuar = groupCode' com groupCode = '' escaneia todos os registros
#     com grupo vazio, podendo retornar destinatarios nao intencionados.
#   - NO-LOCK ja esta correto em todos os acessos (FOR EACH + FIND interno) — sem lock escalation
#   - FIND usuar_mestre.cod_usuario dentro do FOR EACH: padrao ABL aceitavel; eficiencia depende de
#     indice em cod_usuario (assumido presente como chave Datasul)
#   - Fix: adicionar antes do FOR EACH:
#       if not StringUtil:hasValue( groupCode ) then
#           return ''.
#   - Dependentes: EmailMessageFactory.constructor (chamador — nenhuma mudanca necessaria)
#
# Item 2 (B1 MEDIA ACEITO-PARC): EmailService.saveReturn - CIRURGICA BAIXO
#   - EmailService usa routine-level on error undo, throw
#   - sender() chama executeDatasulMailService() -> run pi-execute4 -> output table tt-erros
#     depois chama saveReturn()
#   - saveReturn() usa 'not temp-table tt-erros:has-records' para sucesso mas NAO verifica
#     error-status:error (que pode estar definido mesmo sem registros em tt-erros)
#   - ESCOPO ACEITO-PARC: adicionar apenas error-status:error ao parametro success
#   - Fix linha 94:
#       // antes
#       emailLogger:save( emailMessageFactory, not temp-table tt-erros:has-records ).
#       // depois
#       emailLogger:save( emailMessageFactory,
#                         not error-status:error and not temp-table tt-erros:has-records ).
#   - ATENCAO: delete procedure hUtapi019 (entre run e saveReturn) nao altera error-status
#   - Verificar em saveReturn() e suficiente para o escopo definido — NÃO alterar assinaturas
#
# Itens 3 (P3 MEDIA ACEITO-PARC): 12 classes - CIRURGICA BAIXO
#   - ESCOPO: apenas adicionar prefixo 'ClassName: ' as mensagens AppError sem prefixo
#   - Literal 17006 MANTIDO (conforme escopo ACEITO-PARC)
#   - Padrao estabelecido no projeto: 'ClassName: mensagem' (sem 'THL-' como mostrado no template)
#   - Classes ja cobertas em lotes anteriores (NAO repetir aqui):
#     ConnectorService (Lote 8 P2), MessageExecutionService (Lote 8 P2),
#     SchedulingService (Lote 9 patch unificado), OutboundMessageService (ja tem prefixo no codigo),
#     MessageRepository (ja tem prefixo no codigo), LpcoMessage (Lote 10 P2),
#     NotaFiscalPorEmbarqueMessage (Lote 10 B1)
#
#   3.1 EmailParamRepository (3 AppErrors):
#     loadEmailParameters linha 33: 'Email parameter code (codigoEmail) was not informed.'
#     loadEmailParameters linha 39: 'Email connection parameters thl-email-param not found.'
#     loadConnectionParameters linha 56: 'Email connection parameters (param_email) not found.'
#     -> prefixar todos com 'EmailParamRepository: '
#
#   3.2 RestConnector (6 AppErrors):
#     validateExecutionInput linha 71: 'ConnectorRequest was not informed.'
#     validateExecutionInput linha 74: 'ConnectorConfig was not informed.'
#     validateExecutionInput linha 78: 'AuthenticationConfig was not informed...'
#     executeTokenRequest linha 154: 'Error obtaining authorization key.'
#     executeTokenRequest linha 157: 'Error response content is null'
#     executeTokenRequest linha 162: 'Error response' -> melhorar para 'Error parsing token response.'
#     -> prefixar todos com 'RestConnector: '
#
#   3.3 MessageFactory (2 AppErrors):
#     linha 40: substitute('Unable to instantiate message class: &1', messageClass)
#     linha 50: substitute('Message class &1 is not a valid OutboundMessage subclass.', ...)
#     -> prefixar ambos com 'MessageFactory: '
#
#   3.4 MessageConfigLoader (4 AppErrors):
#     linhas 47, 51, 83, 87: todas substituicoes sem prefixo
#     -> prefixar com 'MessageConfigLoader: ' mantendo substitute()
#
#   3.5 ConnectorFactory (1 AppError):
#     linha 28: substitute('Unsupported connector type: &1.', connectorType)
#     -> prefixar com 'ConnectorFactory: '
#
#   3.6 ConnectorConfig (4 AppErrors):
#     linhas 47, 50, 56, 62: mensagens sobre conexao REST sem prefixo de classe
#     -> prefixar com 'ConnectorConfig: ' nas 4 mensagens
#
#   3.7 AuthenticationConfig (2 AppErrors):
#     linha 69: 'Codigo de conexao de autenticacao nao informado.'
#     linha 75: substitute('Conexao autenticacao REST nao encontrada: &1', ...)
#     -> prefixar com 'AuthenticationConfig: '
#     NOTA: Lote 2 aplicou o guard de connectionCode vazio mas nao adicionou o prefixo
#
#   3.8 OutboundMessage (3 AppErrors):
#     linha 39: 'Outbound object context was not informed.'
#     linhas 46+50: substitute('appendPayloadObject is not implemented for object &1.', ...) (2x)
#     linha 59: 'Path parameter name was not informed.'
#     -> prefixar com 'OutboundMessage: '
#
#   3.9 OutboundObjectContext (2 AppErrors):
#     linha 71: 'Additional data content field name was not informed.'
#     linha 79: 'Additional data field name was not informed.'
#     -> prefixar com 'OutboundObjectContext: '
#
#   3.10 InboundMessage (8 AppErrors parcialmente sem prefixo):
#     linha 79 (dispatchInbound): tem 'Inbound' mas nao 'InboundMessage: '
#       substitute('Inbound method &1 is not supported for object &2.', ...)
#     linhas 121, 125, 129, 133 (4 metodos default nao-implementados): sem prefixo
#       'PATCH is not implemented for object &1.', 'POST...', 'DELETE...', 'GET...'
#     linha 164 (validatePayload): 'Inbound JSON payload was not informed.'
#     linhas 179, 185 (appendPayloadObject): 'Payload object was not informed.'
#                                            'Current payload is not a JsonArray...'
#     -> prefixar todos com 'InboundMessage: '
#     NOTA: linhas 143 (validateRequiredFields) e 144 ja tem prefixo 'InboundMessage: ' — nao alterar
#
#   3.11 TokenProvider (5 AppErrors):
#     thl-extensions/integration/mmcm/connectors/auth/TokenProvider.cls linhas 27,35,41,49,55
#     'Authentication response does not contain data node.'
#     'Authentication data node is invalid.'
#     'Authentication token node was not found.'
#     'Authentication token data is invalid.'
#     'Authentication token was not returned.'
#     -> prefixar todos com 'TokenProvider: '
#
#   3.12 JsonWriter (1 AppError):
#     linha 27: 'toJsonFromBuffer: invalid handle.'
#     -> prefixar com 'JsonWriter: ' -> 'JsonWriter: toJsonFromBuffer: invalid handle.'
#
# Item 4 (F3 MEDIA): RestConnector.execute - CIRURGICA MEDIO
#   - CONSISTENCIA: comportamento de execute() JA E consistente para Outbound e Scheduling
#     (ambos usam o mesmo CATCH que converte toda excecao em ConnectorResponse de falha)
#   - GAP REAL (flag original P4): 'HTTPS nao enforçado - URL pode ser HTTP'
#   - ServicePointManager:SecurityProtocol = SecurityProtocolType:Tls12 configura TLS 1.2 para
#     conexoes HTTPS mas nao impede URLs http://
#   - Compound ASSIGN atual impede validacao intermediaria da URL
#   - Fix: separar o ASSIGN em dois blocos; adicionar validacao apos buildRequestUrl():
#
#       assign requestUrl                    = buildRequestUrl(connectorRequest)
#              connectorResponse:destination = requestUrl.
#
#       if not (requestUrl begins 'https://') then
#           undo, throw new AppError(
#               substitute('RestConnector: Conexao &1 usa URL HTTP nao segura. Configure baseUrl com HTTPS.',
#                          connectorRequest:connectorConfig:connectionCode), 17006).
#
#       assign authorizationKey              = resolveAuthorizationKey(connectorRequest:connectorConfig)
#              responseContent               = executeRequest( requestUrl, connectorRequest,
#                                                             authorizationKey, connectorResponse)
#              connectorResponse:successRequest  = true
#              connectorResponse:successResponse = isTechnicalSuccess( connectorResponse:statusCode )
#              connectorResponse:content         = responseContent.
#
#   - O undo,throw sera capturado pelo CATCH existente de execute() — contrato ConnectorResponse
#     mantido; successRequest = false; statusMessage = 'Technical error during REST execution: ...'
#   - BREAKING CHANGE: conexoes com baseUrl = http:// falharao imediatamente
#     Verificar ambientes antes de aplicar; considerar LogUtil:warn como alternativa para migracao
#   - NOTA PENDENTE: routine-level on error undo, throw (linha 28) deveria ser block-level
#     Este item esta registrado como B3 no Lote 1 e nao deve ser tratado aqui

# P8-L11-RESUMO
CIRURGICA:15|ESTRUTURAL:0
RISCO-ALTO:0|RISCO-MEDIO:1|RISCO-BAIXO:14
TOTAL:15

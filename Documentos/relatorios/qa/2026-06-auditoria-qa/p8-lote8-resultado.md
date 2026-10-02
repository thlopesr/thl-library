# P8-L8-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|MessageExecutionService|(classe)|P2|BAIXO|CIRURGICA|LogUtil-import-type-of-guard-CAST-OutboundMessage
ALTA|MessageExecutionService|executeOnline|F2|MEDIO|CIRURGICA|CATCH-LogUtil-saveResponse-erro-split-assign-guard
ALTA|ConnectorService|(classe)|P2|BAIXO|CIRURGICA|LogUtil-import-prefixo-ConnectorService-AppError
ALTA|ConnectorService|execute|F1|MEDIO|CIRURGICA|valid-object-response-LogUtil-warn-HTTP-CATCH-factory

# P8-L8-NOTAS
# Item 1 (P2 ALTA): MessageExecutionService - nivel de classe
#   - Sem LogUtil: import ausente, nenhuma chamada em executeOnline()
#   - CAST sem TYPE-OF: cast(message_, OutboundMessage) na linha do pathParameters
#     se message_ nao for OutboundMessage -> SysError generico sem contexto
#     Fix: if not type-of(message_, OutboundMessage) then undo,throw AppError(17006) antes do CAST
#     Inserir este guard junto com a edicao do F2 (mesma sessao Dev)
#   - AuditLogService: NAO adicionar - camada tecnica sem operacao de negocio rastreavel
#   - EnvironmentResource:resolveParameterCode() ja e o padrao correto (nao acesso direto ao banco) OK
#   - Adicionar: using thl-lib.logging.LogUtil.
#
# Item 2 (F2 ALTA): executeOnline - gap de log e ausencia de CATCH
#   - Compound ASSIGN atual: build do request + ConnectorService.execute() em instrucao unica
#     Se qualquer etapa lanca excecao: connectorResponse fica = ?, saveResponse nunca chamado
#     sit-processamento fica em 1 (pendente) indefinidamente
#   - Contexto critico descoberto: RestConnector.execute() TEM CATCH INTERNO (linhas 56-64 de RestConnector.cls)
#     que converte TODA excecao em ConnectorResponse de falha -> RestConnector NUNCA lanca excecao
#     Portanto CATCH em executeOnline so se ativa para falhas no building do request ou ConnectorConfig
#   - Fix: separar o compound ASSIGN em 2 blocos:
#     (1) build do connectorRequest (com type-of guard antes do CAST)
#     (2) assign connectorResponse = new ConnectorService():execute(connectorRequest).
#   - Adicionar CATCH que:
#     (a) LogUtil:error com obj/aplic/erro
#     (b) se connectorResponse = ?: montar ConnectorResponse de falha + message_:saveResponse(err, false)
#         usa historyEnabled=false - falha antes de conectar nao deve gerar historico
#     (c) undo, throw e - propaga o erro original
#   - Adicionar LogUtil:info na entrada (obj+aplic) e no sucesso (obj+statusCode HTTP)
#   - Requer: using thl-lib.logging.LogUtil.
#
# Item 3 (P2 ALTA): ConnectorService - nivel de classe
#   - Sem LogUtil: import ausente
#   - AppError sem prefixo de classe (P3 implicito):
#     'ConnectorRequest was not informed.' -> 'ConnectorService: requisicao de conector nao informada.'
#     'Unable to resolve integration connector.' -> 'ConnectorService: conector nao resolvido para tipo &1.'
#     Segundo erro: adicionar substitute() com request:connectorType para identificar o tipo problemático
#   - ATENCAO: renomear texto AppError e BREAKING se chamadores comparam literal da mensagem
#     Verificar chamadores de ConnectorService antes de renomear
#   - Adicionar: using thl-lib.logging.LogUtil.
#
# Item 4 (F1 ALTA): ConnectorService.execute - tres lacunas independentes
#   - Lacuna 1 (resposta nula): connector:execute() pode retornar '?' em conector nao-RestConnector mal implementado
#     Fix: after 'assign response = connector:execute(request).':
#     if not valid-object(response) then undo, throw AppError('ConnectorService: conector tipo &1 retornou nulo.', 17006)
#     Para RestConnector: nunca atingido (CATCH interno garante resposta valida)
#   - Lacuna 2 (HTTP failures silenciosas): quando successResponse=false (HTTP 4xx/5xx absorvido pelo
#     CATCH interno do RestConnector), ConnectorService retorna sem nenhuma linha em log PASOE
#     Falha rastreavel em thl-mensagem via saveResponse, mas invisivel em monitor de servidor em tempo real
#     Fix: if not response:successResponse then LogUtil:warn('tipo=&1 status=&2 msg=&3', ...)
#     NOTA: se volume de requests com falha esperada for alto, considerar LogUtil:debug em vez de warn
#   - Lacuna 3 (sem CATCH para excecoes de factory): new ConnectorFactory():createConnector() pode lançar
#     AppError (tipo desconhecido). ConnectorService propaga sem log.
#     Em executeOnline(), se ConnectorFactory lanca antes de ConnectorService.execute() ser chamado,
#     a excecao chega ao CATCH do executeOnline (com fix F2). Mas sem LogUtil:error no nivel do ConnectorService,
#     o log nao identifica que foi o ConnectorService o ponto de falha
#     Fix: CATCH com LogUtil:error('ConnectorService.execute: excecao tipo=&1 erro=&2') + undo, throw e
#   - Separar 'assign response = connector:execute(request).' em instrucao propria (nao no 'return')
#     necessario para que CATCH possa referenciar request:connectorType sem NullPointerError
#   - ANOMALIA FORA DE ESCOPO: RestConnector.cls linha 28 usa 'routine-level on error undo, throw'
#     em vez de 'block-level' - ja sinalizado em P8-L1 como B* de RestConnector - NAO tratar aqui

# P8-L8-RESUMO
CIRURGICA:4|ESTRUTURAL:0
RISCO-ALTO:0|RISCO-MEDIO:2|RISCO-BAIXO:2
TOTAL:4

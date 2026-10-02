# P8-L6-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|OutboundMessageService|constructor|B*|BAIXO|CIRURGICA|valid-object-configuration-messageFactory-alinha-InboundMessageService
ALTA|OutboundMessageService|(classe)|P2|MEDIO|CIRURGICA|CATCH-process-saveResponse-erro-LogUtil-status-DB-correto
ALTA|OutboundMessageService|reprocess|F3|MEDIO|CIRURGICA|guard-SCHEDULE-throw-RPW-pendente-antes-ONLINE
ALTA|Message|constructor|D3|BAIXO|ACEITO-PARC|documentar-invariancia-9-propriedades-avaliar-DI-protected

# P8-L6-NOTAS
# Item 1 (B*): construtor sem valid-object após new — inconsistência com InboundMessageService
#   - Código atual (linhas 41-42): assign configuration = new MessageConfigLoader():load(...)
#                                                         messageFactory = new MessageFactory(configuration)
#   - Risco: se load() retorna ? sem lançar (retorno silencioso), new MessageFactory(?) falha com SysError genérico
#   - Fix — separar assign em dois blocos com valid-object entre eles:
#       assign configuration = new MessageConfigLoader():load( '*', applicationName, objectName, integrationOperation ).
#       if not valid-object( configuration ) then
#           undo, throw new AppError(
#               substitute( 'OutboundMessageService: Configuracao nao encontrada para obj=&1 op=&2.',
#                           objectName, integrationOperation ), 17006 ).
#       assign messageFactory = new MessageFactory( configuration ).
#       if not valid-object( messageFactory ) then
#           undo, throw new AppError( 'OutboundMessageService: MessageFactory nao foi inicializado.', 17006 ).
#   - Complemento recomendado: após messageFactory, adicionar
#       if not type-of( messageFactory:getMessage(), OutboundMessage ) then
#           undo, throw new AppError( 'OutboundMessageService: Mensagem nao e OutboundMessage.', 17006 ).
#     para equivalência total com InboundMessageService (que tem valid-object + type-of)
#   - Referência: InboundMessageService.constructor linhas ~35-45 (valid-object + type-of após criação)
#   - Aproveitar a mesma edição para adicionar prefixo 'OutboundMessageService:' em TODAS as mensagens
#     AppError da classe (ensureBuildStarted, ensureReadyForProcessing, getLastConnectorResponse, etc.)
#     — impacto zero em runtime, elimina ambiguidade em PASOE log
#
# Item 2 (P2): sem CATCH em process() — sit-processamento fica 1 (pendente) se lança antes de saveResponse
#   - process() chama processOnline() ou scheduleProcessing() sem CATCH envolvente
#   - SchedulingService.schedule() chama message_:saveResponse() ANTES de lançar em qualquer caminho de erro
#   - MessageExecutionService.executeOnline() chama saveResponse() APÓS receber resposta do conector
#   - SE o conector recusa conexão (lança antes de retornar resposta), executeOnline() lança sem chamar saveResponse()
#     -> thl-mensagem.sit-processamento permanece 1 (pendente), nunca atualizado para 2 (erro)
#   - Fix: adicionar CATCH em process() com dois comportamentos:
#       catch e as Progress.Lang.Error:
#           /* salvar status de erro apenas se saveResponse ainda nao foi chamado neste fluxo */
#           if not valid-object( connectorResponse ) then
#           do:
#               define variable errResponse as ConnectorResponse no-undo.
#               assign errResponse                 = new ConnectorResponse()
#                      errResponse:successRequest  = false
#                      errResponse:successResponse = false
#                      errResponse:successProcess  = false
#                      errResponse:statusCode      = 0
#                      errResponse:statusMessage   = e:getMessage(1)
#                      errResponse:destination     = ''.
#               if valid-object( messageFactory ) and valid-object( messageFactory:getMessage() ) then
#                   messageFactory:getMessage():saveResponse( errResponse, false ).
#           end.
#           LogUtil:error( substitute( 'OutboundMessageService.process: obj=&1 erro=&2',
#                                      configuration:objectName, e:getMessage(1) ) ).
#           undo, throw e.
#       end catch.
#   - Referência: InboundMessageService.receive() (CATCH que chama inboundMessage:saveInboundError + relança)
#   - Impacto: requer 'using thl-lib.logging.LogUtil' no cabeçalho
#   - ConnectorResponse em escopo: ConnectorResponse já importado via 'using thl-lib.integration.connectors.core.*'
#   - MessageExecutionService não tem CATCH: está correto — é camada inferior; o CATCH pertence ao orquestrador
#
# Item 3 (F3): reprocess() força ONLINE sem verificar se job RPW está pendente para mensagens SCHEDULE
#   - Código atual (linha 82): return this-object:process( ExecutionMode:ONLINE ).
#   - Fluxo SCHEDULE então reprocess:
#       (1) process(SCHEDULE) -> SchedulingService.schedule() -> thl1989z.p cria job RPW
#                             -> message_:saveResponse(resp, hist) -> qtd-tentativas = 1
#       (2) reprocess(code)   -> process(ONLINE) -> executeOnline() -> saveResponse(resp, hist) -> qtd-tentativas = 2
#       (3) job RPW executa   -> (via thl1989z) -> executa mensagem novamente -> qtd-tentativas = 3
#   - Resultado: duplo envio real + contador inflado + histórico com 3 entradas (2 reais + 1 agendamento)
#   - Fix: adicionar guard no início de reprocess():
#       if configuration:executionModeValue = ExecutionMode:SCHEDULE then
#           undo, throw new AppError(
#               substitute( 'OutboundMessageService: Mensagem &1 usa modo SCHEDULE. ' +
#                           'Cancele o job RPW pendente antes de reprocessar.', messageCode ),
#               17006 ).
#   - Callers que precisam forçar ONLINE em mensagem SCHEDULE devem:
#       (1) cancelar job RPW externamente
#       (2) chamar loadForReprocess(code) + process(ExecutionMode:ONLINE) diretamente
#   - NOTA técnica: Message.executionMode é propriedade 'protected get. private set.' — OutboundMessageService
#     não tem acesso ao modo armazenado na mensagem carregada. A guarda usa configuration:executionModeValue
#     como proxy para o modo da configuração (que determinou o modo original do envio)
#   - ESCOPO relacionado: SchedulingService.schedule F3 ALTA e SchedulingService.schedule B1 MÉDIA
#     estão pendentes no backlog — tratarão o lado do agendador
#
# Item 4 (D3 ACEITO-PARC): construtor com dependência concreta hardcoded — NAO MODIFICAR O CÓDIGO
#   - Código atual (linhas 51-52): this-object:repository = new MessageRepository()
#                                  this-object:errorHandler = new ErrorHandler()
#   - Ação permitida: SOMENTE documentação (comentário + avaliação técnica)
#
#   --- CONTRATO DE INVARIÂNCIA (comentário a inserir acima do constructor na sessão Dev) ---
#   /* Invariância pós-construção de Message:
#      Após execução do constructor, as seguintes propriedades são garantidas como válidas:
#        (a) objectName, applicationName, integrationOperation — character non-empty
#        (b) methodType, connectorType, executionMode          — integer não-zero
#        (c) integrationDirection                              — logical não-unknown
#        (d) repository                                        — valid-object (MessageRepository)
#        (e) errorHandler                                      — valid-object (ErrorHandler)
#      Subclasses invocam super() e herdam esta garantia sem verificação adicional.
#      Callers (OutboundMessageService, InboundMessageService) podem omitir valid-object
#      após 'new ConcreteMessage(...)' pois a invariância é assegurada pelo constructor.
#   */
#
#   --- AVALIAÇÃO DE INJEÇÃO DE DEPENDÊNCIA (ambientes dev/homologação) ---
#   - MessageRepository e ErrorHandler são instâncias stateless: não têm campos estáticos
#     nem dependem de configuração de ambiente — DI seria útil apenas para substituição em testes.
#   - Opção A — constructor overload (invasiva):
#       constructor protected Message( ...<7 params>...,
#                                      repo    as MessageRepository,
#                                      handler as ErrorHandler ).
#     Produção continua usando o constructor de 7 params; testes instanciam via overload.
#     Desvantagem: aumenta superfície da API da classe abstrata.
#   - Opção B — Template Method factory methods (preferida, não invasiva):
#       method protected MessageRepository createRepository(). return new MessageRepository(). end.
#       method protected ErrorHandler      createErrorHandler(). return new ErrorHandler(). end.
#     Constructor substitui 'new MessageRepository()' por 'this-object:createRepository()' e idem
#     para ErrorHandler. Subclasses de teste sobrescrevem os factory methods para retornar stubs.
#     Código de produção permanece inalterado em comportamento; o constructor não muda de assinatura.
#   - Opção B é preferida: muda apenas 2 linhas do constructor; callers existentes não são afetados.
#   - Ambas as opções são EXCLUSIVAS de dev/homologação e não alteram comportamento em produção.

# P8-L6-RESUMO
CIRURGICA:3|ACEITO-PARC:1
RISCO-ALTO:0|RISCO-MEDIO:2|RISCO-BAIXO:2
TOTAL:4

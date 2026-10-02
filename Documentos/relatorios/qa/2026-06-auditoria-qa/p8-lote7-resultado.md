# P8-L7-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|InboundMessage|validateRequiredFields|B*|BAIXO|CIRURGICA|addError-loop-throwIfHasErrors-guard-unknown-prefixo
MEDIA|InboundMessage|methodPost|D5|MEDIO|CIRURGICA|abstract-force-subclasse-compiletime-stubs-3-nao-lidas
MEDIA|InboundMessageService|constructor|D3|BAIXO|CIRURGICA|overload-MessageConfig-InboundMessage-preserva-existente
ALTA|InboundMessageService|receive|F1|ALTO|CIRURGICA|messageCreated-CATCH-aninhado-throw-sem-undo-mascara-original
MEDIA|InboundMessageService|receive|F2|BAIXO|CIRURGICA|LogUtil-error-CATCH-antes-saveInboundError-observabilidade

# P8-L7-NOTAS
# Item 1 (B* ALTA): validateRequiredFields - dois problemas independentes
#   - Problema 1: throwError() em loop chama clearErrors() antes de adicionar -> lanca na 1a iteracao
#     apenas o PRIMEIRO campo faltante e reportado; campos 2,3,... ignorados
#     Fix: trocar throwError() por addError() no loop; adicionar throwIfHasErrors() apos o loop
#     Resultado: AppError unico com N mensagens (uma por campo faltante) - melhor UX para integrador
#   - Problema 2: se subclasse sobrescreve getRequiredFields() e retorna '?' por bug,
#     StringUtil:hasValue(?) = false -> validateRequiredFields retorna sem validar nada
#     Fix: guard no inicio: if requiredFields = ? then undo, throw AppError(objectName, 17006)
#     Distingue '?' (bug de subclasse) de '' (intencional, sem campos obrigatorios)
#   - Aproveitar para prefixar mensagem: 'Required field X...' -> 'InboundMessage: campo obrigatorio X...'
#   - ErrorHandler.throwError(): clearErrors() + addError() + throwIfHasErrors() - CONFIRMA lanca imediato
#   - Mudanca nao requer alteracao em subclasses (metodo protected interno)
#
# Item 2 (D5 MEDIA): methodPost - nao-abstract = falha de compilacao silenciosa
#   - methodPost nao e abstract em InboundMessage (classe abstract) - subclasse pode compilar sem override
#   - Default throw 'POST is not implemented' so descoberto em runtime (producao)
#   - Fix: declarar 'method protected abstract void methodPost(context as InboundObjectContext).'
#   - LpcoMessage e UsuarioMessage: JA TEM override - ok, nao precisam de stub
#   - DocumentoMessage, EmbarqueMessage, NotaFiscalPorEmbarqueMessage: verificar antes de aplicar
#     se nao tiverem override, adicionar stub explicito com AppError 17006 antes de tornar abstract
#   - Recompilacao em cascata: todo modulo thl-lib.integration.messaging.inbound deve ser recompilado
#   - methodPatch, methodDelete, methodGet: manter como default-throw (operacoes opcionais)
#   - InboundRouteResolver: NAO e usado em InboundMessageService (contrario ao esperado pelo P7)
#     A resolucao de rota ocorre no chamador (resourcen.p) que passa objectName diretamente
#
# Item 3 (D3 MEDIA): constructor - hardcoded MessageConfigLoader + MessageFactory
#   - Constructor atual faz FIND no banco (MessageConfigLoader.load()) a cada instanciacao
#   - Impossivel criar InboundMessageService sem acesso ao banco em testes
#   - Fix: adicionar constructor overload: (configuration as MessageConfig, inboundMessage as InboundMessage)
#     assign this-object:configuration = configuration_ / this-object:inboundMessage = inboundMessage_
#     + valid-object check + type-of check (mesmas validacoes do constructor de 4 params)
#   - Constructor de 4 params permanece INALTERADO para producao
#   - Aproveitar para adicionar prefixo 'InboundMessageService:' nas 2 AppError do constructor de 4 params
#
# Item 4 (F1 ALTA): receive() - mascaramento de erro original
#   - BUG CRITICO: se registerMessage() (Etapa 1) falha -> thl-mensagem NAO criado
#     CATCH chama saveInboundError() -> loadMessage() faz FIND -> nao acha registro -> lanca nova excecao
#     Nova excecao SUBSTITUI a original -> chamador ve 'Mensagem nao encontrada' em vez do erro real
#   - Fix 1: adicionar flag 'define variable messageCreated as logical no-undo.'
#     'assign messageCreated = true.' APOS registerMessage() na Etapa 1
#     No CATCH: if valid-object(inboundMessage) AND messageCreated then ... saveInboundError
#   - Fix 2: envolver saveInboundError() em DO com CATCH aninhado:
#       do:
#           inboundMessage:saveInboundError(...)
#           catch e2 as Progress.Lang.Error:
#               LogUtil:error('falha ao persistir erro no BD - &1', e2:getMessage(1)).
#           end catch.
#       end.
#     CATCH aninhado: captura falhas em saveInboundError sem mascarar errorObject original
#   - Fix 3: trocar 'undo, throw errorObject' por 'throw errorObject'
#     'undo' reverte a transacao implicita incluindo as gravacoes de saveInboundError
#     Sem 'undo': gravacoes de saveInboundError permanecem na transacao ate commit/rollback pelo PASOE
#     Limitacao PASOE STATEFREE: se framework reverter sessao por erro, gravacoes DB perdidas de qualquer jeito
#     LogUtil:error() e a unica garantia de rastreabilidade persistente neste cenario
#   - Aplicar F1 e F2 na mesma edicao de receive()
#
# Item 5 (F2 MEDIA): receive() - gap de LogUtil
#   - Nenhum LogUtil:error() em todo receive() - erro fica sem rastro se BD indisponivel ou undo reverte
#   - Fix: LogUtil:error() no inicio do CATCH, ANTES de saveInboundError()
#     LogUtil:error('InboundMessageService.receive: obj=&1 aplic=&2 erro=&3', objectName, appName, err)
#     Garante entrada no log PASOE independentemente do resultado da persistencia DB
#   - F2 esta incorporado na correcao de F1 - aplicar na mesma edicao

# P8-L7-RESUMO
CIRURGICA:5|ESTRUTURAL:0
RISCO-ALTO:1|RISCO-MEDIO:1|RISCO-BAIXO:3
TOTAL:5

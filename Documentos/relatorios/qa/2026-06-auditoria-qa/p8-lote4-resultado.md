# P8-L4-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|EmailMessageFactory|(classe)|D*|ALTO|ESTRUTURAL|extrair-DB-para-EmailParamRepository-remover-logica-negocio
MEDIA|MessageFactory|createStructureStrategy|B3|BAIXO|CIRURGICA|TYPE-OF-antes-CAST-guard-valido-no-caller
MEDIA|OutboundMessage|appendPayloadObject|D4|MEDIO|CIRURGICA|remover-routeAppend-mover-IF-para-strategy-caller
MEDIA|OutboundMessageService|process|D4|BAIXO|CIRURGICA|extrair-evaluateResponse-CASE-vira-dispatcher-puro

# P8-L4-NOTAS
# Item 1 (D*): EmailMessageFactory acumula Factory+Repository(4 tabelas)+VO+logica-negocio
#   - Remover CAN-FIND redundante em loadRecipients antes do FOR EACH
#   - Dependencia implicita em buffer thl-email-param posicionado entre constructor e loadRecipients
#   - Refatoracao: EmailParamRepository carrega os 4 FINDs; factory recebe dados prontos
#   - Unico chamador conhecido: EmailService (EMSVC->EMFAC no grafo P1)
#   - Tratar como sessao Dev dedicada com criacao de nova classe EmailParamRepository
#
# Item 2 (B3): createStructureStrategy - CAST sem TYPE-OF guard
#   - cast(message_, OutboundMessage) pode lancar SysError opaco se tipo errado
#   - Adicionar: if not type-of(message_, OutboundMessage) then undo, throw AppError(17006)
#   - Caller (OutboundMessageService.beginBuild): adicionar valid-object apos atribuicao
#   - Editar MessageFactory.cls e OutboundMessageService.cls na mesma sessao
#
# Item 3 (D4): OutboundMessage.routeAppendPayloadObject contem IF de seleção na base
#   - routeAppendPayloadObject(if hasAdditionalData -> overload 1 else overload 2) viola SRP
#   - Remover routeAppendPayloadObject; IF migra para callers (MultipleMessageStructure, SingleMessageStructure)
#   - Pesquisar TODAS as ocorrencias de routeAppendPayloadObject antes de remover
#   - Verificar subclasses concretas (LpcoMessage, PedidoMessage, etc.) para confirmar overloads usados
#
# Item 4 (D4): OutboundMessageService.process - duplicacao ONLINE/SCHEDULE
#   - Ramos ONLINE e SCHEDULE identicos: valid-object(response) + return successResponse
#   - Extrair para: method private logical evaluateResponse(response as ConnectorResponse)
#   - D4 residual (CASE em si) = backlog estrutural para Strategy pattern; ENUM=3 valores aceita CASE
#   - return false no fim do metodo original era inalcancavel; comportamento preservado

# P8-L4-RESUMO
CIRURGICA:3|ESTRUTURAL:1
RISCO-ALTO:1|RISCO-MEDIO:1|RISCO-BAIXO:2
TOTAL:4

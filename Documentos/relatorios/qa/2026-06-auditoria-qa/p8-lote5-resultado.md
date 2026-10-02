# P8-L5-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|MessageRepository|createMessage|B4|ALTO|CIRURGICA|DO-TRANSACTION-CATCH-LogUtil-documentar-atomicidade-chamador
MEDIA|MessageRepository|(classe)|P3|BAIXO|CIRURGICA|prefixo-MessageRepository-nas-3-mensagens-AppError
MEDIA|EnvironmentRepository|findEnvironmentCodeByPropath|B4|MEDIO|CIRURGICA|block-level-guard-vazio-fallback-find-first-determinístico

# P8-L5-NOTAS
# Item 1 (B4): createMessage sem DO TRANSACTION cria transacao implicita que comita ao retornar
#   - Se createItemMessage() falhar apos createMessage() retornar, thl-mensagem fica orphao
#   - Correcao: DO TRANSACTION em createMessage + CATCH LogUtil antes de relançar
#   - Chamador (Message.cls via MSGS->MREP) deve envolver createMessage+createItemMessage em DO TRANSACTION
#   - Mesmo padrao (sem DO TRANSACTION) em createItemMessage, createHistoryMessage, createMessageContent
#   - Aplicar o mesmo fix nos outros metodos de criacao na mesma sessao Dev
#   - Requer: using thl-lib.logging.LogUtil no cabecalho
#
# Item 2 (P3): 3 AppError sem prefixo de classe
#   - loadMessage: 'Mensagem &1 nao encontrada...' -> 'MessageRepository: Mensagem &1...'
#   - ensureMessageCode: 'Message code was not informed.' -> 'MessageRepository: Codigo de mensagem nao informado.'
#   - ensureReferenceCode: 'Reference code was not informed.' -> 'MessageRepository: Codigo de referencia nao informado.'
#   - Alem de prefixo, aproveitar para padronizar idioma (ingles->portugues nos dois ensureXxx)
#   - CUIDADO: verificar callers que comparem literal de mensagem antes de aplicar
#
# Item 3 (B4): findEnvironmentCodeByPropath - routine-level + fallback nao-determinístico
#   - routine-level -> block-level (afeta todos os metodos do arquivo)
#   - Adicionar guard: if trim(propathValue) = '' then undo,throw AppError(17006)
#   - Fallback: trocar 'if available thl-ambiente' (pós-loop) por 'find first thl-ambiente no-lock'
#   - findVariableValue: bug de condicao invertida (if not available) - JA SINALIZADO em spawn-task, NAO corrigir aqui
#   - A mensagem de erro original 'Environment not identified.' tambem nao tem prefixo - corrigir na mesma edicao
#   - Verificar se EnvironmentUtil.cls e afetado pelo comportamento do fallback alterado

# P8-L5-RESUMO
CIRURGICA:3|ESTRUTURAL:0
RISCO-ALTO:1|RISCO-MEDIO:1|RISCO-BAIXO:1
TOTAL:3

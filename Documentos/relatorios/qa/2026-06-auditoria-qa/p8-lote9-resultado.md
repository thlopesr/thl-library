# P8-L9-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
MEDIA|SchedulingService|schedule|B1|MEDIO|CIRURGICA|CATCH-run-thl1989z-saveResponse-erro-throw-unificada
ALTA|SchedulingService|schedule|F3|MEDIO|CIRURGICA|successProcess-null-statusCode-numPedido-RPW-unificada
MEDIA|SchedulingService|schedule|F1|MEDIO|CIRURGICA|CATCH-LogUtil-error-propaga-preserva-estado-unificada

# P8-L9-NOTAS
# PATCH UNIFICADO: B1 + F3 + F1 — tres categorias, um unico patch em schedule()
#
# Item 1 (B1 MEDIA) + Item 3 (F1 MEDIA): ausencia de CATCH para erros do run thl1989z.p
#   - block-level on error undo, throw JA EXISTE na linha 17 — B1 nao e sobre isso
#   - O problema: se run thl\thl1989z.p lanca Progress.Lang.Error (procedure nao encontrada, DB,
#     timeout), a excecao sobe sem chamar message_:saveResponse()
#     -> thl-mensagem fica com sit-processamento = 1 (pendente) indefinidamente
#     -> nenhuma entrada em PASOE log
#   - Caminhos return-value='NOK' e numPedidoExecucao=0/null JA chamam saveResponse antes de throw
#     O CATCH so e ativado para excecoes do run (nao para os lanca AppError explicitamente)
#   - Fix: CATCH ao nivel do metodo:
#       (a) LogUtil:error('SchedulingService.schedule: excecao ao agendar msg=&1 erro=&2', messageCode, e)
#       (b) if not valid-object(response): montar ConnectorResponse de falha + message_:saveResponse(err, false)
#       (c) throw e (SEM undo) — preserva gravacoes de saveResponse na transacao corrente
#     NOTA: mesma logica do InboundMessageService.receive F1 fix (Lote 7)
#           'undo, throw' reverteria o saveResponse do CATCH; 'throw' preserva
#           Em PASOE STATEFREE o framework pode reverter de qualquer forma, mas LogUtil:error e garantido
#
# Item 2 (F3 ALTA): assimetria de estado entre scheduling e fluxo ONLINE
#   - Caminho de sucesso atual (linhas 73-84):
#       response:successProcess  = true   // BUG: RPW ainda nao executou o HTTP
#       response:statusCode      = 200    // BUG: devia ser numPedidoExecucao
#   - Comentario do proprio metodo (linha 25): 'successProcess = ? indica que o processamento ainda nao ocorreu'
#     O codigo contradiz o comentario — bug introduzido na implementacao
#   - Impacto confirmado via MessageRepository.saveResultMessage() linha 101:
#       successProcess = true -> sit-processamento = 3 (processado com sucesso) — ERRADO antes do RPW executar
#       successProcess = ?    -> sit-processamento = 4 (desconhecido/pendente)  — CORRETO
#   - Monitoramento que ve sit-processamento=3 antes do RPW executar registra falso positivo
#   - Fix:
#       response:successProcess = ?               // sit-processamento=4 ate RPW executar
#       response:statusCode     = numPedidoExecucao  // numero do job RPW para rastreabilidade
#   - Quando RPW executar: saveResponse() sobrescreve sit-processamento e statusCode com resultado HTTP real
#     numPedidoExecucao fica visivel no historico (se historyEnabled=true)
#   - VERIFICAR: se ferramentas de retry/monitoramento filtram por sit-processamento — ver Atencao
#
# ADICIONAIS no patch unificado:
#   - using thl-lib.logging.LogUtil. (ADICIONADO ao cabecalho)
#   - LogUtil:info no caminho de sucesso (msg agendada + pedido RPW)
#   - LogUtil:warn nos caminhos NOK e pedido invalido
#   - Prefixo 'SchedulingService: ' em todos os AppError (padrao P3)
#
# ANOMALIA FORA DE ESCOPO detectada: MessageRepository.saveResultMessage() linha 102
#   b-thl-mensagem.sit-requisicao = if successResponse = ? then 4 else if successRequest then 3 else 2
#   Verifica 'successResponse = ?' mas usa 'successRequest' no ramo positivo (nao 'successResponse')
#   Parece copy-paste invertido entre sit-requisicao e sit-retorno — sinalizado como spawn-task separado

# P8-L9-RESUMO
CIRURGICA:3|ESTRUTURAL:0
RISCO-ALTO:0|RISCO-MEDIO:3|RISCO-BAIXO:0
TOTAL:3

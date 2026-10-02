# P8-L10-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|D2|ALTO|ESTRUTURAL|extrair-4-operacoes-NotaFiscalPorEmbarqueService-backlog
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|B1|BAIXO|CIRURGICA|setPreFaturFree-FINALLY-code0-17006-prefix
ALTA|LpcoMessage|methodPost|B4|MEDIO|CIRURGICA|DO-TRANSACTION-create-assigns-appendItem-escopo-reduzido
MEDIA|LpcoMessage|methodPost-methodDelete|P2|BAIXO|CIRURGICA|LogUtil-info-prefix-LpcoMessage-AppError
MEDIA|EmbarqueMessage|methodPost|B4|MEDIO|CIRURGICA|appendItem-dentro-DO-TRANSACTION-existente-escopo-reduzido

# P8-L10-NOTAS
# Item 1 (D2 ALTA): NotaFiscalPorEmbarqueMessage - ESTRUTURAL
#   - methodPost despacha para 4 operacoes de negocio completamente distintas via context:operation:
#       '' -> createByShipment (4 BOS procedures + DO TRANSACTION + calcFatura ft4001a.p)
#       'impressao' -> printInvoice (FOR EACH nota-fiscal + run esft1932i.p)
#       'autorizacao-sefaz' -> updateSefaz (loop retry 1-10 + bodi135na + bodi317ef)
#       'notificacao' -> notifyInvoice (run esft1932a RPW)
#   - Cada operacao e uma responsabilidade de negocio distinta - violacao de SRP
#   - Fix estrutural: criar NotaFiscalPorEmbarqueService com metodo execute(b-embarque, operation, payload_, outPayload)
#     methodPost passa a delegar: new NotaFiscalPorEmbarqueService():execute(...)
#   - Desafio de acoplamento: metodos privados usam temp-tables de classe (tt-res-cli, tt-nota-gerada,
#     tt-nota-fiscal) e this-object:throwRowErrorsIfAny() / this-object:addInvoiceSefazPayload()
#     Estas dependencias precisam ser parametrizadas ou replicadas no Service
#   - BACKLOG: tratar em sessao separada com analise de acoplamento dedicada
#   - Enquanto D2 nao e aplicado, B1 pode ser aplicado como patch imediato
#
# Item 2 (B1 ALTA): NotaFiscalPorEmbarqueMessage.methodPost - CIRURGICA
#   - Dois achados no fluxo de methodPost:
#   - Achado 1: new AppError('Operacao de Embarque nao implementada: &1', 0)
#     -> codigo 0 deve ser 17006; adicionar prefixo 'NotaFiscalPorEmbarqueMessage: '
#     Linha 67-73 em methodPost (clausula 'otherwise' do CASE context:operation)
#   - Achado 2: em createByShipment() (chamado de methodPost):
#     'run setPreFaturFree in h-bodi162 (input b-embarque.cdd-embarq)' esta na linha 180
#     APOS o 'end.' do 'do transaction' (linha 178) e FORA do bloco 'finally' (linhas 194-203)
#     Se throwRowErrorsIfAny('Efetua o calculo do embarque') na linha 176 lanca excecao,
#     a execucao pula direto para FINALLY - setPreFaturFree NUNCA e chamado
#     -> embarque fica em estado 'in-use' indefinidamente (setPreFaturInUse foi chamado na linha 139)
#   - Fix achado 2: mover 'run setPreFaturFree' para dentro do bloco FINALLY com no-error
#     ATENCAO: setPreFaturFree no FINALLY usa no-error para nao interromper o finally se handle invalido
#   - Verificar se finalizaBOS in h-bodi317in limpa os handles h-bodi317pr, h-bodi317sd,
#     h-bodi317im1bra, h-bodi317va (criados por inicializaBOS). Se nao, adicionar delete procedure para cada
#   - Também prefixar throwError na linha 55: 'NotaFiscalPorEmbarqueMessage: Embarque nao localizado.'
#
# Item 3 (B4 ALTA ACEITO-PARC): LpcoMessage.methodPost - escopo reduzido
#   - 'create b-nit-lpco' (linha 77) sem DO TRANSACTION explícito
#   - block-level ja proporciona rollback implicito em caso de erro - comportamento correto
#   - Fix: envolver create + 14 SetValue + appendMessageItemByReference em 'do transaction / end.'
#   - Adicionar comentario documentando contrato: CREATE + SetValue + appendItem = unidade atomica
#   - can-find permanece fora do do transaction (leitura, sem gravacao)
#   - Aproveitar edicao para prefixar AppError 'LPCO ja existe.' com 'LpcoMessage: '
#   - COMPORTAMENTO IDENTICO ao codigo atual - mudanca e de documentacao e demarcacao
#
# Item 4 (P2 MEDIA): LpcoMessage.methodPost e methodDelete - CIRURGICA
#   - Nenhum LogUtil:info em methodPost (criacao) nem methodDelete (delecao)
#   - AppError sem prefixo 'LpcoMessage: ' em ambos os metodos
#   - Fix methodPost: LogUtil:info apos appendMessageItemByReference (dentro do do transaction)
#       'LpcoMessage.methodPost: LPCO criado cod=&1 num=&2', codigoEmitente, numeroInternoLpco
#   - Fix methodDelete: LogUtil:info apos delete + prefixo AppError
#       'LpcoMessage.methodDelete: LPCO deletado cod=&1 num=&2'
#   - CRITICO B1 DETECTADO fora do escopo P2: 'delete b-nit-lpco no-error.' (linha 111 methodDelete)
#     O no-error suprime QUALQUER erro do DELETE (lock por outra sessao, integridade referencial)
#     Metodo retorna sucesso mesmo que a delecao falhe silenciosamente
#     Fix B1: remover no-error -> 'delete b-nit-lpco.' (erro propaga com block-level)
#     Esta correcao B1 pode ser aplicada junto com P2 na mesma edicao de methodDelete
#   - Adicionar: using thl-lib.logging.LogUtil. ao cabecalho
#
# Item 5 (B4 MEDIA ACEITO-PARC): EmbarqueMessage.methodPost - escopo reduzido
#   - appendMessageItemByExternalReference (linha 105) esta ANTES do 'do transaction' (linha 137)
#   - appendCreatedShipmentItem (linha 150) esta DEPOIS do 'end.' do 'do transaction' (linha 148)
#   - block-level ja proporciona atomicidade implicita em caso de erro
#   - Fix: expandir o 'do transaction' existente para incluir ambos os appendItem:
#       Mover appendMessageItemByExternalReference para PRIMEIRA linha dentro do do transaction
#       Mover appendCreatedShipmentItem para ULTIMA linha dentro do do transaction (antes do end.)
#   - setShipmentSuccessPayload permanece fora do do transaction (sem gravacao de DB)
#   - run eqp/eqapi300.p (setup do handle) permanece fora - operacao de leitura/setup
#   - find last embarque, find first estabelec, create tt-embarque (TEMP-TABLE) permanecem fora
#   - ANOMALIA detectada fora do escopo B4: methodDelete linha 174 verifica 'if not available b-embarque'
#     apos appendCreatedShipmentItem (que faz FIND como side effect) - padrao fragil
#     Documentar para sessao separada

# P8-L10-RESUMO
CIRURGICA:4|ESTRUTURAL:1
RISCO-ALTO:1|RISCO-MEDIO:2|RISCO-BAIXO:2
TOTAL:5

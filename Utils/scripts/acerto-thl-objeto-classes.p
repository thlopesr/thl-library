/*------------------------------------------------------------------------
    File        : acerto-thl-objeto-classes.p
    Purpose     : Acerto dos cadastros de objeto e de operacao para o desenho
                  Message -> Processor -> Service com o metodo na chave da
                  operacao e a extensao REST:
                  1. operacoes: cria a extensao REST
                     (thl-objeto-parametro-rest) que faltar;
                  2. objetos de ENTRADA: preenche as classes de processor e
                     de service a partir da classe de message atual, troca a
                     message retirada pela padrao e grava na extensao REST o
                     contrato que a message tinha no codigo (campos
                     obrigatorios por metodo e chave externa).
    Created     : 2026-10-04
    Notes       : - ADRs Documentos/.claude/adr/inbound-message-processor-service.md
                    e operacao-acao-extensao-rest.md.
                  - Rodar depois de carregar os deltas (ate o
                    delta-thl-2026-10-08.df, que tira o campo acao e deixa o
                    metodo na chave), de compilar e de rodar as cargas,
                    e ANTES de liberar a API: objeto de entrada sem classe de
                    service e recusado pelo InboundConfigLoader, e objeto que
                    aponta para message retirada nao instancia.
                  - A regra do objeto vem do nome curto da classe de message
                    atual (a parte depois do ultimo ponto): vale para qualquer
                    aplicacao e para nomes de pacote antigos.
                  - O metodo faz parte da chave da operacao (REST: 1 POST,
                    2 PUT, 3 PATCH, 4 DELETE, 5 GET). Base com o campo acao:
                    rodar pre-delta-metodo-chave.p antes do delta.
                  - Contrato: so grava campo da extensao que esta em branco;
                    o que ja foi cadastrado na tela nao e alterado.
                  - Nota fiscal: um objeto so (rota notafiscal), com o
                    NotaFiscalProcessor e o NotaFiscalService; a URL
                    notafiscal/embarque/<etapa> chega como operacao
                    embarque/<etapa>; o Service vem da linha cadastrada no thl0022 e o Processor so pega a etapa (ultima parte).
                    Base que ja tem um objeto proprio para o embarque (rota
                    notafiscal/embarque ou objeto notafiscalembarque) e
                    respeitada: Processor padrao + NotaFiscalPorEmbarqueService.
                  - Exige a tabela thl-objeto-rota (Database/Definition/thl.df).
                  - Pacote dos Processors: o nome gravado nos cadastros com o
                    pacote antigo (erp.process, ou a classe-base em
                    inbound.process) e trocado pelo atual. Exige o
                    delta-thl-2026-10-07.df para os objetos novos nascerem
                    com o nome certo.
                  - Objeto de saida: so as operacoes (extensao).
                  - Objeto cuja classe nao esta na lista fica no log como
                    "sem regra": preencher pelo thl0021.
                  - Objeto proprio de filho (carga antiga da API de cadastros)
                    fica no log como "sem uso": o filho virou operacao do pai.
                  - Service de filho de agregado (item/Saldo, objeto/usuario...):
                    fica na linha da operacao. Rodar em seguida o
                    acerto-thl-operacao-service.p, que cria essas linhas.
                  - As classes valem na linha da operacao (a execucao nao le mais
                    thl-objeto): ao trocar a classe do objeto, as linhas que ainda
                    tem a antiga acompanham. Rodar por ultimo
                    acerto-thl-operacao-classes.p (verbos -> branco e classes em branco).
                  - Idempotente. Roda em SIMULACAO por padrao (simulate = yes).
                  - Log: <session:temp-directory>acerto-thl-objeto-classes.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate         as logical   no-undo initial yes.
define variable defaultMessage   as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.InboundMessage".
define variable defaultProcessor as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.Processor".
define variable thlProcess       as character no-undo initial "thl-extensions.integration.thl.messaging.inbound.process.".
define variable thlService       as character no-undo initial "thl-extensions.erp.thl.service.".
define variable libService       as character no-undo initial "thl-lib.erp.service.".
define variable libProcess       as character no-undo initial "thl-lib.integration.messaging.inbound.process.".
define variable logFile          as character no-undo.
define variable shortName        as character no-undo.
define variable newMessage       as character no-undo.
define variable newProcessor     as character no-undo.
define variable newService       as character no-undo.
define variable oldMessage       as character no-undo.
define variable oldProcessor     as character no-undo.
define variable oldService       as character no-undo.
define buffer b-linha for thl-objeto-parametro.
define variable objectKey        as character no-undo.
define variable totalRead        as integer   no-undo.
define variable totalChanged     as integer   no-undo.
define variable totalOk          as integer   no-undo.
define variable totalNoRule      as integer   no-undo.
define variable totalObsolete    as integer   no-undo.
define variable totalExtension   as integer   no-undo.
define variable totalContract    as integer   no-undo.
define variable totalRenamed     as integer   no-undo.
define variable shipmentRoute    as character no-undo initial "notafiscal/embarque".
define variable shipmentService  as character no-undo
    initial "thl-lib.erp.service.NotaFiscalPorEmbarqueService".

// nome curto da message atual | message nova (branco = mantem) | processor (branco = padrao) | service
// service "SEM-USO" = objeto proprio de filho, que virou operacao do pai
// contrato: campos obrigatorios por metodo e chave externa, em array JSON de texto
define temp-table tt-regra no-undo
    field classe-atual   as character
    field message        as character
    field processor      as character
    field service        as character
    field obrig-criar    as character
    field obrig-alterar  as character
    field obrig-eliminar as character
    field chave-externa  as character
    index pk-regra is primary unique classe-atual.

define buffer b-thl-objeto           for thl-objeto.
define buffer b-thl-objeto-parametro for thl-objeto-parametro.

define stream logStream.

/* ***************************  Main Block  *************************** */

// ---- sistema thl: messages retiradas (a padrao assume)
run addRule( "AmbienteMessage"       , defaultMessage, ""                                      , thlService + "AmbienteService" ).
run addRule( "AplicacaoMessage"      , defaultMessage, ""                                      , thlService + "AplicacaoService" ).
run addRule( "ConexaoRestPathMessage", defaultMessage, ""                                      , thlService + "ConexaoRestPathService" ).
run addRule( "InboundRotaMessage"    , defaultMessage, ""                                      , "SEM-USO" ).
run addRule( "EmailParametroMessage" , defaultMessage, ""                                      , thlService + "EmailParametroService" ).
run addRule( "AuditoriaMessage"      , defaultMessage, libProcess + "MetricsProcessor"         , thlService + "AuditoriaService" ).
run addRule( "EmailMessage"          , defaultMessage, libProcess + "MetricsProcessor"         , thlService + "EmailService" ).
run addRule( "MensageriaMessage"     , defaultMessage, libProcess + "MetricsProcessor"         , thlService + "MensageriaService" ).
run addRule( "AuditoriaTabelaMessage", defaultMessage, ""                                      , thlService + "AuditoriaTabelaService" ).
run addRule( "ObjetoMessage"         , defaultMessage, ""                                      , thlService + "ObjetoService" ).
run addRule( "GrupoEmailMessage"     , defaultMessage, ""                                      , thlService + "GrupoEmailService" ).

// ---- sistema thl: messages que ficaram (mascara de segredo)
run addRule( "ParametroAmbienteMessage", "", ""                               , thlService + "ParametroAmbienteService" ).
run addRule( "ConexaoRestMessage"      , "", ""                               , thlService + "ConexaoRestService" ).

// ---- sistema thl: objetos proprios de filhos (primeira carga da API de cadastros)
run addRule( "ParametroVariavelMessage"         , "", "", "SEM-USO" ).
run addRule( "ParametroProgramaMessage"         , "", "", "SEM-USO" ).
run addRule( "ObjetoParametroMessage"           , "", "", "SEM-USO" ).
run addRule( "ObjetoUsuarioMessage"             , "", "", "SEM-USO" ).
run addRule( "ConexaoRestAutenticacaoMessage"   , "", "", "SEM-USO" ).
run addRule( "ConexaoRestHeaderMessage"         , "", "", "SEM-USO" ).
run addRule( "AuditoriaTabelaAcessoMessage"     , "", "", "SEM-USO" ).
run addRule( "AuditoriaTabelaCampoMessage"      , "", "", "SEM-USO" ).
run addRule( "AuditoriaTabelaNotificacaoMessage", "", "", "SEM-USO" ).
run addRule( "AuditoriaTabelaExpurgoMessage"    , "", "", "SEM-USO" ).
run addRule( "GrupoEmailUsuarioMessage"         , "", "", "SEM-USO" ).

// ---- thl-lib: messages retiradas (a padrao assume)
run addRule( "CentroCustoMessage", defaultMessage, ""                                , libService + "CentroCustoService" ).
run addRule( "DocumentoMessage"  , defaultMessage, ""                                , libService + "DocumentoService" ).
run addRule( "EmbarqueMessage"   , defaultMessage, ""                                , libService + "EmbarqueService" ).
run addRule( "EmitenteMessage"   , defaultMessage, ""                               , libService + "EmitenteService" ).
run addRule( "ItemMessage"       , defaultMessage, ""                               , libService + "ItemService" ).
run addRule( "RequisicaoMessage" , defaultMessage, ""                               , libService + "RequisicaoService" ).
run addRule( "TransporteMessage" , defaultMessage, ""                                , libService + "TransporteService" ).
run addRule( "UsuarioMessage"    , defaultMessage, ""                                , libService + "UsuarioService" ).

// ---- thl-lib: nota fiscal - um objeto, NotaFiscalProcessor separa o embarque pela
//      operacao; objeto proprio do embarque ja cadastrado e respeitado (resolveInvoiceObject)
run addRule( "NotaFiscalMessage" , defaultMessage, libProcess + "NotaFiscalProcessor", libService + "NotaFiscalService" ).

// ---- demais extensoes: messages retiradas (a padrao assume)
run addRule( "LpcoMessage"             , defaultMessage, "", "thl-extensions.erp.automatizador.service.LpcoService" ).
run addRule( "FreteMessage"            , defaultMessage, "", "thl-extensions.erp.dvv.service.FretePrevistoService" ).
run addRule( "LoogAiDocumentoMessage"  , defaultMessage, "", "thl-extensions.erp.loogai.service.LoogAiDocumentoService" ).
run addRule( "LoogAiEmbarqueMessage"   , defaultMessage, "", "thl-extensions.erp.loogai.service.LoogAiEmbarqueService" ).
run addRule( "NinahubNotaFiscalMessage", defaultMessage, libProcess + "NotaFiscalProcessor", "thl-extensions.erp.ninahub.service.NinahubNotaFiscalService" ).

// ---- contrato que as messages retiradas tinham no codigo:
//      classe | obrigatorios ao criar | ao alterar | ao eliminar | chave externa ("" = padrao externalID; "[]" = desligada)
run addContract( "EmbarqueMessage",
                 '["codigoEstabelecimento","codigoUsuario","dataEmbarque","sequencia","entregas"]',
                 '["codigoEmbarque"]',
                 '["codigoEmbarque"]',
                 "" ).
run addContract( "UsuarioMessage",
                 '["codigoUsuario"]', '["codigoUsuario"]', '["codigoUsuario"]', "" ).
run addContract( "RequisicaoMessage",
                 "", "", '["nr-requisicao"]', "[]" ).
run addContract( "LpcoMessage",
                 '["codigoEmitente"]',
                 '["codigoEmitente","numeroInternoLpco"]',
                 '["codigoEmitente","numeroInternoLpco"]',
                 '["numeroLpco"]' ).
run addContract( "FreteMessage",
                 '["Estabelecimento","Serie","NrNota","TipoFrete","ValorFrete"]',
                 '["Estabelecimento","Serie","NrNota","TipoFrete","ValorFrete"]',
                 '["Estabelecimento","Serie","NrNota","TipoFrete"]',
                 "" ).
run addContract( "LoogAiDocumentoMessage",
                 '["tipoDocumento","cnpjEstabelecimento","cnpjTransportadora","documentoCliente","aliquotaCofins","aliquotaPis","aliquotaIcms","chaveAcesso","valorTotal","dataEmissao","serie","numeroDocumento"]',
                 '["tipoDocumento","cnpjEstabelecimento","cnpjTransportadora","documentoCliente","aliquotaCofins","aliquotaPis","aliquotaIcms","chaveAcesso","valorTotal","dataEmissao","serie","numeroDocumento"]',
                 '["tipoDocumento","cnpjEstabelecimento","cnpjTransportadora","documentoCliente","aliquotaCofins","aliquotaPis","aliquotaIcms","chaveAcesso","valorTotal","dataEmissao","serie","numeroDocumento"]',
                 "" ).
run addContract( "LoogAiEmbarqueMessage",
                 '["codigoEstabelecimento","viagem","entregas"]',
                 '["codigoEmbarque"]',
                 '["codigoEmbarque","viagem"]',
                 '["viagem"]' ).
run addContract( "NotaFiscalMessage",
                 "", "", "", '["codigoEstabelecimento","serie","numeroNotaFiscal"]' ).
run addContract( "NinahubNotaFiscalMessage",
                 "", "", "", '["codigoEstabelecimento","serie","numeroNotaFiscal"]' ).

logFile = session:temp-directory + "acerto-thl-objeto-classes.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Acerto de objetos e operacoes em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip.

// ------------------------------------------------------------ 0. pacote dos Processors

put stream logStream unformatted skip(1)
    "PACOTE DOS PROCESSORS" skip
    "cadastro;chave;nome antigo;nome novo" skip.

for each thl-objeto no-lock
    where thl-objeto.classe-processor <> "":
    run fixProcessorObject( rowid( thl-objeto ) ).
end.

for each thl-objeto-parametro no-lock
    where thl-objeto-parametro.classe-processor <> "":
    run fixProcessorOperation( rowid( thl-objeto-parametro ) ).
end.

// ------------------------------------------------------------ 1. operacoes

for each thl-objeto-parametro no-lock,
    first thl-objeto no-lock
    where thl-objeto.aplicacao         = thl-objeto-parametro.aplicacao
      and thl-objeto.objeto            = thl-objeto-parametro.objeto
      and thl-objeto.modelo-integracao = 1:      // REST
    run ensureExtension( rowid( thl-objeto-parametro ) ).
end.

// ------------------------------------------------------------ 2. objetos de entrada

put stream logStream unformatted skip(1)
    "OBJETOS DE ENTRADA" skip
    "aplicacao/objeto;classe message atual;acao;message;processor;service" skip.

// so objetos de entrada (sentido-fluxo = no)
for each thl-objeto no-lock
    where not thl-objeto.sentido-fluxo:

    assign totalRead = totalRead + 1
           objectKey = thl-objeto.aplicacao + "/" + thl-objeto.objeto
           shortName = if thl-objeto.classe-objeto = "" then ""
                       else entry( num-entries( thl-objeto.classe-objeto, "." ), thl-objeto.classe-objeto, "." ).

    find tt-regra where tt-regra.classe-atual = shortName no-error.

    if not available tt-regra then do:

        // ja no modelo novo (message padrao e service informado): nada a fazer
        if thl-objeto.classe-service <> "" and thl-objeto.classe-processor <> "" and thl-objeto.classe-objeto <> "" then do:
            assign totalOk = totalOk + 1.
            run writeLog( objectKey, thl-objeto.classe-objeto, "ja preenchido", "", "", "" ).
        end.
        else do:
            assign totalNoRule = totalNoRule + 1.
            run writeLog( objectKey, thl-objeto.classe-objeto, "sem regra - preencher as classes pelo thl0021", "", "", "" ).
        end.

        next.

    end.

    if tt-regra.service = "SEM-USO" then do:
        assign totalObsolete = totalObsolete + 1.
        run writeLog( objectKey, thl-objeto.classe-objeto, "sem uso - o filho virou operacao do pai; eliminar o objeto", "", "", "" ).
        next.
    end.

    // antes de trocar a classe: o contrato que ela tinha no codigo vai para o cadastro
    run applyContract( thl-objeto.aplicacao, thl-objeto.objeto, thl-objeto.modelo-integracao ).

    assign newMessage   = if tt-regra.message   = "" then thl-objeto.classe-objeto else tt-regra.message
           newProcessor = if tt-regra.processor = "" then defaultProcessor         else tt-regra.processor
           newService   = tt-regra.service.

    // nota fiscal: inicio da operacao na rota do embarque ou, se o objeto e so do embarque, o Service dele
    if shortName = "NotaFiscalMessage" then
        run resolveInvoiceObject( thl-objeto.aplicacao, thl-objeto.objeto, input-output newProcessor, input-output newService ).

    if thl-objeto.classe-objeto    = newMessage   and
       thl-objeto.classe-processor = newProcessor and
       thl-objeto.classe-service   = newService   then do:
        assign totalOk = totalOk + 1.
        run writeLog( objectKey, thl-objeto.classe-objeto, "ja preenchido", newMessage, newProcessor, newService ).
        next.
    end.

    if not simulate then do transaction:

        find b-thl-objeto exclusive-lock
            where rowid( b-thl-objeto ) = rowid( thl-objeto )
            no-error.

        assign oldMessage   = b-thl-objeto.classe-objeto
               oldProcessor = b-thl-objeto.classe-processor
               oldService   = b-thl-objeto.classe-service.

        assign b-thl-objeto.classe-objeto    = newMessage
               b-thl-objeto.classe-processor = newProcessor
               b-thl-objeto.classe-service   = newService.

        // as linhas de operacao que ainda tem a classe antiga (ou em branco) acompanham o objeto
        for each b-linha exclusive-lock
            where b-linha.aplicacao = b-thl-objeto.aplicacao
              and b-linha.objeto    = b-thl-objeto.objeto:
            if b-linha.classe-objeto = oldMessage or b-linha.classe-objeto = "" then
                assign b-linha.classe-objeto = newMessage.
            if b-linha.classe-processor = oldProcessor or b-linha.classe-processor = "" then
                assign b-linha.classe-processor = newProcessor.
            if b-linha.classe-service = oldService or b-linha.classe-service = "" then
                assign b-linha.classe-service = newService.
        end.

        release b-thl-objeto.

    end.

    assign totalChanged = totalChanged + 1.
    run writeLog( objectKey, thl-objeto.classe-objeto, if simulate then "seria alterado" else "alterado", newMessage, newProcessor, newService ).

end.

put stream logStream unformatted skip(1)
    ( if simulate then "Nomes de Processor que seriam trocados: " else "Nomes de Processor trocados: " ) totalRenamed skip
    ( if simulate then "Extensoes REST que seriam criadas: " else "Extensoes REST criadas: " ) totalExtension skip
    ( if simulate then "Contratos que seriam gravados: " else "Contratos gravados: " ) totalContract skip
    "Objetos de entrada lidos: " totalRead skip
    ( if simulate then "Seriam alterados: " else "Alterados: " ) totalChanged skip
    "Ja preenchidos: " totalOk skip
    "Sem regra (preencher pelo thl0021): " totalNoRule skip
    "Sem uso (objeto proprio de filho): " totalObsolete skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Nomes de Processor que seriam trocados: " else "Nomes de Processor trocados: " ) totalRenamed chr(10)
        ( if simulate then "Extensoes REST que seriam criadas: " else "Extensoes REST criadas: " ) totalExtension chr(10)
        ( if simulate then "Contratos que seriam gravados: " else "Contratos gravados: " ) totalContract chr(10)
        "Objetos de entrada lidos: " totalRead chr(10)
        ( if simulate then "Seriam alterados: " else "Alterados: " ) totalChanged chr(10)
        "Ja preenchidos: " totalOk chr(10)
        "Sem regra (preencher pelo thl0021): " totalNoRule chr(10)
        "Sem uso (objeto proprio de filho): " totalObsolete chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure addRule private:
    define input parameter currentClass  as character no-undo.
    define input parameter messageName   as character no-undo.
    define input parameter processorName as character no-undo.
    define input parameter serviceName   as character no-undo.

    create tt-regra.
    assign tt-regra.classe-atual = currentClass
           tt-regra.message      = messageName
           tt-regra.processor    = processorName
           tt-regra.service      = serviceName.
end procedure.

procedure addContract private:
    define input parameter currentClass   as character no-undo.
    define input parameter requiredCreate as character no-undo.
    define input parameter requiredUpdate as character no-undo.
    define input parameter requiredDelete as character no-undo.
    define input parameter externalKey    as character no-undo.

    find tt-regra where tt-regra.classe-atual = currentClass.

    assign tt-regra.obrig-criar    = requiredCreate
           tt-regra.obrig-alterar  = requiredUpdate
           tt-regra.obrig-eliminar = requiredDelete
           tt-regra.chave-externa  = externalKey.
end procedure.

// Nome atual de um Processor gravado com o pacote antigo; devolve o proprio nome se ja esta certo.
// - classe-base: thl-lib.erp.process.Processor ou ...inbound.process.Processor -> a padrao atual;
// - thl-lib.erp.process.<Classe>                   -> thl-lib.integration.messaging.inbound.process.<Classe>;
// - thl-extensions.erp.<sistema>.process.<Classe>  -> thl-extensions.integration.<sistema>.messaging.inbound.process.<Classe>.
function currentProcessorName returns character private ( input oldName as character ):

    if oldName = "thl-lib.erp.process.Processor" or
       oldName = "thl-lib.integration.messaging.inbound.process." + "Processor" then
        return defaultProcessor.

    if oldName begins "thl-lib.erp.process." then
        return "thl-lib.integration.messaging.inbound.process." + substring( oldName, 21 ).

    if oldName begins "thl-extensions.erp."     and
       num-entries( oldName, "." ) = 5          and
       entry( 4, oldName, "." ) = "process"     then
        return substitute( "thl-extensions.integration.&1.messaging.inbound.process.&2",
                           entry( 3, oldName, "." ), entry( 5, oldName, "." ) ).

    return oldName.

end function.

procedure fixProcessorObject private:
    define input parameter objectRowid as rowid no-undo.

    define variable newName as character no-undo.

    find b-thl-objeto no-lock
        where rowid( b-thl-objeto ) = objectRowid no-error.
    if not available b-thl-objeto then
        return.

    assign newName = currentProcessorName( b-thl-objeto.classe-processor ).

    if newName = b-thl-objeto.classe-processor then
        return.

    put stream logStream unformatted
        "thl-objeto;" b-thl-objeto.aplicacao "/" b-thl-objeto.objeto ";" b-thl-objeto.classe-processor ";" newName skip.

    if not simulate then do transaction:
        find current b-thl-objeto exclusive-lock.
        assign b-thl-objeto.classe-processor = newName.
        release b-thl-objeto.
    end.

    assign totalRenamed = totalRenamed + 1.
end procedure.

procedure fixProcessorOperation private:
    define input parameter operationRowid as rowid no-undo.

    define variable newName as character no-undo.

    find b-thl-objeto-parametro no-lock
        where rowid( b-thl-objeto-parametro ) = operationRowid no-error.
    if not available b-thl-objeto-parametro then
        return.

    assign newName = currentProcessorName( b-thl-objeto-parametro.classe-processor ).

    if newName = b-thl-objeto-parametro.classe-processor then
        return.

    put stream logStream unformatted
        "thl-objeto-parametro;" b-thl-objeto-parametro.cod-estabel "/" b-thl-objeto-parametro.aplicacao "/"
        b-thl-objeto-parametro.objeto "/" b-thl-objeto-parametro.operacao ";"
        b-thl-objeto-parametro.classe-processor ";" newName skip.

    if not simulate then do transaction:
        find current b-thl-objeto-parametro exclusive-lock.
        assign b-thl-objeto-parametro.classe-processor = newName.
        release b-thl-objeto-parametro.
    end.

    assign totalRenamed = totalRenamed + 1.
end procedure.

// Extensao REST da operacao: cria a que faltar, com o verbo da operacao
procedure ensureExtension private:
    define input parameter operationRowid as rowid no-undo.

    find b-thl-objeto-parametro no-lock
        where rowid( b-thl-objeto-parametro ) = operationRowid no-error.
    if not available b-thl-objeto-parametro then
        return.

    // sem o metodo a operacao nao tem chave completa: informar pelo thl0022
    if b-thl-objeto-parametro.metodo < 1 then
        return.

    if can-find( thl-objeto-parametro-rest
                 where thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                   and thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                   and thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                   and thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                   and thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo ) then
        return.

    if not simulate then do transaction:
        create thl-objeto-parametro-rest.
        assign thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
               thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
               thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
               thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
               thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo.
        release thl-objeto-parametro-rest.
    end.

    assign totalExtension = totalExtension + 1.
end procedure.

// Contrato da message (tt-regra posicionada) para a extensao REST de cada operacao do objeto
procedure applyContract private:
    define input parameter applicationName  as character no-undo.
    define input parameter objectName       as character no-undo.
    define input parameter integrationModel as integer   no-undo.

    define variable requiredFields as character no-undo.
    define variable operationKey   as character no-undo.
    define variable hasChange      as logical   no-undo.

    if tt-regra.obrig-criar    = "" and
       tt-regra.obrig-alterar  = "" and
       tt-regra.obrig-eliminar = "" and
       tt-regra.chave-externa  = "" then
        return.

    if integrationModel <> 1 then do:
        put stream logStream unformatted applicationName "/" objectName ";;contrato nao gravado - objeto nao e REST, sem extensao" skip.
        return.
    end.

    for each b-thl-objeto-parametro no-lock
        where b-thl-objeto-parametro.aplicacao = applicationName
          and b-thl-objeto-parametro.objeto    = objectName:

        case b-thl-objeto-parametro.metodo:
            when 1 then assign requiredFields = tt-regra.obrig-criar.      // POST
            when 2 or
            when 3 then assign requiredFields = tt-regra.obrig-alterar.    // PUT, PATCH
            when 4 then assign requiredFields = tt-regra.obrig-eliminar.   // DELETE
            otherwise   assign requiredFields = "".
        end case.

        assign operationKey = substitute( "&1/&2/&3/&4", b-thl-objeto-parametro.cod-estabel, applicationName,
                                                         objectName, b-thl-objeto-parametro.operacao )
               hasChange    = false.

        if simulate then do:
            // na simulacao a extensao pode ainda nao existir: mostra o que seria gravado
            put stream logStream unformatted operationKey ";;contrato que seria gravado (se em branco);" requiredFields ";" tt-regra.chave-externa skip.
            assign totalContract = totalContract + 1.
            next.
        end.

        do transaction:

            find thl-objeto-parametro-rest exclusive-lock
                where thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                  and thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                  and thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                  and thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                  and thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo
                no-error.

            if not available thl-objeto-parametro-rest then do:
                put stream logStream unformatted operationKey ";;contrato nao gravado - operacao sem extensao REST (sem metodo?)" skip.
                next.
            end.

            // so preenche o que esta em branco: o que foi cadastrado na tela fica
            if thl-objeto-parametro-rest.campos-obrigatorios = "" and requiredFields <> "" then
                assign thl-objeto-parametro-rest.campos-obrigatorios = requiredFields
                       hasChange                                     = true.

            if thl-objeto-parametro-rest.chave-externa = "" and tt-regra.chave-externa <> "" then
                assign thl-objeto-parametro-rest.chave-externa = tt-regra.chave-externa
                       hasChange                               = true.

            release thl-objeto-parametro-rest.

        end.

        if hasChange then do:
            assign totalContract = totalContract + 1.
            put stream logStream unformatted operationKey ";;contrato gravado;" requiredFields ";" tt-regra.chave-externa skip.
        end.

    end.
end procedure.

// Nota fiscal: o objeto atendido pela rota do embarque usa o Service por embarque.
// Sem rota cadastrada o roteador usa a propria rota, sem a barra, como objeto.
procedure resolveInvoiceObject private:
    define input        parameter applicationName as character no-undo.
    define input        parameter objectName      as character no-undo.
    define input-output parameter processorName   as character no-undo.
    define input-output parameter serviceName     as character no-undo.

    if can-find( first thl-objeto-rota
                 where thl-objeto-rota.aplicacao    = applicationName
                   and thl-objeto-rota.objeto       = objectName
                   and thl-objeto-rota.rota-publica = shipmentRoute ) or
       objectName = replace( shipmentRoute, "/", "" ) then
        assign processorName = defaultProcessor
               serviceName   = shipmentService.
end procedure.

procedure writeLog private:
    define input parameter keyValue      as character no-undo.
    define input parameter currentClass  as character no-undo.
    define input parameter action        as character no-undo.
    define input parameter messageName   as character no-undo.
    define input parameter processorName as character no-undo.
    define input parameter serviceName   as character no-undo.

    put stream logStream unformatted
        keyValue ";" currentClass ";" action ";" messageName ";" processorName ";" serviceName skip.
end procedure.

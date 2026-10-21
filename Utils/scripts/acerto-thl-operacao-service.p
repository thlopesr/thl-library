/*------------------------------------------------------------------------
    File        : acerto-thl-operacao-service.p
    Purpose     : Leva para o cadastro a escolha do Service do filho de agregado,
                  que estava fixa nos Processors retirados em 2026-10-08:
                  1. cria a linha da operacao do filho (thl-objeto-parametro,
                     com thl-objeto-parametro.classe-service) e a extensao REST,
                     a partir da linha generica do pai (operacao em branco ou
                     com o nome do verbo);
                  2. troca o Processor retirado pelo padrao (ou pelo
                     MetricsProcessor, no objeto que usava o MensageriaProcessor).
    Created     : 2026-10-08
    Notes       : - ADR Documentos/.claude/adr/inbound-message-processor-service.md.
                  - Rodar depois do acerto-thl-objeto-classes.p e ANTES de
                    usar os fontes novos: sem a linha da operacao, a URL do
                    filho (item/Saldo, objeto/usuario...) cai na linha generica
                    e usa o Service do PAI, sem erro.
                  - O objeto e reconhecido pelo Service do cadastro
                    (thl-objeto.classe-service), em qualquer aplicacao.
                  - A linha do filho copia a do pai (parametros, log, forma de
                    execucao, contrato da extensao); ajustar depois pelo
                    thl0022 se o filho precisar de valor proprio.
                  - Verbos: "*" = todos os que o pai tem; senao a lista de
                    MethodTypeEnum (1 POST, 2 PUT, 3 PATCH, 4 DELETE, 5 GET).
                  - Idempotente. Roda em SIMULACAO por padrao (simulate = yes).
                  - Log: <session:temp-directory>acerto-thl-operacao-service.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate         as logical   no-undo initial yes.
define variable defaultProcessor as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.Processor".
define variable metricsProcessor as character no-undo
    initial "thl-lib.integration.messaging.inbound.process.MetricsProcessor".
define variable retiredNames     as character no-undo
    initial "ItemProcessor,EmitenteProcessor,RequisicaoProcessor,ParametroProcessor,ObjetoProcessor,ConexaoRestProcessor,AuditoriaTabelaProcessor,GrupoEmailProcessor,FreteProcessor".
define variable thlService       as character no-undo initial "thl-extensions.erp.thl.service.".
define variable libService       as character no-undo initial "thl-lib.erp.service.".
define variable verbNames        as character no-undo initial "POST,PUT,PATCH,DELETE,GET".
define variable logFile          as character no-undo.
define variable totalOperation   as integer   no-undo.
define variable totalExisting    as integer   no-undo.
define variable totalNoParent    as integer   no-undo.
define variable totalProcessor   as integer   no-undo.

// Service do pai | operacao do filho na URL | Service do filho | verbos ("*" = os do pai)
define temp-table tt-filho no-undo
    field service-pai   as character
    field operacao      as character
    field service-filho as character
    field metodos       as character
    index pk-filho is primary unique service-pai operacao.

define buffer b-thl-objeto                for thl-objeto.
define buffer b-thl-objeto-parametro      for thl-objeto-parametro.
define buffer b-thl-objeto-parametro-rest for thl-objeto-parametro-rest.

define stream logStream.

/* ***************************  Main Block  *************************** */

// ---- thl-lib
run addChild( libService + "ItemService"      , "Saldo"       , libService + "SaldoService"         , "5" ).
run addChild( libService + "EmitenteService"  , "localentrega", libService + "LocalEntregaService"  , "5" ).
run addChild( libService + "RequisicaoService", "item"        , libService + "ItemRequisicaoService", "4" ).

// ---- sistema thl
run addChild( thlService + "MensageriaService"       , "conteudo"    , thlService + "MensageriaConteudoService"        , "5" ).
run addChild( thlService + "ParametroAmbienteService", "variavel"    , thlService + "ParametroVariavelService"         , "*" ).
run addChild( thlService + "ParametroAmbienteService", "programa"    , thlService + "ParametroProgramaService"         , "*" ).
run addChild( thlService + "ObjetoService"           , "parametro"   , thlService + "ObjetoParametroService"           , "*" ).
run addChild( thlService + "ObjetoService"           , "usuario"     , thlService + "ObjetoUsuarioService"             , "*" ).
run addChild( thlService + "ObjetoService"           , "rota"        , thlService + "ObjetoRotaService"                , "*" ).
run addChild( thlService + "ConexaoRestService"      , "autenticacao", thlService + "ConexaoRestAutenticacaoService"   , "*" ).
run addChild( thlService + "ConexaoRestService"      , "header"      , thlService + "ConexaoRestHeaderService"         , "*" ).
run addChild( thlService + "AuditoriaTabelaService"  , "acesso"      , thlService + "AuditoriaTabelaAcessoService"     , "*" ).
run addChild( thlService + "AuditoriaTabelaService"  , "campo"       , thlService + "AuditoriaTabelaCampoService"      , "*" ).
run addChild( thlService + "AuditoriaTabelaService"  , "notificacao" , thlService + "AuditoriaTabelaNotificacaoService", "*" ).
run addChild( thlService + "AuditoriaTabelaService"  , "expurgo"     , thlService + "AuditoriaTabelaExpurgoService"    , "*" ).
run addChild( thlService + "GrupoEmailService"       , "usuario"     , thlService + "GrupoEmailUsuarioService"         , "*" ).

logFile = session:temp-directory + "acerto-thl-operacao-service.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Service do filho na operacao em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip(1)
    "OPERACOES DOS FILHOS" skip
    "estabelecimento/aplicacao/objeto/operacao;metodo;service;situacao" skip.

// ------------------------------------------------------------ 1. linhas das operacoes

for each thl-objeto no-lock
    where not thl-objeto.sentido-fluxo,
    each tt-filho
    where tt-filho.service-pai = thl-objeto.classe-service:
    run createChildOperations( rowid( thl-objeto ) ).
end.

// ------------------------------------------------------------ 2. Processors retirados

put stream logStream unformatted skip(1)
    "PROCESSORS" skip
    "cadastro;chave;processor atual;processor novo" skip.

for each thl-objeto no-lock
    where thl-objeto.classe-processor <> "":
    run fixObjectProcessor( rowid( thl-objeto ) ).
end.

for each thl-objeto-parametro no-lock
    where thl-objeto-parametro.classe-processor <> "":
    run fixOperationProcessor( rowid( thl-objeto-parametro ) ).
end.

put stream logStream unformatted skip(1)
    ( if simulate then "Operacoes que seriam criadas: " else "Operacoes criadas: " ) totalOperation skip
    "Operacoes ja cadastradas: " totalExisting skip
    "Filhos sem linha do pai para copiar: " totalNoParent skip
    ( if simulate then "Processors que seriam trocados: " else "Processors trocados: " ) totalProcessor skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Operacoes que seriam criadas: " else "Operacoes criadas: " ) totalOperation chr(10)
        "Operacoes ja cadastradas: " totalExisting chr(10)
        "Filhos sem linha do pai para copiar: " totalNoParent chr(10)
        ( if simulate then "Processors que seriam trocados: " else "Processors trocados: " ) totalProcessor chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure addChild private:
    define input parameter parentService as character no-undo.
    define input parameter operationName as character no-undo.
    define input parameter childService  as character no-undo.
    define input parameter methodList    as character no-undo.

    create tt-filho.
    assign tt-filho.service-pai   = parentService
           tt-filho.operacao      = operationName
           tt-filho.service-filho = childService
           tt-filho.metodos       = methodList.
end procedure.

// Uma linha do filho para cada linha generica do pai (por estabelecimento e metodo)
procedure createChildOperations private:
    define input parameter objectRowid as rowid no-undo.

    define variable operationKey as character no-undo.
    define variable copied       as logical   no-undo.

    find b-thl-objeto no-lock
        where rowid( b-thl-objeto ) = objectRowid no-error.
    if not available b-thl-objeto then
        return.

    for each b-thl-objeto-parametro no-lock
        where b-thl-objeto-parametro.aplicacao = b-thl-objeto.aplicacao
          and b-thl-objeto-parametro.objeto    = b-thl-objeto.objeto
          and b-thl-objeto-parametro.metodo   >= 1
          and b-thl-objeto-parametro.metodo   <= 5:

        // linha generica: operacao em branco ou com o nome do proprio verbo
        if b-thl-objeto-parametro.operacao <> "" and
           b-thl-objeto-parametro.operacao <> entry( b-thl-objeto-parametro.metodo, verbNames ) then
            next.

        if tt-filho.metodos <> "*" and
           lookup( string( b-thl-objeto-parametro.metodo ), tt-filho.metodos ) = 0 then
            next.

        assign copied       = true
               operationKey = substitute( "&1/&2/&3/&4", b-thl-objeto-parametro.cod-estabel, b-thl-objeto.aplicacao,
                                                         b-thl-objeto.objeto, tt-filho.operacao ).

        if can-find( thl-objeto-parametro
                     where thl-objeto-parametro.cod-estabel = b-thl-objeto-parametro.cod-estabel
                       and thl-objeto-parametro.aplicacao   = b-thl-objeto-parametro.aplicacao
                       and thl-objeto-parametro.objeto      = b-thl-objeto-parametro.objeto
                       and thl-objeto-parametro.operacao    = tt-filho.operacao
                       and thl-objeto-parametro.metodo      = b-thl-objeto-parametro.metodo ) then do:
            assign totalExisting = totalExisting + 1.
            put stream logStream unformatted operationKey ";" b-thl-objeto-parametro.metodo ";" tt-filho.service-filho ";ja cadastrada (conferir o Service no thl0022)" skip.
            next.
        end.

        if not simulate then do transaction:

            create thl-objeto-parametro.
            buffer-copy b-thl-objeto-parametro
                except operacao classe-service
                to thl-objeto-parametro
                assign thl-objeto-parametro.operacao       = tt-filho.operacao
                       thl-objeto-parametro.classe-service = tt-filho.service-filho.

            // extensao REST: copia o contrato da linha do pai
            find first b-thl-objeto-parametro-rest no-lock
                where b-thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                  and b-thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                  and b-thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                  and b-thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                  and b-thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo
                no-error.

            if available b-thl-objeto-parametro-rest then do:
                create thl-objeto-parametro-rest.
                buffer-copy b-thl-objeto-parametro-rest
                    except operacao
                    to thl-objeto-parametro-rest
                    assign thl-objeto-parametro-rest.operacao = tt-filho.operacao.
                release thl-objeto-parametro-rest.
            end.

            release thl-objeto-parametro.

        end.

        assign totalOperation = totalOperation + 1.
        put stream logStream unformatted operationKey ";" b-thl-objeto-parametro.metodo ";" tt-filho.service-filho ";"
            ( if simulate then "seria criada" else "criada" ) skip.

    end.

    if not copied then do:
        assign totalNoParent = totalNoParent + 1.
        put stream logStream unformatted
            b-thl-objeto.aplicacao "/" b-thl-objeto.objeto "/" tt-filho.operacao ";;" tt-filho.service-filho
            ";SEM LINHA DO PAI para o metodo - cadastrar a operacao pelo thl0022" skip.
    end.
end procedure.

// Processor retirado -> padrao; MensageriaProcessor -> MetricsProcessor
function replacementProcessor returns character private ( input currentName as character ):

    define variable shortName as character no-undo.

    assign shortName = entry( num-entries( currentName, "." ), currentName, "." ).

    if shortName = "MensageriaProcessor" then
        return metricsProcessor.

    if lookup( shortName, retiredNames ) > 0 then
        return defaultProcessor.

    return currentName.

end function.

procedure fixObjectProcessor private:
    define input parameter objectRowid as rowid no-undo.

    define variable newName as character no-undo.

    find b-thl-objeto no-lock
        where rowid( b-thl-objeto ) = objectRowid no-error.
    if not available b-thl-objeto then
        return.

    assign newName = replacementProcessor( b-thl-objeto.classe-processor ).

    if newName = b-thl-objeto.classe-processor then
        return.

    put stream logStream unformatted
        "thl-objeto;" b-thl-objeto.aplicacao "/" b-thl-objeto.objeto ";" b-thl-objeto.classe-processor ";" newName skip.

    if not simulate then do transaction:
        find current b-thl-objeto exclusive-lock.
        assign b-thl-objeto.classe-processor = newName.
        release b-thl-objeto.
    end.

    assign totalProcessor = totalProcessor + 1.
end procedure.

procedure fixOperationProcessor private:
    define input parameter operationRowid as rowid no-undo.

    define variable newName as character no-undo.

    find b-thl-objeto-parametro no-lock
        where rowid( b-thl-objeto-parametro ) = operationRowid no-error.
    if not available b-thl-objeto-parametro then
        return.

    assign newName = replacementProcessor( b-thl-objeto-parametro.classe-processor ).

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

    assign totalProcessor = totalProcessor + 1.
end procedure.

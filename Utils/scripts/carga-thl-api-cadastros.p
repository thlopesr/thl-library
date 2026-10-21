/*------------------------------------------------------------------------
    File        : carga-thl-api-cadastros.p
    Purpose     : Carga dos cadastros que ligam a API REST dos cadastros THL
                  ao resourcen.p: aplicacao THL, objetos (com as classes de
                  message, processor e service), parametros por metodo e
                  rotas inbound.
    Created     : 2026-09-25
    Notes       : - ADR Documentos/.claude/adr/inbound-message-processor-service.md.
                  - Um objeto por agregado (2026-10-04): os filhos sao
                    operacoes da URL (objeto/usuario), nao objetos nem rotas.
                    O Service do filho fica na linha da operacao
                    (thl-objeto-parametro.classe-service): rodar depois o
                    acerto-thl-operacao-service.p, que cria essas linhas.
                  - Classes do objeto: message (a padrao InboundMessage ou a
                    de mascara de segredo), processor (o padrao ou o do
                    agregado) e service (o do pai).
                  - O InboundConfigLoader usa a linha do metodo para qualquer
                    operacao sem linha propria; cada metodo usa o proprio
                    nome como operacao (GET, POST, PATCH, DELETE).
                  - Idempotente. Objeto ja cadastrado tem as tres classes
                    conferidas e corrigidas. Rota de filho de carga anterior
                    (parametro-variavel, objeto-usuario...) e desativada: a
                    URL passa a ser pai/filho.
                  - Objeto proprio de filho de carga anterior fica sem uso. A
                    carga so avisa no log; eliminar pelo thl0021/thl0022.
                  - A aplicacao THL e marcada como interna.
                  - Exige os deltas Database/delta-thl-2026-10-03.df,
                    delta-thl-2026-10-04.df e delta-thl-2026-10-05.df
                    carregados.
                  - A operacao nasce com o metodo, que e parte da chave
                    (delta-thl-2026-10-08.df). A extensao REST e criada pelo
                    acerto-thl-objeto-classes.p, que roda depois das cargas.
                  - Roda em SIMULACAO por padrao (simulate = yes): so gera o
                    log. Para gravar, altere simulate para no e rode de novo.
                  - Log: <session:temp-directory>carga-thl-api-cadastros.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate         as logical   no-undo initial yes.
define variable application      as character no-undo initial "THL".
define variable messagePkg       as character no-undo
    initial "thl-extensions.integration.thl.messaging.inbound.message.".
define variable processorPkg     as character no-undo
    initial "thl-extensions.integration.thl.messaging.inbound.process.".
define variable servicePkg       as character no-undo
    initial "thl-extensions.erp.thl.service.".
define variable defaultMessage   as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.InboundMessage".
define variable defaultProcessor as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.Processor".
define variable logFile          as character no-undo.
define variable loadOrder        as integer   no-undo.
define variable created          as integer   no-undo.
define variable updated          as integer   no-undo.
define variable existing         as integer   no-undo.
define variable obsolete         as integer   no-undo.
define variable failed           as integer   no-undo.

// objeto | message | processor | service | rota publica | descricao
// message e processor em branco = classes padrao da biblioteca
define temp-table tt-recurso no-undo
    field ordem      as integer
    field objeto     as character
    field message    as character
    field processor  as character
    field service    as character
    field rota       as character
    field descricao  as character
    index pk-recurso is primary unique objeto.

// filho de carga anterior: tinha rota e objeto proprios, agora e operacao do pai
define temp-table tt-filho-antigo no-undo
    field ordem         as integer
    field objeto-antigo as character
    field rota-antiga   as character
    field nova-url      as character
    index pk-filho-antigo is primary unique rota-antiga.

define stream logStream.

/* ***************************  Main Block  *************************** */

run addResource( "Ambiente"         , ""                        , ""                        , "AmbienteService"         , "ambiente"          , "Cadastro de ambientes (thl0001)" ).
run addResource( "ParametroAmbiente"        , "ParametroAmbienteMessage", ""                        , "ParametroAmbienteService", "parametro-ambiente", "Parametros de ambiente (thl0002); operacoes variavel e programa" ).
run addResource( "Aplicacao"        , ""                        , ""                        , "AplicacaoService"        , "aplicacao"         , "Cadastro de aplicacoes (thl0020)" ).
run addResource( "AuditoriaTabela"     , ""                        , ""                        , "AuditoriaTabelaService"  , "auditoria-tabela"  , "Tabelas auditadas (thl0050); operacoes acesso, campo, notificacao e expurgo" ).
run addResource( "ConexaoRest"     , "ConexaoRestMessage"      , ""                        , "ConexaoRestService"      , "conexao-rest"      , "Conexoes REST (thl0030); operacoes autenticacao e header" ).
run addResource( "ConexaoRestPath", ""                        , ""                        , "ConexaoRestPathService"  , "conexao-rest-path" , "Paths (endpoints) REST (thl0031)" ).
run addResource( "Objeto"           , ""                        , ""                        , "ObjetoService"           , "objeto"            , "Objetos de integracao (thl0021); operacoes parametro e usuario" ).
run addResource( "EmailParametro"  , ""                        , ""                        , "EmailParametroService"   , "email-parametro"   , "Parametros de e-mail (thl0010)" ).
run addResource( "GrupoEmail"      , ""                        , ""                        , "GrupoEmailService"       , "grupo-email"       , "Grupos de e-mail (thl0011); operacao usuario" ).

run addOldChild( "PARAMETRO-VARIAVEL"       , "parametro-variavel"          , "parametro-ambiente/variavel" ).
run addOldChild( "PARAMETRO-PROGRAMA"       , "parametro-programa"          , "parametro-ambiente/programa" ).
run addOldChild( "AUDIT-TABELA-ACESSO"      , "auditoria-tabela-acesso"     , "auditoria-tabela/acesso" ).
run addOldChild( "AUDIT-TABELA-CAMPO"       , "auditoria-tabela-campo"      , "auditoria-tabela/campo" ).
run addOldChild( "AUDIT-TABELA-NOTIFICACAO" , "auditoria-tabela-notificacao", "auditoria-tabela/notificacao" ).
run addOldChild( "AUDIT-TABELA-EXPURGO"     , "auditoria-tabela-expurgo"    , "auditoria-tabela/expurgo" ).
run addOldChild( "CONEXAO-REST-AUTENTICACAO", "conexao-rest-autenticacao"   , "conexao-rest/autenticacao" ).
run addOldChild( "CONEXAO-REST-HEADER"      , "conexao-rest-header"         , "conexao-rest/header" ).
run addOldChild( "OBJETO-PARAMETRO"         , "objeto-parametro"            , "objeto/parametro" ).
run addOldChild( "OBJETO-USUARIO"           , "objeto-usuario"              , "objeto/usuario" ).
run addOldChild( "InboundRota"              , "inbound-rota"                , "objeto/rota" ).
run addOldChild( "GRUPO-EMAIL-USUARIO"      , "grupo-email-usuario"         , "grupo-email/usuario" ).

logFile = session:temp-directory + "carga-thl-api-cadastros.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Carga API cadastros THL em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip
    "tabela;chave;acao" skip.

run loadApplication.

for each tt-recurso by tt-recurso.ordem:
    run loadObject    ( buffer tt-recurso ).
    run loadParameters( buffer tt-recurso ).
    run loadRoute     ( buffer tt-recurso ).
end.

for each tt-filho-antigo by tt-filho-antigo.ordem:
    run disableOldRoute( buffer tt-filho-antigo ).
    run reportObsolete ( tt-filho-antigo.objeto-antigo ).
end.

put stream logStream unformatted skip
    ( if simulate then "Seriam criados: " else "Criados: " ) created skip
    ( if simulate then "Seriam alterados: " else "Alterados: " ) updated skip
    "Ja cadastrados: " existing skip
    "Objetos sem uso (eliminar depois): " obsolete skip
    "Erros: " failed skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Seriam criados: " else "Criados: " ) created chr(10)
        ( if simulate then "Seriam alterados: " else "Alterados: " ) updated chr(10)
        "Ja cadastrados: " existing chr(10)
        "Objetos sem uso (eliminar depois): " obsolete chr(10)
        "Erros: " failed chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure addResource private:
    define input parameter objectName      as character no-undo.
    define input parameter messageName     as character no-undo.
    define input parameter processorName   as character no-undo.
    define input parameter serviceName     as character no-undo.
    define input parameter routePath       as character no-undo.
    define input parameter descriptionText as character no-undo.

    loadOrder = loadOrder + 1.

    create tt-recurso.
    assign tt-recurso.ordem     = loadOrder
           tt-recurso.objeto    = objectName
           tt-recurso.message   = if messageName   = "" then defaultMessage   else messagePkg   + messageName
           tt-recurso.processor = if processorName = "" then defaultProcessor else processorPkg + processorName
           tt-recurso.service   = servicePkg + serviceName
           tt-recurso.rota      = routePath
           tt-recurso.descricao = descriptionText.
end procedure.

procedure addOldChild private:
    define input parameter legacyObject as character no-undo.
    define input parameter legacyRoute  as character no-undo.
    define input parameter newUrl       as character no-undo.

    loadOrder = loadOrder + 1.

    create tt-filho-antigo.
    assign tt-filho-antigo.ordem         = loadOrder
           tt-filho-antigo.objeto-antigo = legacyObject
           tt-filho-antigo.rota-antiga   = legacyRoute
           tt-filho-antigo.nova-url      = newUrl.
end procedure.

procedure loadApplication private:
    define buffer b-aplicacao for thl-aplicacao.

    find first b-aplicacao no-lock
        where b-aplicacao.aplicacao = application
        no-error.

    if available b-aplicacao then do:

        if b-aplicacao.ind-interna then do:
            run countExisting( "thl-aplicacao", application ).
            return.
        end.

        // aplicacao do proprio THL: marca como interna (separa o trafego nos monitores e metricas)
        if not simulate then do transaction:
            find current b-aplicacao exclusive-lock.
            assign b-aplicacao.ind-interna = yes.
        end.
        run countUpdated( "thl-aplicacao", application + " -> interna" ).
        return.

    end.

    if not simulate then do transaction:
        create thl-aplicacao.
        assign thl-aplicacao.aplicacao   = application
               thl-aplicacao.descricao   = "THL - cadastros do proprio framework"
               thl-aplicacao.ind-interna = yes.
    end.
    run countCreated( "thl-aplicacao", application ).

    // erro num registro nao interrompe os demais; fica registrado no log
    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-aplicacao", application, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

procedure loadObject private:
    define parameter buffer b-recurso for tt-recurso.

    define buffer b-objeto for thl-objeto.

    define variable objectKey as character no-undo.

    objectKey = application + "/" + b-recurso.objeto.

    find first b-objeto no-lock
        where b-objeto.aplicacao = application
          and b-objeto.objeto    = b-recurso.objeto
        no-error.

    if available b-objeto then do:

        if b-objeto.classe-objeto    = b-recurso.message   and
           b-objeto.classe-processor = b-recurso.processor and
           b-objeto.classe-service   = b-recurso.service   then do:
            run countExisting( "thl-objeto", objectKey ).
            return.
        end.

        // objeto de carga anterior: acerta as tres classes
        if not simulate then do transaction:
            find current b-objeto exclusive-lock.
            assign b-objeto.classe-objeto    = b-recurso.message
                   b-objeto.classe-processor = b-recurso.processor
                   b-objeto.classe-service   = b-recurso.service.
        end.
        run countUpdated( "thl-objeto", objectKey + " -> classes de message, processor e service" ).
        return.

    end.

    if not simulate then do transaction:
        create thl-objeto.
        assign thl-objeto.aplicacao          = application
               thl-objeto.objeto             = b-recurso.objeto
               thl-objeto.classe-objeto      = b-recurso.message
               thl-objeto.classe-processor   = b-recurso.processor
               thl-objeto.classe-service     = b-recurso.service
               thl-objeto.modelo-integracao  = 1      // REST
               thl-objeto.sentido-fluxo      = no     // Entrada
               thl-objeto.ind-inativo        = no
               thl-objeto.ind-gera-historico = no.
    end.
    run countCreated( "thl-objeto", objectKey + " -> " + b-recurso.service ).

    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto", objectKey, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

procedure loadParameters private:
    define parameter buffer b-recurso for tt-recurso.

    define variable methodList  as character no-undo initial "5,1,3,4".   // GET, POST, PATCH, DELETE
    define variable methodIndex as integer   no-undo.
    define variable methodType  as integer   no-undo.
    define variable operation   as character no-undo.
    define variable paramKey    as character no-undo.

    do methodIndex = 1 to num-entries( methodList ):

        assign methodType = integer( entry( methodIndex, methodList ) )
               operation  = ""
               paramKey   = substitute( "*/&1/&2/(branco)/&3", application, b-recurso.objeto, methodType ).

        if can-find( first thl-objeto-parametro where thl-objeto-parametro.cod-estabel = "*"
                                            and thl-objeto-parametro.aplicacao   = application
                                            and thl-objeto-parametro.objeto      = b-recurso.objeto
                                            and thl-objeto-parametro.operacao    = operation
                                            and thl-objeto-parametro.metodo      = methodType ) then do:
            run countExisting( "thl-objeto-parametro", paramKey ).
            next.
        end.

        if not simulate then do transaction:
            create thl-objeto-parametro.
            assign thl-objeto-parametro.cod-estabel          = "*"
                   thl-objeto-parametro.aplicacao            = application
                   thl-objeto-parametro.objeto               = b-recurso.objeto
                   thl-objeto-parametro.operacao             = operation
                   thl-objeto-parametro.metodo               = methodType
                   thl-objeto-parametro.classe-objeto        = b-recurso.message
                   thl-objeto-parametro.classe-processor     = b-recurso.processor
                   thl-objeto-parametro.classe-service       = b-recurso.service
                   thl-objeto-parametro.forma-execucao       = 1     // Online
                   thl-objeto-parametro.ind-inativo          = no
                   thl-objeto-parametro.ind-mensagem-simples = no
                   thl-objeto-parametro.ind-gera-historico   = no.
        end.
        run countCreated( "thl-objeto-parametro", paramKey ).

        catch loadError as Progress.Lang.Error:
            run countFailed( "thl-objeto-parametro", paramKey, loadError:GetMessage( 1 ) ).
        end catch.
    end.
end procedure.

procedure loadRoute private:
    define parameter buffer b-recurso for tt-recurso.

    define buffer b-rota for thl-objeto-rota.

    define variable routeKey as character no-undo.

    assign routeKey = b-recurso.rota + " -> " + application + "/" + b-recurso.objeto.

    // a chave e aplicacao + objeto + rota publica: o objeto pode ter varias rotas
    find first b-rota no-lock
        where b-rota.aplicacao    = application
          and b-rota.objeto       = b-recurso.objeto
          and b-rota.rota-publica = b-recurso.rota
        no-error.

    if available b-rota and b-rota.ind-ativo then do:
        run countExisting( "thl-objeto-rota", b-recurso.rota ).
        return.
    end.

    // o caminho publico e unico: nao pode estar em outro objeto
    if can-find( first thl-objeto-rota
                 where thl-objeto-rota.rota-publica = b-recurso.rota
                   and ( thl-objeto-rota.aplicacao <> application or
                         thl-objeto-rota.objeto    <> b-recurso.objeto ) ) then do:
        run countFailed( "thl-objeto-rota", b-recurso.rota, "rota publica ja usada por outro objeto" ).
        return.
    end.

    if available b-rota then do:
        if not simulate then do transaction:
            find current b-rota exclusive-lock.
            assign b-rota.ind-ativo = yes.
        end.
        run countUpdated( "thl-objeto-rota", routeKey ).
        return.
    end.

    if not simulate then do transaction:
        create thl-objeto-rota.
        assign thl-objeto-rota.aplicacao    = application
               thl-objeto-rota.objeto       = b-recurso.objeto
               thl-objeto-rota.rota-publica = b-recurso.rota
               thl-objeto-rota.ind-ativo    = yes.
    end.
    run countCreated( "thl-objeto-rota", routeKey ).

    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto-rota", b-recurso.rota, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

// rota propria de filho (carga anterior): desativa. Ativa, ela seria lida como
// rota sem operacao e cairia no Service do pai.
procedure disableOldRoute private:
    define parameter buffer b-filho for tt-filho-antigo.

    define buffer b-rota for thl-objeto-rota.

    find first b-rota no-lock
        where b-rota.rota-publica = b-filho.rota-antiga
          and b-rota.aplicacao    = application
        no-error.

    if not available b-rota or not b-rota.ind-ativo then
        return.

    if not simulate then do transaction:
        find current b-rota exclusive-lock.
        assign b-rota.ind-ativo = no.
    end.
    run countUpdated( "thl-objeto-rota", b-filho.rota-antiga + " -> desativada (nova URL: " + b-filho.nova-url + ")" ).

    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto-rota", b-filho.rota-antiga, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

// objeto proprio do filho, criado por carga anterior: nao e mais usado
procedure reportObsolete private:
    define input parameter legacyObject as character no-undo.

    if not can-find( thl-objeto where thl-objeto.aplicacao = application
                                  and thl-objeto.objeto    = legacyObject ) then
        return.

    obsolete = obsolete + 1.
    run writeLog( "thl-objeto", application + "/" + legacyObject, "sem uso - eliminar o objeto, os parametros e os usuarios dele" ).
end procedure.

procedure countCreated private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.

    created = created + 1.
    run writeLog( tableName, keyValue, if simulate then "seria criado" else "criado" ).
end procedure.

procedure countUpdated private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.

    updated = updated + 1.
    run writeLog( tableName, keyValue, if simulate then "seria alterado" else "alterado" ).
end procedure.

procedure countExisting private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.

    existing = existing + 1.
    run writeLog( tableName, keyValue, "ja cadastrado" ).
end procedure.

procedure countFailed private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.
    define input parameter errorText as character no-undo.

    failed = failed + 1.
    run writeLog( tableName, keyValue, "erro: " + errorText ).
end procedure.

procedure writeLog private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.
    define input parameter action    as character no-undo.

    put stream logStream unformatted tableName ";" keyValue ";" action skip.
end procedure.

/*------------------------------------------------------------------------
    File        : carga-thl-transporte.p
    Purpose     : Carga dos cadastros que ligam a consulta de transportador
                  (message padrao + TransporteService) ao resourcen.p:
                  objeto, parametro do metodo GET e rota inbound.
    Created     : 2026-09-30
    Notes       : - Modelo carga-thl-api-cadastros.p.
                  - So GET: sem operacao na URL, o MessageConfigLoader acha o
                    thl-objeto-parametro pelo metodo; a operacao gravada e
                    em branco (linha do pai; a chave e operacao + metodo).
                  - A aplicacao precisa existir em thl-aplicacao (o script
                    nao a cria); ajuste a variavel application se o objeto
                    for de outra aplicacao.
                  - Idempotente: registro ja cadastrado nao e alterado.
                  - Roda em SIMULACAO por padrao (simulate = yes): so gera o
                    log. Para gravar, altere simulate para no e rode de novo.
                  - Log: <session:temp-directory>carga-thl-transporte.log
                  - Uso: GET .../resourcen/transporte?codigo=<cod-transp>
                         GET .../resourcen/transporte?nome=<nome-abrev>
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate    as logical   no-undo initial yes.
define variable application as character no-undo initial "THL".
define variable objectName  as character no-undo initial "TRANSPORTE".
//TransporteMessage foi retirada (2026-10-04): message e processor padrao + Service
define variable className   as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.InboundMessage".
define variable processorName as character no-undo
    initial "thl-lib.integration.messaging.inbound.core.Processor".
define variable serviceName as character no-undo
    initial "thl-lib.erp.service.TransporteService".
define variable routePath   as character no-undo initial "transporte".
define variable routeText   as character no-undo initial "Consulta de transportador (transporte)".
define variable methodType  as integer   no-undo initial 5.     // MethodTypeEnum: 5=GET
define variable operation   as character no-undo initial "".
define variable logFile     as character no-undo.
define variable created     as integer   no-undo.
define variable existing    as integer   no-undo.
define variable failed      as integer   no-undo.

define stream logStream.

/* ***************************  Main Block  *************************** */

logFile = session:temp-directory + "carga-thl-transporte.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Carga objeto TRANSPORTE em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip
    "tabela;chave;acao" skip.

if not can-find( thl-aplicacao where thl-aplicacao.aplicacao = application ) then
    run countFailed( "thl-aplicacao", application, "aplicacao nao cadastrada - cadastre antes de rodar a carga" ).
else do:
    run loadObject.
    run loadParameter.
    run loadRoute.
end.

put stream logStream unformatted skip
    ( if simulate then "Seriam criados: " else "Criados: " ) created skip
    "Ja cadastrados: " existing skip
    "Erros: " failed skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Seriam criados: " else "Criados: " ) created chr(10)
        "Ja cadastrados: " existing chr(10)
        "Erros: " failed chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure loadObject private:
    define variable objectKey as character no-undo.

    objectKey = application + "/" + objectName.

    if can-find( thl-objeto where thl-objeto.aplicacao = application
                              and thl-objeto.objeto    = objectName ) then do:
        run countExisting( "thl-objeto", objectKey ).
        return.
    end.

    if not simulate then do transaction:
        create thl-objeto.
        assign thl-objeto.aplicacao          = application
               thl-objeto.objeto             = objectName
               thl-objeto.classe-objeto      = className
               thl-objeto.classe-processor   = processorName
               thl-objeto.classe-service     = serviceName
               thl-objeto.modelo-integracao  = 1      // REST
               thl-objeto.sentido-fluxo      = no     // Entrada
               thl-objeto.ind-inativo        = no
               thl-objeto.ind-gera-historico = no.
    end.
    run countCreated( "thl-objeto", objectKey + " -> " + className ).

    // erro num registro nao interrompe os demais; fica registrado no log
    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto", objectKey, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

procedure loadParameter private:
    define variable paramKey as character no-undo.

    paramKey = substitute( "*/&1/&2/(branco)/&3", application, objectName, methodType ).

    if can-find( first thl-objeto-parametro where thl-objeto-parametro.cod-estabel = "*"
                                        and thl-objeto-parametro.aplicacao   = application
                                        and thl-objeto-parametro.objeto      = objectName
                                        and thl-objeto-parametro.operacao    = operation
                                        and thl-objeto-parametro.metodo      = methodType ) then do:
        run countExisting( "thl-objeto-parametro", paramKey ).
        return.
    end.

    if not simulate then do transaction:
        create thl-objeto-parametro.
        assign thl-objeto-parametro.cod-estabel          = "*"
               thl-objeto-parametro.aplicacao            = application
               thl-objeto-parametro.objeto               = objectName
               thl-objeto-parametro.operacao             = operation
               thl-objeto-parametro.metodo               = methodType
               thl-objeto-parametro.classe-objeto        = className
               thl-objeto-parametro.classe-processor     = processorName
               thl-objeto-parametro.classe-service       = serviceName
               thl-objeto-parametro.forma-execucao       = 1     // Online
               thl-objeto-parametro.ind-inativo          = no
               thl-objeto-parametro.ind-mensagem-simples = no
               thl-objeto-parametro.ind-gera-historico   = no.  // consulta nao gera historico
    end.
    run countCreated( "thl-objeto-parametro", paramKey ).

    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto-parametro", paramKey, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

procedure loadRoute private:

    // uma rota por objeto (chave aplicacao + objeto); o caminho publico e unico
    if can-find( first thl-objeto-rota where thl-objeto-rota.rota-publica = routePath ) or
       can-find( thl-objeto-rota where thl-objeto-rota.aplicacao = application
                                   and thl-objeto-rota.objeto    = objectName ) then do:
        run countExisting( "thl-objeto-rota", routePath ).
        return.
    end.

    if not simulate then do transaction:
        create thl-objeto-rota.
        assign thl-objeto-rota.aplicacao    = application
               thl-objeto-rota.objeto       = objectName
               thl-objeto-rota.rota-publica = routePath
               thl-objeto-rota.ind-ativo    = yes.
    end.
    run countCreated( "thl-objeto-rota", routePath + " -> " + application + "/" + objectName ).

    catch loadError as Progress.Lang.Error:
        run countFailed( "thl-objeto-rota", routePath, loadError:GetMessage( 1 ) ).
    end catch.
end procedure.

procedure countCreated private:
    define input parameter tableName as character no-undo.
    define input parameter keyValue  as character no-undo.

    created = created + 1.
    run writeLog( tableName, keyValue, if simulate then "seria criado" else "criado" ).
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

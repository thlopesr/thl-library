/*------------------------------------------------------------------------
    File        : carga-thl-aplicacao.p
    Purpose     : Carga inicial do cadastro thl-aplicacao (thl0020) a partir
                  dos valores de aplicacao já gravados nas tabelas THL.
    Created     : 2026-09-25
    Notes       : - Lê os valores distintos do campo aplicacao em thl-objeto,
                    thl-objeto-parametro, thl-objeto-usuario, thl-objeto-rota
                    e thl-mensagem e cria em thl-aplicacao os que faltam, com
                    descricao = código (ajustar depois no thl0020).
                  - Idempotente: aplicação já cadastrada não é alterada.
                  - Valor em branco é ignorado.
                  - Roda em SIMULAÇÃO por padrão (simulate = yes): só gera o
                    log. Para gravar, altere simulate para no e rode de novo.
                  - Log: <session:temp-directory>carga-thl-aplicacao.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate     as logical   no-undo initial yes.
define variable sourceTables as character no-undo
    initial "thl-objeto,thl-objeto-parametro,thl-objeto-usuario,thl-objeto-rota,thl-mensagem".
define variable logFile      as character no-undo.
define variable tableIndex   as integer   no-undo.
define variable appCode      as character no-undo.
define variable appOrigin    as character no-undo.
define variable created      as integer   no-undo.
define variable existing     as integer   no-undo.
define variable failed       as integer   no-undo.

define temp-table tt-aplicacao no-undo
    field aplicacao as character
    field origem    as character
    index pk-aplicacao is primary unique aplicacao.

define stream logStream.

/* ***************************  Main Block  *************************** */

logFile = session:temp-directory + "carga-thl-aplicacao.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Carga thl-aplicacao em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip
    "aplicacao;origem;acao" skip.

do tableIndex = 1 to num-entries( sourceTables ):
    run collectFromTable( entry( tableIndex, sourceTables ) ).
end.

for each tt-aplicacao:
    // guardados antes da gravação: no CATCH o buffer pode não estar mais disponível
    assign appCode   = tt-aplicacao.aplicacao
           appOrigin = tt-aplicacao.origem.

    if can-find( thl-aplicacao where thl-aplicacao.aplicacao = appCode ) then do:
        existing = existing + 1.
        run writeLog( appCode, appOrigin, "ja cadastrada" ).
        next.
    end.

    if simulate then do:
        created = created + 1.
        run writeLog( appCode, appOrigin, "seria criada" ).
        next.
    end.

    do transaction:
        create thl-aplicacao.
        assign thl-aplicacao.aplicacao = appCode
               thl-aplicacao.descricao = appCode.
    end.

    created = created + 1.
    run writeLog( appCode, appOrigin, "criada" ).

    // erro numa aplicação não interrompe as demais; fica registrado no log
    catch loadError as Progress.Lang.Error:
        failed = failed + 1.
        run writeLog( appCode, appOrigin, "erro: " + loadError:GetMessage( 1 ) ).
    end catch.
end.

put stream logStream unformatted skip
    ( if simulate then "Seriam criadas: " else "Criadas: " ) created skip
    "Ja cadastradas: " existing skip
    "Erros: " failed skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Seriam criadas: " else "Criadas: " ) created chr(10)
        "Ja cadastradas: " existing chr(10)
        "Erros: " failed chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure collectFromTable private:
    define input parameter tableName as character no-undo.

    define variable tableBuffer as handle    no-undo.
    define variable lastValue   as character no-undo.

    create buffer tableBuffer for table tableName.

    // salta de valor em valor (aplicacao > último lido): nas tabelas com índice
    // iniciado por aplicacao (thl-mensagem inclusive) não lê todos os registros
    do while true:
        tableBuffer:find-first( substitute( "where &1.aplicacao > &2", tableName, quoter( lastValue ) ), no-lock ) no-error.
        if not tableBuffer:available then
            leave.

        lastValue = tableBuffer:buffer-field( "aplicacao" ):buffer-value.

        find tt-aplicacao where tt-aplicacao.aplicacao = lastValue no-error.
        if not available tt-aplicacao then do:
            create tt-aplicacao.
            tt-aplicacao.aplicacao = lastValue.
        end.
        tt-aplicacao.origem = tt-aplicacao.origem + ( if tt-aplicacao.origem = "" then "" else "," ) + tableName.
    end.

    finally:
        delete object tableBuffer no-error.
    end finally.
end procedure.

procedure writeLog private:
    define input parameter logApplication as character no-undo.
    define input parameter logOrigin      as character no-undo.
    define input parameter logAction      as character no-undo.

    put stream logStream unformatted logApplication ";" logOrigin ";" logAction skip.
end procedure.

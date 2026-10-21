/*------------------------------------------------------------------------
    File        : acerto-thl-operacao-classes.p
    Purpose     : Prepara a base para a execucao que le so a linha da operacao
                  (thl-objeto-parametro):
                  1. operacao com o nome do verbo (POST, PUT, PATCH, DELETE,
                     GET) vira operacao em branco, que e a linha do pai; a
                     extensao REST (thl-objeto-parametro-rest) vai junto;
                  2. classe em branco da linha (message, processor, service)
                     recebe a do objeto (thl-objeto).
    Created     : 2026-10-08
    Notes       : - ADR Documentos/.claude/adr/operacao-acao-extensao-rest.md
                    (secao 14).
                  - Rodar ANTES de publicar o InboundConfigLoader e o
                    MessageConfigLoader novos: sem isto, a linha com o nome do
                    verbo deixa de ser achada e a classe em branco deixa de
                    valer a do objeto. Pode rodar depois do
                    acerto-thl-objeto-classes.p e do
                    acerto-thl-operacao-service.p (a ordem entre eles nao
                    importa; este deve ser o ultimo).
                  - Operacao com o nome do verbo e metodo diferente (POST na
                    operacao GET, por exemplo) nao e tocada: vai para o log.
                  - Se ja existe a linha em branco do mesmo metodo, nada e
                    movido: a duplicata vai para o log. Eliminar uma das duas
                    pelo thl0022 e rodar de novo.
                  - Idempotente. Roda em SIMULACAO por padrao (simulate = yes).
                  - Log: <session:temp-directory>acerto-thl-operacao-classes.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate       as logical   no-undo initial yes.
define variable verbNames      as character no-undo initial "POST,PUT,PATCH,DELETE,GET".
define variable logFile        as character no-undo.
define variable totalMoved     as integer   no-undo.
define variable totalDuplicate as integer   no-undo.
define variable totalOther     as integer   no-undo.
define variable totalFilled    as integer   no-undo.

define temp-table tt-linha no-undo
    field id-registro as rowid.

define buffer b-thl-objeto-parametro      for thl-objeto-parametro.
define buffer b-thl-objeto-parametro-rest for thl-objeto-parametro-rest.
define buffer b-outra                     for thl-objeto-parametro.
define buffer b-outra-rest                for thl-objeto-parametro-rest.

define stream logStream.

/* ***************************  Main Block  *************************** */

assign logFile = session:temp-directory + "acerto-thl-operacao-classes.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Operacoes e classes em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip(1)
    "OPERACAO COM O NOME DO VERBO" skip
    "estabelecimento/aplicacao/objeto/operacao;metodo;situacao" skip.

// ------------------------------------------------------------ 1. verbo -> branco

for each thl-objeto-parametro no-lock
    where thl-objeto-parametro.operacao <> "":

    if thl-objeto-parametro.metodo < 1 or thl-objeto-parametro.metodo > 5 then
        next.

    if thl-objeto-parametro.operacao <> entry( thl-objeto-parametro.metodo, verbNames ) then do:
        // nome de verbo de outro metodo: nao e a linha generica
        if lookup( thl-objeto-parametro.operacao, verbNames ) > 0 then do:
            assign totalOther = totalOther + 1.
            put stream logStream unformatted
                thl-objeto-parametro.cod-estabel "/" thl-objeto-parametro.aplicacao "/"
                thl-objeto-parametro.objeto "/" thl-objeto-parametro.operacao ";"
                thl-objeto-parametro.metodo ";nome de verbo de outro metodo - conferir pelo thl0022" skip.
        end.
        next.
    end.

    create tt-linha.
    assign tt-linha.id-registro = rowid( thl-objeto-parametro ).
end.

for each tt-linha:
    run moveToBlankOperation( tt-linha.id-registro ).
end.

// ------------------------------------------------------------ 2. classes em branco

put stream logStream unformatted skip(1)
    "CLASSES EM BRANCO" skip
    "estabelecimento/aplicacao/objeto/operacao;metodo;situacao" skip.

empty temp-table tt-linha.

for each thl-objeto-parametro no-lock
    where thl-objeto-parametro.classe-objeto    = ""
       or thl-objeto-parametro.classe-processor = ""
       or thl-objeto-parametro.classe-service   = "":
    create tt-linha.
    assign tt-linha.id-registro = rowid( thl-objeto-parametro ).
end.

for each tt-linha:
    run fillClasses( tt-linha.id-registro ).
end.

put stream logStream unformatted skip(1)
    ( if simulate then "Operacoes que passariam para branco: " else "Operacoes passadas para branco: " ) totalMoved skip
    "Duplicadas (nada movido): " totalDuplicate skip
    "Nome de verbo de outro metodo (conferir): " totalOther skip
    ( if simulate then "Linhas que receberiam classes do objeto: " else "Linhas com classes do objeto: " ) totalFilled skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Operacoes que passariam para branco: " else "Operacoes passadas para branco: " ) totalMoved chr(10)
        "Duplicadas (nada movido): " totalDuplicate chr(10)
        "Nome de verbo de outro metodo (conferir): " totalOther chr(10)
        ( if simulate then "Linhas que receberiam classes do objeto: " else "Linhas com classes do objeto: " ) totalFilled chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure moveToBlankOperation private:
    define input parameter lineRowid as rowid no-undo.

    define variable estabCode   as character no-undo.
    define variable appCode     as character no-undo.
    define variable objectCode  as character no-undo.
    define variable oldOp       as character no-undo.
    define variable methodCode  as integer   no-undo.
    define variable lineKey     as character no-undo.

    find b-thl-objeto-parametro no-lock
        where rowid( b-thl-objeto-parametro ) = lineRowid no-error.
    if not available b-thl-objeto-parametro then
        return.

    assign estabCode  = b-thl-objeto-parametro.cod-estabel
           appCode    = b-thl-objeto-parametro.aplicacao
           objectCode = b-thl-objeto-parametro.objeto
           oldOp      = b-thl-objeto-parametro.operacao
           methodCode = b-thl-objeto-parametro.metodo
           lineKey    = substitute( "&1/&2/&3/&4", estabCode, appCode, objectCode, oldOp ).

    if can-find( b-outra
                 where b-outra.cod-estabel = estabCode
                   and b-outra.aplicacao   = appCode
                   and b-outra.objeto      = objectCode
                   and b-outra.operacao    = ""
                   and b-outra.metodo      = methodCode ) then do:
        assign totalDuplicate = totalDuplicate + 1.
        put stream logStream unformatted lineKey ";" methodCode ";DUPLICADA - ja existe a linha em branco do metodo; eliminar uma das duas pelo thl0022" skip.
        return.
    end.

    if not simulate then do transaction:

        // extensao REST: acompanha a linha; se a em branco ja existe, a do verbo sai
        find b-thl-objeto-parametro-rest exclusive-lock
            where b-thl-objeto-parametro-rest.cod-estabel = estabCode
              and b-thl-objeto-parametro-rest.aplicacao   = appCode
              and b-thl-objeto-parametro-rest.objeto      = objectCode
              and b-thl-objeto-parametro-rest.operacao    = oldOp
              and b-thl-objeto-parametro-rest.metodo      = methodCode
            no-error.

        if available b-thl-objeto-parametro-rest then do:
            if can-find( b-outra-rest
                         where b-outra-rest.cod-estabel = estabCode
                           and b-outra-rest.aplicacao   = appCode
                           and b-outra-rest.objeto      = objectCode
                           and b-outra-rest.operacao    = ""
                           and b-outra-rest.metodo      = methodCode ) then
                delete b-thl-objeto-parametro-rest.
            else
                assign b-thl-objeto-parametro-rest.operacao = "".
        end.

        find b-thl-objeto-parametro exclusive-lock
            where rowid( b-thl-objeto-parametro ) = lineRowid.
        assign b-thl-objeto-parametro.operacao = "".
        release b-thl-objeto-parametro.

    end.

    assign totalMoved = totalMoved + 1.
    put stream logStream unformatted lineKey ";" methodCode ";" ( if simulate then "passaria para operacao em branco" else "operacao em branco" ) skip.
end procedure.

procedure fillClasses private:
    define input parameter lineRowid as rowid no-undo.

    define variable lineKey as character no-undo.

    find b-thl-objeto-parametro no-lock
        where rowid( b-thl-objeto-parametro ) = lineRowid no-error.
    if not available b-thl-objeto-parametro then
        return.

    find first thl-objeto no-lock
        where thl-objeto.aplicacao = b-thl-objeto-parametro.aplicacao
          and thl-objeto.objeto    = b-thl-objeto-parametro.objeto
        no-error.

    assign lineKey = substitute( "&1/&2/&3/&4", b-thl-objeto-parametro.cod-estabel, b-thl-objeto-parametro.aplicacao,
                                                b-thl-objeto-parametro.objeto, b-thl-objeto-parametro.operacao ).

    if not available thl-objeto then do:
        put stream logStream unformatted lineKey ";" b-thl-objeto-parametro.metodo ";SEM OBJETO em thl-objeto - classes nao preenchidas" skip.
        return.
    end.

    if not simulate then do transaction:
        find current b-thl-objeto-parametro exclusive-lock.
        if b-thl-objeto-parametro.classe-objeto = "" then
            assign b-thl-objeto-parametro.classe-objeto = thl-objeto.classe-objeto.
        if b-thl-objeto-parametro.classe-processor = "" then
            assign b-thl-objeto-parametro.classe-processor = thl-objeto.classe-processor.
        if b-thl-objeto-parametro.classe-service = "" then
            assign b-thl-objeto-parametro.classe-service = thl-objeto.classe-service.
        release b-thl-objeto-parametro.
    end.

    assign totalFilled = totalFilled + 1.
    put stream logStream unformatted lineKey ";" b-thl-objeto-parametro.metodo ";"
        ( if simulate then "receberia as classes do objeto" else "classes do objeto" ) skip.
end procedure.

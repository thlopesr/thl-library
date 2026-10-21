/*------------------------------------------------------------------------
    File        : diagnostico-thl-situacao-mensagem.p
    Purpose     : Lista, por aplicacao + objeto + sentido, quantas mensagens
                  existem em cada combinacao das tres situacoes
                  (sit-requisicao, sit-processamento, sit-retorno).
                  Serve para conferir quais objetos gravam processamento
                  diferente de 4 (Nao Aplicavel) e quais ficaram com fase
                  pendente, antes de criar a situacao geral (sit-mensagem).
    Created     : 2026-10-03
    Notes       : - Somente leitura (no-lock); nao grava nada no banco.
                  - Le a thl-mensagem inteira: rodar fora do horario de pico
                    em base grande.
                  - Saida: <session:temp-directory>diagnostico-thl-situacao-mensagem.csv
                    (separador ;).
                  - Situacao geral prevista: 2=Erro se alguma fase esta em
                    erro; 1=Pendente se alguma fase esta pendente; 3=Sucesso
                    se todas estao em sucesso ou nao aplicavel.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define temp-table tt-situacao no-undo
    field aplicacao         as character
    field objeto            as character
    field sentido-fluxo     as logical
    field sit-requisicao    as integer
    field sit-processamento as integer
    field sit-retorno       as integer
    field quantidade        as integer
    field dt-ultima         as datetime
    index pk-situacao is primary unique
        aplicacao objeto sentido-fluxo sit-requisicao sit-processamento sit-retorno.

define variable outputFile   as character no-undo.
define variable totalRead    as integer   no-undo.
define variable totalGroups  as integer   no-undo.
define variable overallLabel as character no-undo.
define variable remark       as character no-undo.

define stream csvStream.

function getStatusLabel returns character ( input statusValue as integer ) forward.

/* ***************************  Main Block  *************************** */

for each thl-mensagem no-lock:

    find tt-situacao
        where tt-situacao.aplicacao         = thl-mensagem.aplicacao
          and tt-situacao.objeto            = thl-mensagem.objeto
          and tt-situacao.sentido-fluxo     = thl-mensagem.sentido-fluxo
          and tt-situacao.sit-requisicao    = thl-mensagem.sit-requisicao
          and tt-situacao.sit-processamento = thl-mensagem.sit-processamento
          and tt-situacao.sit-retorno       = thl-mensagem.sit-retorno
        no-error.

    if not available tt-situacao then do:
        create tt-situacao.
        assign tt-situacao.aplicacao         = thl-mensagem.aplicacao
               tt-situacao.objeto            = thl-mensagem.objeto
               tt-situacao.sentido-fluxo     = thl-mensagem.sentido-fluxo
               tt-situacao.sit-requisicao    = thl-mensagem.sit-requisicao
               tt-situacao.sit-processamento = thl-mensagem.sit-processamento
               tt-situacao.sit-retorno       = thl-mensagem.sit-retorno
               totalGroups                   = totalGroups + 1.
    end.

    assign tt-situacao.quantidade = tt-situacao.quantidade + 1
           totalRead              = totalRead + 1.

    if tt-situacao.dt-ultima = ? or thl-mensagem.dt-criacao > tt-situacao.dt-ultima then
        assign tt-situacao.dt-ultima = thl-mensagem.dt-criacao.

end.

outputFile = session:temp-directory + "diagnostico-thl-situacao-mensagem.csv".

output stream csvStream to value( outputFile ).

put stream csvStream unformatted
    "aplicacao;objeto;sentido;requisicao;processamento;retorno;quantidade;ultima criacao;situacao geral prevista;observacao" skip.

for each tt-situacao:

    run getOverall( tt-situacao.sit-requisicao, tt-situacao.sit-processamento, tt-situacao.sit-retorno,
                    output overallLabel ).

    assign remark = "".

    if tt-situacao.sit-processamento <> 4 then
        assign remark = "processamento diferente de Nao Aplicavel".

    if tt-situacao.sit-requisicao    = 1 or
       tt-situacao.sit-processamento = 1 or
       tt-situacao.sit-retorno       = 1 then
        assign remark = remark + ( if remark = "" then "" else " | " ) + "fase pendente".

    put stream csvStream unformatted
        tt-situacao.aplicacao ";"
        tt-situacao.objeto ";"
        ( if tt-situacao.sentido-fluxo then "Saida" else "Entrada" ) ";"
        tt-situacao.sit-requisicao    " - " getStatusLabel( tt-situacao.sit-requisicao    ) ";"
        tt-situacao.sit-processamento " - " getStatusLabel( tt-situacao.sit-processamento ) ";"
        tt-situacao.sit-retorno       " - " getStatusLabel( tt-situacao.sit-retorno       ) ";"
        tt-situacao.quantidade ";"
        ( if tt-situacao.dt-ultima = ? then "" else string( tt-situacao.dt-ultima ) ) ";"
        overallLabel ";"
        remark skip.

end.

output stream csvStream close.

message "Mensagens lidas: " totalRead chr(10)
        "Combinacoes encontradas: " totalGroups chr(10)
        "Arquivo: " outputFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure getOverall private:
    define input  parameter requestStatus as integer   no-undo.
    define input  parameter processStatus as integer   no-undo.
    define input  parameter returnStatus  as integer   no-undo.
    define output parameter overallText   as character no-undo.

    if requestStatus = 2 or processStatus = 2 or returnStatus = 2 then
        assign overallText = "2 - Erro".
    else if requestStatus = 1 or processStatus = 1 or returnStatus = 1 then
        assign overallText = "1 - Pendente".
    else
        assign overallText = "3 - Sucesso".
end procedure.

function getStatusLabel returns character ( input statusValue as integer ):
    case statusValue:
        when 1 then return "Pendente".
        when 2 then return "Erro".
        when 3 then return "Sucesso".
        when 4 then return "Nao Aplicavel".
        otherwise   return "Desconhecido".
    end case.
end function.

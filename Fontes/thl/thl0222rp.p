
/*------------------------------------------------------------------------
    File        : 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : 
    Notes       :
  ----------------------------------------------------------------------*/

{include/i-prgvrs.i thl0222rp 12.00.00.000}

/* pre-processador para ativar ou nao a saida para RTF */
&GLOBAL-DEFINE RTF NO

/* pre-processador para setar o tamanho da pagina */
&SCOPED-DEFINE pagesize 42   

define temp-table tt-param no-undo
    field destino                as integer
    field arquivo                as character format "x(35)"
    field usuario                as character format "x(12)"
    field data-exec              as date
    field hora-exec              as integer
    field classifica             as integer
    field desc-classifica        as character format "x(40)"
    field modelo-rtf             as character format "x(35)"
    field l-habilitaRtf          as logical
    field codigo-ini             like thl-mensagem.codigo-mensagem             
    field codigo-fin             like thl-mensagem.codigo-mensagem              
    field objeto-ini             like thl-mensagem.objeto             
    field objeto-fin             like thl-mensagem.objeto
    field aplicacao-ini           like thl-mensagem.aplicacao
    field aplicacao-fin           like thl-mensagem.aplicacao
    field operacao-ini            like thl-mensagem.operacao
    field operacao-fin            like thl-mensagem.operacao
    field metodo-ini                like thl-mensagem.metodo
    field metodo-fin                like thl-mensagem.metodo
    .

define temp-table tt-raw-digita no-undo
    field raw-digita as raw.

define input parameter raw-param as raw no-undo.
define input parameter table for tt-raw-digita.

create tt-param.
raw-transfer raw-param to tt-param.

{include/i-rpvar.i}

define new global shared variable c-seg-usuario as character  format 'x(12)' no-undo.

define variable progressHandle as handle    no-undo.
define variable deletedCount   as integer   no-undo.
define variable successDeleted as integer   no-undo.
define variable errorDeleted   as integer   no-undo.
define variable totalDeleted   as integer   no-undo.
define variable messageIndex   as integer   no-undo.
define variable errorText      as character no-undo format 'x(200)'.

form tt-param.codigo-ini     format 'x(40)'
     tt-param.codigo-fin     format 'x(40)'
     tt-param.aplicacao-ini  format 'x(40)'
     tt-param.aplicacao-fin  format 'x(40)'
     tt-param.objeto-ini     format 'x(40)'
     tt-param.objeto-fin     format 'x(40)'
     tt-param.operacao-ini   format 'x(40)'
     tt-param.operacao-fin   format 'x(40)'
     tt-param.metodo-ini       format '>9'
     tt-param.metodo-fin       format '>9'
     c-seg-usuario           format 'x(30)'      column-label 'Usuario'
    with width 268 frame f-param down stream-io.

form thl-objeto.aplicacao              format 'x(30)'
     thl-objeto.objeto                 format 'x(40)'
     thl-objeto.retencao-dias-sucesso  column-label 'Dias Sucesso'
     successDeleted                    column-label 'Sucesso Eliminadas'
     thl-objeto.retencao-dias-erro     column-label 'Dias Erro'
     errorDeleted                      column-label 'Erro/Pendente Eliminadas'
    with width 268 frame f-objeto down stream-io.

form totalDeleted column-label 'Total Eliminado'
    with width 268 frame f-total down stream-io.

form errorText column-label 'Erro'
    with width 268 frame f-erro down stream-io.

/* **********************  Internal Procedures  *********************** */

// Elimina as mensagens de um objeto numa situacao geral (sit-mensagem),
// criadas antes de hoje - retentionDays. Zero ou vazio = nao expurga.
procedure pi-expurgar.
    define input  parameter applicationName as character no-undo.
    define input  parameter objectName      as character no-undo.
    define input  parameter messageStatus   as integer   no-undo.
    define input  parameter retentionDays   as integer   no-undo.
    define output parameter deletedMessages as integer   no-undo.

    define variable cutoffDate as datetime no-undo.

    if retentionDays = ? or retentionDays <= 0 then
        return.

    // meia-noite do dia-limite: os ultimos retentionDays dias ficam inteiros
    assign cutoffDate = datetime( today - retentionDays ).

    // idx-objeto-situacao: igualdades + intervalo em dt-criacao.
    // cada iteracao e uma transacao (mensagem + filhas): nao acumula locks
    for each thl-mensagem exclusive-lock
        where thl-mensagem.aplicacao        = applicationName
          and thl-mensagem.objeto           = objectName
          and thl-mensagem.sit-mensagem     = messageStatus
          and thl-mensagem.dt-criacao       < cutoffDate
          and thl-mensagem.operacao        >= tt-param.operacao-ini
          and thl-mensagem.operacao        <= tt-param.operacao-fin
          and thl-mensagem.metodo          >= tt-param.metodo-ini
          and thl-mensagem.metodo          <= tt-param.metodo-fin
          and thl-mensagem.codigo-mensagem >= tt-param.codigo-ini
          and thl-mensagem.codigo-mensagem <= tt-param.codigo-fin.

        for each thl-mensagem-conteudo of thl-mensagem exclusive-lock.
            delete thl-mensagem-conteudo.
        end.

        for each thl-mensagem-historico of thl-mensagem exclusive-lock.
            delete thl-mensagem-historico.
        end.

        for each thl-mensagem-item of thl-mensagem exclusive-lock.
            delete thl-mensagem-item.
        end.

        for each thl-mensagem-ped-exec of thl-mensagem exclusive-lock.
            delete thl-mensagem-ped-exec.
        end.

        delete thl-mensagem.

        assign deletedMessages = deletedMessages + 1.

    end.

end procedure.

/* ***************************  Main Block  *************************** */

{include/i-rpout.i &STREAM="stream str-rp"}
{include/i-rpcab.i &STREAM="str-rp"}

assign c-programa     = 'thl0222'
       c-versao       = '12.00'
       c-revisao      = '.00.000'
       c-empresa      = 'Nitro'
       c-sistema      = 'Totvs'
       c-titulo-relat = 'Expurgo de Mensagens'.

view stream str-rp frame f-cabec.
view stream str-rp frame f-rodape.

run utp/ut-acomp.p persistent set progressHandle.

run pi-inicializar in progressHandle ( input 'Expurgo de Mensagens' ).

display stream str-rp
        tt-param.codigo-ini
        tt-param.codigo-fin
        tt-param.aplicacao-ini
        tt-param.aplicacao-fin
        tt-param.objeto-ini
        tt-param.objeto-fin
        tt-param.operacao-ini
        tt-param.operacao-fin
        tt-param.metodo-ini
        tt-param.metodo-fin
        c-seg-usuario        with frame f-param.
    down stream str-rp with frame f-param.

// A retencao vem do cadastro do objeto (thl0021): mensagens com sucesso
// (sit-mensagem = 3) pelo prazo de sucesso; com erro (2) ou pendentes (1)
// pelo prazo de erro. O campo qtd-dias da tela nao e mais usado.
for each thl-objeto no-lock
    where thl-objeto.aplicacao >= tt-param.aplicacao-ini
      and thl-objeto.aplicacao <= tt-param.aplicacao-fin
      and thl-objeto.objeto    >= tt-param.objeto-ini
      and thl-objeto.objeto    <= tt-param.objeto-fin:

    run pi-acompanhar in progressHandle ( thl-objeto.objeto ).

    assign successDeleted = 0
           errorDeleted   = 0.

    run pi-expurgar ( input  thl-objeto.aplicacao, input thl-objeto.objeto, input 3,
                      input  thl-objeto.retencao-dias-sucesso,
                      output successDeleted ).

    run pi-expurgar ( input  thl-objeto.aplicacao, input thl-objeto.objeto, input 2,
                      input  thl-objeto.retencao-dias-erro,
                      output deletedCount ).

    assign errorDeleted = deletedCount.

    run pi-expurgar ( input  thl-objeto.aplicacao, input thl-objeto.objeto, input 1,
                      input  thl-objeto.retencao-dias-erro,
                      output deletedCount ).

    assign errorDeleted = errorDeleted + deletedCount
           totalDeleted = totalDeleted + successDeleted + errorDeleted.

    display stream str-rp
         thl-objeto.aplicacao
         thl-objeto.objeto
         thl-objeto.retencao-dias-sucesso
         successDeleted
         thl-objeto.retencao-dias-erro
         errorDeleted        with frame f-objeto.
    down stream str-rp with frame f-objeto.

end.

display stream str-rp totalDeleted with frame f-total.
    down stream str-rp with frame f-total.

{include/i-rpclo.i &STREAM="stream str-rp"}

return "OK":U.

catch err as Progress.Lang.Error.

    do messageIndex = 1 to err:NumMessages.
        display stream str-rp err:GetMessage( messageIndex ) @ errorText with frame f-erro.
            down stream str-rp with frame f-erro.
    end.

end catch.

finally.

    if valid-handle( progressHandle ) then
        run pi-finalizar in progressHandle.

end finally.

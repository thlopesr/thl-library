/*------------------------------------------------------------------------
    File        : thl0210rp.p
    Purpose     : Expurgo do log de e-mails (thl-email)
    Description : Elimina os e-mails enviados antes de (hoje - qtd-dias),
                  na faixa de programa informada no thl0210.
    Created     : 2026-09-25
    Notes       : Percorre a faixa pela chave idx-data-envio
                  (cod-prog-dtsul, data-envio): um programa por vez, com
                  igualdade no programa e intervalo na data, para o indice
                  delimitar as duas colunas. E-mail sem data de envio (?)
                  nao e eliminado.
  ----------------------------------------------------------------------*/

{include/i-prgvrs.i thl0210rp 12.00.00.000}

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
    field prog-ini               like thl-email.cod-prog-dtsul
    field prog-fin               like thl-email.cod-prog-dtsul
    field qtd-dias               as integer.

define temp-table tt-raw-digita no-undo
    field raw-digita as raw.

define input parameter raw-param as raw no-undo.
define input parameter table for tt-raw-digita.

create tt-param.
raw-transfer raw-param to tt-param.

{include/i-rpvar.i}

define new global shared variable c-seg-usuario as character format 'x(12)' no-undo.

define variable acompanhar   as handle    no-undo.
define variable dat-expurgo  as datetime  no-undo.
define variable contador     as integer   no-undo.
define variable texto-erro   as character no-undo format 'x(200)'.

form thl-email.cod-prog-dtsul format 'x(20)'
     thl-email.data-envio
     thl-email.log-envio
     thl-email.assunto        format 'x(60)'
     thl-email.destino        format 'x(60)'
     with width 268 frame f-email down stream-io.

form tt-param.prog-ini   format 'x(40)'  column-label 'Programa Inicial'
     tt-param.prog-fin   format 'x(40)'  column-label 'Programa Final'
     tt-param.qtd-dias                   column-label 'Manter Dias'
     c-seg-usuario       format 'x(30)'  column-label 'Usuario'
     dat-expurgo                         column-label 'Eliminar Antes De'
    with width 268 frame f-param down stream-io.

form contador column-label 'E-mails Eliminados'
    with width 268 frame f-total down stream-io.

form texto-erro column-label 'Erro'
    with width 268 frame f-erro down stream-io.

{include/i-rpout.i &STREAM="stream str-rp"}
{include/i-rpcab.i &STREAM="str-rp"}

assign c-programa     = 'thl0210'
       c-versao       = '12.00'
       c-revisao      = '.00.000'
       c-empresa      = 'Nitro'
       c-sistema      = 'Totvs'
       c-titulo-relat = 'Expurgo de E-mails'.

view stream str-rp frame f-cabec.
view stream str-rp frame f-rodape.

run utp/ut-acomp.p persistent set acompanhar.

run pi-inicializar in acompanhar ( input 'Expurgo de E-mails' ).

// meia-noite do dia-limite: os ultimos qtd-dias ficam inteiros
assign dat-expurgo = datetime( today - tt-param.qtd-dias ).

display stream str-rp
        tt-param.prog-ini
        tt-param.prog-fin
        tt-param.qtd-dias
        c-seg-usuario
        dat-expurgo         with frame f-param.
    down stream str-rp with frame f-param.

// primeiro programa da faixa; os seguintes saltam pelo indice (> ultimo)
for each thl-email exclusive-lock
    where thl-email.cod-prog-dtsul >= tt-param.prog-ini
      and thl-email.cod-prog-dtsul <= tt-param.prog-fin 
      and thl-email.data-envio     <  dat-expurgo.

    run pi-acompanhar in acompanhar ( thl-email.cod-prog-dtsul ).

    display stream str-rp
        thl-email.cod-prog-dtsul
        thl-email.data-envio
        thl-email.log-envio
        thl-email.assunto
        thl-email.destino         with frame f-email.
    down stream str-rp with frame f-email.

    delete thl-email.
    
    assign contador = contador + 1.

end.

display stream str-rp contador with frame f-total.
    down stream str-rp with frame f-total.

{include/i-rpclo.i &STREAM="stream str-rp"}

return "OK":U.

catch err as Progress.Lang.Error.
    do contador = 1 to err:NumMessages.
        display stream str-rp err:GetMessage( contador ) @ texto-erro with frame f-erro.
            down stream str-rp with frame f-erro.
    end.
end catch.

finally.
    if valid-handle( acompanhar ) then
        run pi-finalizar in acompanhar.
end finally.

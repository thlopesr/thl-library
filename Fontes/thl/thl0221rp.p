
/*------------------------------------------------------------------------
    File        : thl0221rp.p
    Purpose     : Runner RPW para processamento de mensagens inbound
                  agendadas (ExecutionMode = SCHEDULE).
    Author(s)   : Lopes
    Created     : 2026-07-26
    Notes       : Agendado via thl0220z.p (branch sentido-fluxo = INBOUND).
                  Itera thl-mensagem pendentes (dt-integracao = ?) com
                  sentido-fluxo = false (INBOUND) e chama
                  InboundMessageService:processScheduled().
  ----------------------------------------------------------------------*/
using thl-lib.integration.messaging.inbound.service.InboundMessageService.

{include/i-prgvrs.i thl0221rp 12.00.00.000}

&GLOBAL-DEFINE RTF NO

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
    field metodo-fin                like thl-mensagem.metodo.

define temp-table tt-raw-digita no-undo
    field raw-digita as raw.

define input parameter raw-param as raw no-undo.
define input parameter table for tt-raw-digita.

create tt-param.
raw-transfer raw-param to tt-param.

{include/i-rpvar.i}

define new global shared variable c-seg-usuario as character format 'x(12)' no-undo.

define variable h-acompanhar as handle                no-undo.
define variable svc          as InboundMessageService no-undo.

form thl-mensagem.codigo-mensagem
     thl-mensagem.dt-integracao
     thl-mensagem.cod-status-retorno
     thl-mensagem.descr-retorno      format 'x(100)'
     with width 268 frame f-integr down stream-io.

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

{include/i-rpout.i &STREAM="stream str-rp"}

{include/i-rpcab.i &STREAM="str-rp"}

assign c-programa     = 'thl0221'
       c-versao       = '12.00'
       c-revisao      = '.00.000'
       c-empresa      = 'THL'
       c-sistema      = 'Totvs'
       c-titulo-relat = 'Inbound Agendados'.

view stream str-rp frame f-cabec.
view stream str-rp frame f-rodape.

run utp/ut-acomp.p persistent set h-acompanhar.

run pi-inicializar in h-acompanhar ( input 'Inbound Agendados' ).

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
    down stream str-rp  with frame f-param.

for each thl-mensagem no-lock
    where thl-mensagem.aplicacao       >= tt-param.aplicacao-ini
      and thl-mensagem.aplicacao       <= tt-param.aplicacao-fin
      and thl-mensagem.objeto          >= tt-param.objeto-ini
      and thl-mensagem.objeto          <= tt-param.objeto-fin
      and thl-mensagem.operacao        >= tt-param.operacao-ini
      and thl-mensagem.operacao        <= tt-param.operacao-fin
      and thl-mensagem.metodo          >= tt-param.metodo-ini
      and thl-mensagem.metodo          <= tt-param.metodo-fin
      and thl-mensagem.codigo-mensagem >= tt-param.codigo-ini
      and thl-mensagem.codigo-mensagem <= tt-param.codigo-fin
      and thl-mensagem.dt-integracao    = ?
      and not thl-mensagem.sentido-fluxo.

    run pi-acompanhar in h-acompanhar ( thl-mensagem.objeto ).

    svc = new InboundMessageService( thl-mensagem.aplicacao, thl-mensagem.objeto, thl-mensagem.metodo, thl-mensagem.operacao ).
    svc:processScheduled( thl-mensagem.codigo-mensagem ).
    delete object svc no-error.

    display stream str-rp
         thl-mensagem.codigo-mensagem
         thl-mensagem.dt-integracao
         thl-mensagem.cod-status-retorno
         thl-mensagem.descr-retorno        with frame f-integr.
    down stream str-rp with frame f-integr.

end.

{include/i-rpclo.i &STREAM="stream str-rp"}

return "OK":U.

catch err as Progress.Lang.Error.

    define variable iContador as integer no-undo.

    do iContador = 1 to err:NumMessages.
        display stream str-rp err:GetMessage(iContador) with frame f-integr.
            down stream str-rp with frame f-integr.
    end.

end catch.

finally.

    if valid-handle(h-acompanhar) then
        run pi-finalizar in h-acompanhar.

end finally.

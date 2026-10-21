/*------------------------------------------------------------------------
    File        : testProcessoExportacao.p
    Purpose     : Smoke test do envio Automatizacao / ProcessoExportacao / Envio
    Notes       : Roda em HML, com os cadastros carregados. Envia UM processo
                  informado em cNrProcExp/cCodEstabel. Nao compilado.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using thl-lib.integration.messaging.outbound.service.OutboundMessageService.

define variable cCodEstabel    as character                no-undo initial '1'.
define variable cNrProcExp     as character                no-undo initial ''.
define variable messageService as OutboundMessageService   no-undo.

find first processo-exp no-lock
    where processo-exp.cod-estabel = cCodEstabel
      and processo-exp.nr-proc-exp = cNrProcExp
    no-error.

if not available processo-exp then do:
    message 'Informe cCodEstabel/cNrProcExp de um processo existente.' view-as alert-box.
    return.
end.

assign messageService = new OutboundMessageService( 'Automatizacao', 'ProcessoExportacao', 'Envio' ).

messageService:beginBuild().
messageService:addObject( recid( processo-exp ) ).
messageService:finishBuild().

if messageService:process() then
    message 'Enviado. Confira thl-mensagem (sit-mensagem) e o monitor thl1986.' view-as alert-box.
else
    message 'Nao enviado (modo BATCH/SCHEDULE?). Confira a forma de execucao em thl0022.' view-as alert-box.

catch e as Progress.Lang.Error:
    message e:GetMessage(1) view-as alert-box error.
end catch.

finally.
    delete object messageService no-error.
end finally.

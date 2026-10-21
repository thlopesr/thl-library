
/*------------------------------------------------------------------------
   File        : InboundSchedulingService
   Purpose     : Agenda mensagem inbound para execucao via RPW (thl0220z.p)
                 e retorna JsonObject com messageCode, pedidoExecucao e status.
   Author(s)   : Lopes
   Created     : 2026-07-26
   Notes       : Reutiliza thl0220z.p (que faz branch por sentido-fluxo
                 para apontar o runner correto: thl0221rp.p para inbound).
                 Nao salva response na mensagem — dt-integracao permanece ?
                 para que o runner localize a mensagem como pendente.
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.JsonObject.

using thl-lib.integration.messaging.core.Message.
using thl-lib.integration.messaging.core.MessageConfig.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.service.InboundSchedulingService.

    method public JsonObject schedule( message_      as Message       ,
                                       configuration as MessageConfig ).

        define variable messageCode as character  no-undo.
        define variable numPedExec  as integer    no-undo.
        define variable response    as JsonObject no-undo.

        assign messageCode = message_:getMessageCode().

        if messageCode = '' or messageCode = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule',
                'Codigo da mensagem nao informado para agendamento.' ).

        run thl/thl0220z.p ( input  messageCode,
                             output numPedExec  ).

        if return-value = 'NOK':U then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule',
                substitute( 'Agendamento recusado para a mensagem &1.', messageCode ) ).

        if numPedExec = 0 or numPedExec = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule',
                substitute( 'Numero de pedido invalido para a mensagem &1.', messageCode ) ).

        assign response = new JsonObject().
        response:Add( 'messageCode'    , messageCode ).
        response:Add( 'pedidoExecucao' , numPedExec  ).
        response:Add( 'status'         , 'agendado'  ).

        return response.

    end method.

end class.

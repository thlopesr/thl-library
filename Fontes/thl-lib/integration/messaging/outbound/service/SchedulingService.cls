
 /*------------------------------------------------------------------------
    File        : SchedulingService
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.messaging.core.*.
using thl-lib.integration.connectors.core.ConnectorResponse.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.
using thl-lib.logging.LogUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.service.SchedulingService.

    /*------------------------------------------------------------------------------
     Purpose  : Agenda a mensagem para execucao via RPW (thl0220z.p) e retorna
                um ConnectorResponse com o resultado, equivalente ao modo ONLINE.
     Notes    : successRequest/successResponse = true indica agendamento aceito.
                successProcess = ? indica que o processamento ainda nao ocorreu.
                statusCode recebe o numero do pedido de execucao gerado pelo RPW.
    ------------------------------------------------------------------------------*/
    method public ConnectorResponse schedule( message_      as Message     ,
                                              configuration as MessageConfig ).

        define variable messageCode       as character        no-undo.
        define variable numPedidoExecucao as integer          no-undo.
        define variable response          as ConnectorResponse no-undo.

        assign messageCode = message_:getMessageCode().

        if not StringUtil:hasValue( messageCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule', 'Codigo da mensagem nao informado para agendamento.' ).

        run thl/thl0220z.p ( input  messageCode      ,
                             output numPedidoExecucao ).

        // [B1/F1] throw sem undo — preserva escritas de saveResponse na transacao corrente
        if return-value = 'NOK':U then do:
            assign response                 = new ConnectorResponse()
                   response:successRequest  = false
                   response:successResponse = false
                   response:successProcess  = false
                   response:statusCode      = 0
                   response:statusMessage   = substitute( 'SchedulingService: Agendamento recusado para a mensagem &1.', messageCode )
                   response:content         = ''
                   response:destination     = 'RPW'
                   .
            message_:saveResponse( response, configuration:historyEnabled ).
            //undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule',
            //    substitute( 'Agendamento recusado para a mensagem &1.', messageCode ) ).
        end.

        if numPedidoExecucao = 0 or numPedidoExecucao = ? then do:
            assign response                 = new ConnectorResponse()
                   response:successRequest  = true
                   response:successResponse = false
                   response:successProcess  = false
                   response:statusCode      = 0
                   response:statusMessage   = substitute( 'SchedulingService: Numero de pedido invalido para a mensagem &1.', messageCode )
                   response:content         = ''
                   response:destination     = 'RPW'
                   .
            message_:saveResponse( response, configuration:historyEnabled ).
            //undo, throw new ThlError( this-object:GetClass():TypeName, 'schedule',
            //    substitute( 'Numero de pedido invalido para a mensagem &1.', messageCode ) ).
        end.

        // [F3] successProcess=? (RPW ainda nao executou); statusCode=numPedidoExecucao para rastreabilidade
        assign response                 = new ConnectorResponse()
               response:successRequest  = true
               response:successResponse = true
               response:successProcess  = ?
               response:statusCode      = numPedidoExecucao
               response:statusMessage   = substitute( 'Mensagem agendada. Pedido de execucao: &1.',
                                                      numPedidoExecucao )
               response:content         = ''
               response:destination     = 'RPW'
               .

        message_:saveResponse( response, configuration:historyEnabled ).

        //aceito, mas ainda nao enviado: a situacao geral fica pendente ate o RPW gravar o resultado
        message_:markPending().

        LogUtil:write(
            substitute( 'SchedulingService.schedule: agendado msg=&1 pedido=&2',
                        messageCode, numPedidoExecucao ),
            'SchedulingService' ).

        return response.

        // [B1/F1] CATCH: excecoes do run thl0220z.p + relancamentos dos branches acima
        //   valid-object(response)=false: excecao do run -> salvar erro + throw
        //   valid-object(response)=true:  relancamento de branch -> apenas log + throw
        catch e as Progress.Lang.Error.
            //LogUtil:write(
            //    substitute( 'SchedulingService.schedule: falha ao agendar msg=&1 erro=&2',
            //                messageCode, e:GetMessage(1) ),
            //    'SchedulingService' ).

            if not valid-object( response ) then do:
                define variable errResponse as ConnectorResponse no-undo.
                assign errResponse                 = new ConnectorResponse()
                       errResponse:successRequest  = false
                       errResponse:successResponse = false
                       errResponse:successProcess  = false
                       errResponse:statusCode      = 0
                       errResponse:statusMessage   = e:GetMessage(1)
                       errResponse:content         = ''
                       errResponse:destination     = 'RPW'
                       .
                message_:saveResponse( errResponse, false ).
            end.

        end catch.

    end method.

end class.

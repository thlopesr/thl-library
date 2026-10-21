 
 /*------------------------------------------------------------------------
    File        : MessageService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.integration.messaging.core.*.
using thl-lib.logging.LogUtil.
using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.
using thl-lib.integration.messaging.outbound.core.OutboundMessage.
using thl-lib.core.environment.EnvironmentResource.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.service.MessageExecutionService. 

    method public ConnectorResponse executeOnline( message_      as Message       ,
                                                   configuration as MessageConfig ).

        define variable connectorRequest  as ConnectorRequest  no-undo.
        define variable connectorResponse as ConnectorResponse no-undo.

        if not type-of( message_, OutboundMessage ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeOnline', substitute( 'mensagem para objeto &1 nao e OutboundMessage.', message_:objectName ) ).
        
        assign connectorRequest                 = new ConnectorRequest()
               connectorRequest:connectorType   = configuration:connectorType
               connectorRequest:methodType      = configuration:methodType
               connectorRequest:connectorConfig = new ConnectorConfig( message_:applicationName + '.' + message_:objectName,
                                                                       configuration:parameterCode      ,
                                                                       configuration:routeParameterCode )
               connectorRequest:content         = message_:getPayloadContent()
               connectorRequest:contentText     = message_:loadContent()
               connectorRequest:pathParameters  = cast( message_, OutboundMessage ):getPathParameters()
               connectorResponse                = new ConnectorService():execute( connectorRequest ).
        
        message_:saveResponse( connectorResponse, configuration:historyEnabled ).
        
        return connectorResponse.

        catch err as Progress.Lang.Error.

            if not valid-object( connectorResponse ) and valid-object( message_ ) then do.
                define variable errResponse as ConnectorResponse no-undo.
                assign errResponse                 = new ConnectorResponse()
                       errResponse:successRequest  = false
                       errResponse:successResponse = false
                       errResponse:successProcess  = false
                       errResponse:statusCode      = 0
                       errResponse:statusMessage   = err:GetMessage(1)
                       errResponse:destination     = ''.
                       
                message_:saveResponse( errResponse, false ).
                
            end.

            undo, throw err.
        end catch.

    end method.

end class.


 
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
using thl-lib.integration.messaging.core.*.
using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.Outbound.service.MessageExecutionService. 

    method public void executeOnline( message_       as Message      ,
                                      configuration as MessageConfig ).

        define variable connectorRequest  as ConnectorRequest  no-undo.
        define variable connectorResponse as ConnectorResponse no-undo.

        assign connectorRequest                 = new ConnectorRequest()
               connectorRequest:connectorType   = configuration:connectorType
               connectorRequest:methodType      = configuration:methodType
               connectorRequest:content         = message_:loadContent()
               connectorRequest:connectorConfig = new ConnectorConfig( configuration:parameterCode, configuration:routeParameterCode )
               connectorResponse                = new ConnectorService():execute(connectorRequest).

        message_:saveResponse( connectorResponse, configuration:historyEnabled ).

    end method.

end class.


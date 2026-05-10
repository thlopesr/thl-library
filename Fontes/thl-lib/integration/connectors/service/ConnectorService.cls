 
 /*------------------------------------------------------------------------
    File        : ConnectorService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.connectors.core.ConnectorResponse.
using thl-lib.integration.connectors.core.ConnectorRequest.
using thl-lib.integration.connectors.factory.ConnectorFactory.
using thl-lib.integration.connectors.types.IntegrationConnector.

class thl-lib.integration.connectors.service.ConnectorService.

    method public ConnectorResponse execute ( input request as ConnectorRequest ).

        define variable connector as IntegrationConnector no-undo.

        if not valid-object(request) then
            undo, throw new AppError('ConnectorRequest was not informed.', 17006).

        assign connector = new ConnectorFactory():createConnector( request:connectorType ).

        if not valid-object(connector) then
            undo, throw new AppError('Unable to resolve integration connector.', 17006).

        return connector:execute( request ).

    end method.

end class.

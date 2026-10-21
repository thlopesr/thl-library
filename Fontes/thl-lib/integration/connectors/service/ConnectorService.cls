 
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
using thl-lib.core.error.ThlError.
using thl-lib.logging.LogUtil.
using thl-lib.integration.connectors.core.ConnectorResponse.
using thl-lib.integration.connectors.core.ConnectorRequest.
using thl-lib.integration.connectors.factory.ConnectorFactory.
using thl-lib.integration.connectors.types.IntegrationConnector.

block-level on error undo, throw.

class thl-lib.integration.connectors.service.ConnectorService.

    method public ConnectorResponse execute ( input request as ConnectorRequest ).

        define variable connector as IntegrationConnector no-undo.
        define variable response  as ConnectorResponse    no-undo.

        if not valid-object(request) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'execute', 'requisicao de conector nao informada.' ).

        assign connector = new ConnectorFactory():createConnector( request:connectorType ).

        if not valid-object(connector) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'execute',
                substitute( 'conector nao resolvido para tipo &1.', request:connectorType ) ).

        assign response = connector:execute( request ).

        if not valid-object( response ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'execute',
                substitute( 'conector tipo &1 retornou resposta nula.', request:connectorType ) ).

        if not response:successResponse then
            LogUtil:write(
                substitute( 'ConnectorService: falha HTTP tipo=&1 status=&2 msg=&3',
                            request:connectorType, response:statusCode, response:statusMessage ),
                'ConnectorService' ).

        return response.

        catch e as Progress.Lang.Error:
            LogUtil:write( request,
                substitute( 'ConnectorService.execute: excecao tipo=&1 erro=&2',
                            request:connectorType, e:GetMessage(1) ),
                'ConnectorService' ).
            undo, throw e.
        end catch.

    end method.

end class.

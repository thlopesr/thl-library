/*------------------------------------------------------------------------
    File        : centroCusto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:41:22 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.integration.messaging.outbound.core.*.
using thl-lib.core.environment.EnvironmentResource.

block-level on error undo, throw.

class thl-extensions.integration.ninahub.messaging.outbound.message.ChamadoMessage inherits OutboundMessage.
    
    define private buffer b-embarque for embarque.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public ChamadoMessage ( objectName           as character ,
                                        applicationName      as character ,
                                        integrationOperation as character ,
                                        methodType           as integer   ,
                                        connectorType        as integer   ,
                                        integrationDirection as logical   ,
                                        executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor. 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override void appendPayloadObject( objectContext as OutboundObjectContext ).
    
        define variable payloadTemplate as JsonObject  no-undo.
        define variable template        as longchar    no-undo.
        define variable createDate      as datetime-tz no-undo.
        
        assign fix-codepage(template) = 'UTF-8'
               template           = new EnvironmentResource():getEnvironmentVariable('infoAberturaChamado')
               payloadTemplate    = cast( new ObjectModelParser():Parse(template), JsonObject)
               createDate         = now.

        if payloadTemplate:Has('descricao') then payloadTemplate:set('descricao', objectContext:getAdditionalDataContent()).
                                            else payloadTemplate:add('descricao', objectContext:getAdditionalDataContent()).
        
        assign payload = payloadTemplate.
        
    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-embarque no-lock
            where recid(b-embarque) = register
            no-error.

        if not available b-embarque then
            this-object:errorHandler:throwError( 'onLoadData', 'Embarque nao encontrado.' ).

        return ( 
            substitute(
                '&1#&2', 
                b-embarque.cdd-embarq  ,
                b-embarque.nr-embarque    
            ) 
        ).

    end method.

end class.

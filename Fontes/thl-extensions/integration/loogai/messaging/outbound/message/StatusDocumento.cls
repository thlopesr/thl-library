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
using thl-lib.util.file.FileUtil.
using thl-lib.integration.messaging.outbound.core.*.

block-level on error undo, throw.

class thl-extensions.integration.loogai.messaging.outbound.message.StatusDocumento inherits OutboundMessage.
    
    define private buffer b-docum-est for docum-est.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public StatusDocumento( objectName           as character ,
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
    
        this-object:initializeObjectPayload().
        
        cast( this-object:payload, JsonObject):add( 'chaveAcesso' , entry( 1, objectContext:additionalData:GetCharacter('content'), '#' ) ). 
        cast( this-object:payload, JsonObject):add( 'TipoMovto'   , entry( 2, objectContext:additionalData:GetCharacter('content'), '#' ) ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        return ''.
    end method.

end class.

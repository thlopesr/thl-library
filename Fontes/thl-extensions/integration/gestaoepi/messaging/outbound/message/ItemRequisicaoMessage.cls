/*------------------------------------------------------------------------
    File        : 
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : 
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.util.file.FileUtil.
using thl-lib.integration.messaging.outbound.core.*.

block-level on error undo, throw.

class thl-extensions.integration.gestaoepi.messaging.outbound.message.ItemRequisicaoMessage inherits OutboundMessage.
    
    define private buffer b-it-requisicao for it-requisicao.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public ItemRequisicaoMessage( objectName           as character ,
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
    
        define variable count as integer no-undo.
        
        define variable items as JsonArray  no-undo.
        define variable item  as JsonObject no-undo.
        
        this-object:initializeObjectPayload().
        
        cast( this-object:payload, JsonObject):add( 'numero_requisicao', b-it-requisicao.nr-requisicao ). 
        
        assign items = new JsonArray()
               item  = new JsonObject().
            
        item:Add('it_codigo'  , b-it-requisicao.it-codigo                            ).
        item:Add('status'     , objectContext:additionalData:GetCharacter('content') ).
        item:Add('qt_atendida', b-it-requisicao.qt-atendida                          ).
        
        items:add( item ).
        
        cast( this-object:payload, JsonObject ):add( 'itens', items ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-it-requisicao no-lock
            where recid(b-it-requisicao) = register
            no-error.

        if not available b-it-requisicao then
            this-object:errorHandler:throwError( 'onLoadData', 'Item da requisicao nao encontrada.' ).

        return string(b-it-requisicao.nr-requisicao).

    end method.

end class.

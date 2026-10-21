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

class thl-extensions.integration.mmcm.messaging.outbound.message.PedidoMessage inherits OutboundMessage.
    
    define private buffer b-nota-fiscal for nota-fiscal.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public PedidoMessage( objectName           as character ,
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
        
        define variable attachments as JsonArray  no-undo.
        define variable attachment  as JsonObject no-undo.
        
        this-object:initializeObjectPayload().
        
        cast( this-object:payload, JsonObject):add( 'token'            , '' ). 
        cast( this-object:payload, JsonObject):add( 'nota_fiscal'      , b-nota-fiscal.nr-nota-fis ).
        cast( this-object:payload, JsonObject):add( 'serie_nota_fiscal', b-nota-fiscal.serie       ).
        cast( this-object:payload, JsonObject):add( 'chave_acesso'     , b-nota-fiscal.cod-chave-aces-nf-eletro ).
        cast( this-object:payload, JsonObject):add( 'nf_base64'        , FileUtil:loadFileAsBase64( objectContext:additionalData:GetCharacter('file') ) ).
        
        assign attachments = new JsonArray().
        
        if objectContext:additionalData:Has('files') then do.
        
            do count = 1 to objectContext:additionalData:GetJsonArray('files'):Length.
                
                assign attachment = new JsonObject().
                
                attachment:Add('nome'  , objectContext:additionalData:GetJsonArray('files'):GetJsonObject(count):GetCharacter('file') ).
                attachment:Add('base64', FileUtil:loadFileAsBase64( objectContext:additionalData:GetJsonArray('files'):GetJsonObject(count):GetCharacter('file') ) ).
            
                attachments:add( attachment ).
                         
            end.
            
        end.
        
        cast( this-object:payload, JsonObject ):add( 'anexos', attachments ).

        this-object:setPathParameter('#Pedido#', b-nota-fiscal.nr-pedcli ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-nota-fiscal no-lock
            where recid(b-nota-fiscal) = register
            no-error.

        if not available b-nota-fiscal then
            this-object:errorHandler:throwError( 'onLoadData', 'Nota fiscal nao encontrada.' ).

        return ( 
            substitute(
                '&1#&2#&3', 
                b-nota-fiscal.cod-estabel,
                b-nota-fiscal.serie      ,
                b-nota-fiscal.nr-nota-fis    
            ) 
        ).

    end method.

end class.

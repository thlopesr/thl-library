 
 /*------------------------------------------------------------------------
    File        : Message
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:25:57 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.messaging.core.Message.
using thl-lib.integration.messaging.outbound.core.OutboundObjectContext.
using thl-lib.integration.connectors.core.ConnectorResponse.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.core.OutboundMessage abstract inherits Message.

    define protected property pathParameters as JsonArray no-undo get. private set.

    constructor public OutboundMessage ( objectName           as character ,
                                         applicationName      as character ,
                                         integrationOperation as character ,
                                         methodType           as integer   ,
                                         connectorType        as integer   ,
                                         integrationDirection as logical   ,
                                         executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor.
    
    method public void loadData( objectContext as OutboundObjectContext ).
        if not valid-object(objectContext) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadData', 'Contexto de objeto outbound nao informado.' ).
        
        assign this-object:referenceCode = if objectContext:recordId = ? then objectContext:referenceCode
                                                                         else onLoadData( objectContext:recordId )
               repository:referenceCode  = this-object:referenceCode.
    end method. 
    
    method public void appendPayloadObject( ).
        undo, throw new ThlError( this-object:GetClass():TypeName, 'appendPayloadObject', substitute( 'appendPayloadObject nao implementado para o objeto &1.', this-object:objectName ) ).
    end method.

    method public void appendPayloadObject( objectContext as OutboundObjectContext ).
        undo, throw new ThlError( this-object:GetClass():TypeName, 'appendPayloadObject', substitute( 'appendPayloadObject nao implementado para o objeto &1.', this-object:objectName ) ).
    end method. 
    
    method protected void setPathParameter( input parameterName  as character,
                                            input parameterValue as character ).

        define variable path as JsonObject no-undo.
        
        if not StringUtil:hasValue( parameterName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'setPathParameter', 'Nome do parametro de path nao informado.' ).
    
        if not valid-object(this-object:pathParameters) then
            assign this-object:pathParameters = new JsonArray().
    
        assign path = new JsonObject().
        
        path:Add('name' , parameterName ).
        path:Add('value', parameterValue).
        
        this-object:pathParameters:add(path).
    
    end method.
    
    method public JsonArray getPathParameters().

        if not valid-object(this-object:pathParameters) then
            assign this-object:pathParameters = new JsonArray().

        return this-object:pathParameters.

    end method.

    method public override void saveResponse( connectorResponse as ConnectorResponse,
                                              isIncremental     as logical          ).
        
        //envio com falha: o processamento de negocio nao chegou a ocorrer (nao aplicavel)
        if connectorResponse:successResponse then
            assign connectorResponse:successProcess = applyBusinessProcess( connectorResponse:content ).
        else
            assign connectorResponse:successProcess = ?.
        
        super:saveResponse( connectorResponse, isIncremental).
        
    end method.

    method protected logical parseBusinessProcess( input response as longchar ).
        return ?.
    end method.

    method public logical applyBusinessProcess( input response as longchar ).
        return this-object:parseBusinessProcess( response ).
    end method.
    
    method protected abstract character onLoadData ( register as recid ).

end class.
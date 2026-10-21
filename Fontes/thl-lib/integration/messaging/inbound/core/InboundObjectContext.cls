 
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

using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.core.InboundObjectContext.

    define public property payload         as JsonObject no-undo get. private set.
    define public property queryParameters as JsonObject no-undo get. private set.
    define public property pathParameters  as JsonArray  no-undo get. private set.
    define public property payloadText     as longchar   no-undo get. private set.
    define public property operation       as character  no-undo get. private set.
    define public property routePath       as character  no-undo get. private set.

    constructor public InboundObjectContext ( ).
        assign this-object:Payload         = new JsonObject()
               this-object:QueryParameters = new JsonObject()
               this-object:PathParameters  = new JsonArray().
    end constructor.

    method public void SetPayload ( Payload as JsonObject ).
        if valid-object ( Payload ) then
            assign this-object:Payload = Payload.
    end method.

    method public void SetQueryParameters ( queryParameters as JsonObject ).
        if valid-object ( queryParameters ) then
            assign this-object:QueryParameters = queryParameters.
    end method.

    method public void SetPathParameters  ( pathParameters as JsonArray ).
        if valid-object ( pathParameters ) then
            assign this-object:PathParameters = pathParameters.
    end method.
    
    method public void SetOperation  ( operation as character ).
        assign this-object:operation = operation.
    end method.
    
    method public void SetRoutePath  ( routePath as character ).
        assign this-object:routePath = routePath.
    end method.
    
    method public logical hasPathParameters().
        
        if valid-object ( this-object:PathParameters ) then
            return this-object:pathParameters:Length <> 0.
            
        return false.
        
    end method.
    
    method public logical hasPayload().
        return valid-object ( this-object:payload ).    
    end method.
    
    method public void setPayloadText().
        if hasPayload() then
            assign fix-codepage( payloadText ) = 'UTF-8'
                   this-object:payloadText     = payload:GetJsonText().
    end method.

    method public integer getQueryParamInt( paramName    as character,
                                            defaultValue as integer  ).
        return integer( this-object:getQueryParam( paramName,  string(defaultValue) ) ).
    end method.

    method public character getQueryParam   ( paramName    as character,
                                              defaultValue as character).
        if valid-object( this-object:queryParameters ) and
           this-object:queryParameters:Has( paramName ) then
            return this-object:queryParameters:GetJsonArray( paramName ):GetCharacter(1).
        return defaultValue.
    end method.

    //Data e hora da query string, somente no formato yyyy-MM-ddTHH:mm
    //(StringUtil:parseDateTime). Sem o parametro, vale o valor padrao informado
    //por quem chama - ex.: now ou add-interval( now, -24, 'hours' ).
    method public datetime getQueryParamDateTime( paramName    as character   ,
                                                  defaultValue as datetime-tz ).

        define variable defaultDateTime as datetime no-undo.

        //o padrao chega com fuso (now); os filtros comparam campos datetime, sem fuso
        assign defaultDateTime = defaultValue.

        return StringUtil:parseDateTime( this-object:getQueryParam( paramName, '' ), defaultDateTime ).

    end method.

end class.
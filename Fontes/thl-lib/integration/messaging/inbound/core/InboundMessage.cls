 
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
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.core.InboundMessage abstract inherits Message.

    define protected temp-table RowErrors no-undo
        field ErrorSequence    as integer
        field ErrorNumber      as integer
        field ErrorDescription as character
        field ErrorParameters  as character
        field ErrorType        as character
        field ErrorHelp        as character
        field ErrorSubType     as character.
   
    constructor public InboundMessage ( objectName           as character ,
                                        integrationOperation as character ,
                                        methodType           as integer   ,
                                        connectorType        as integer   ,
                                        integrationDirection as logical   ,
                                        executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor.
     
    method public void processInbound( input payload as JsonObject ).
        this-object:dispatchInbound( payload ).
    end method.

    method public void dispatchInbound( input payload as JsonObject ).

        case this-object:methodType.

            when MethodTypeEnum:POST:GetValue() then do.
                this-object:validate    ( payload ).
                this-object:methodpost  ( payload ).
            end.
            when MethodTypeEnum:PATCH:GetValue() or
            when MethodTypeEnum:PUT:GetValue()   then do. 
                this-object:validate    ( payload ).
                this-object:methodpatch ( payload ).
            end.
            when MethodTypeEnum:DELETE:GetValue() then  do. 
                this-object:validate    ( payload ).
                this-object:methoddelete( payload ).
            end.
            when MethodTypeEnum:GET:GetValue() then this-object:methodGet   ().
            
            otherwise
                undo, throw new AppError(
                    substitute(
                        'Inbound method &1 is not supported for object &2.',
                        this-object:methodType,
                        this-object:objectName
                    ),
                    17006
                ).

        end case.

    end method.

    method protected void methodPatch( input payload as JsonObject ).
        undo, throw new AppError( substitute( 'PATCH is not implemented for object &1.', this-object:objectName ), 17006 ).
    end method.

    method protected void methodPost( input payload as JsonObject ).
        undo, throw new AppError( substitute( 'POST is not implemented for object &1.', this-object:objectName ), 17006 ).
    end method.

    method protected void methodDelete( input payload as JsonObject ).
        undo, throw new AppError( substitute( 'DELETE is not implemented for object &1.', this-object:objectName ), 17006 ).
    end method.

    method protected void methodGet().
        undo, throw new AppError( substitute( 'GET is not implemented for object &1.', this-object:objectName ), 17006 ).
    end method.
    
    method protected void validateRequiredFields( payload         as JsonObject,
                                                  requiredFields  as character ).

        define variable fieldName as character no-undo.
        define variable fieldIdx  as integer   no-undo.
    
        if requiredFields = '' or
           requiredFields = ?  then
            return.
    
        do fieldIdx = 1 to num-entries( requiredFields ).
    
            assign fieldName = trim( entry( fieldIdx, requiredFields ) ).
    
            if not payload:Has( fieldName ) then
                this-object:errorHandler:throwError( 17006, substitute( 'Required field &1 was not informed.', fieldName ) ).
    
        end.

    end method.
    
    method protected void validatePayload( input payload as JsonObject ).
        if not valid-object( payload ) then
            undo, throw new AppError( 'Inbound JSON payload was not informed.', 17006 ).
    end method.
    
    method protected character getRequiredFields().
        return ''.
    end method.
    
    method protected void validate( payload as JsonObject ).
        this-object:validatePayload       ( payload ).
        this-object:validateRequiredFields( payload, getRequiredFields() ).
    end method.
    
    method protected void appendPayloadObject( input payloadObject as JsonObject ).
    
        if not valid-object( payloadObject ) then
            undo, throw new AppError(
                'Payload object was not informed.',
                17006
            ).
            
        if not type-of( this-object:payload, JsonArray ) then
            undo, throw new AppError(
                'Current payload is not a JsonArray, use initializeArrayPayload.',
                17006
            ).
    
        cast( this-object:payload, JsonArray ):Add( payloadObject ).
    
    end method.
    
        
    method public void saveInboundSuccess().
    
        repository:saveResultMessage   ( this-object:objectName, true,  true,  true, 200, 'Mensagem processada com sucesso.' ).
        repository:createHistoryMessage( ).

    end method.
    
    method public void saveInboundError( input errorObject as Progress.Lang.Error ).
        
        repository:loadMessage      ().
        repository:saveResultMessage(
            this-object:objectName,
            true ,
            false,
            false,
            this-object:errorHandler:getErrorStatusCode(errorObject),
            this-object:errorHandler:getErrorMessage(errorObject)
        ).
        this-object:saveContentByType( 
            DirectionEnum:OUTBOUND:GetValue(), 
            this-object:errorHandler:getErrorJsonText(errorObject)
        ).
        repository:createHistoryMessage ( ).
    
    end method.
    
    method protected void addRowErrorsToErrorHandler( step as character ).

        for each RowErrors.
            this-object:errorHandler:addError( RowErrors.ErrorNumber                    ,
                                               step + ' - ' + RowErrors.ErrorDescription).
        end.
    
    end method.
    
    method protected void throwRowErrorsIfAny().
        this-object:addRowErrorsToErrorHandler('').
        this-object:errorHandler:throwIfHasErrors().
    end method.
    
    method protected void throwRowErrorsIfAny(step as character).
        this-object:addRowErrorsToErrorHandler(step).
        this-object:errorHandler:throwIfHasErrors().
    end method.

end class.
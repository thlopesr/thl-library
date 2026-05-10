 
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
using thl-lib.integration.messaging.repository.MessageRepository.
using thl-lib.integration.connectors.core.ConnectorResponse.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.core.error.ErrorHandler.

block-level on error undo, throw.

class thl-lib.integration.messaging.core.Message abstract.  

    define protected property payload              as JsonConstruct     no-undo get. set. 
    define protected property repository           as MessageRepository no-undo get. private   set. 
    define protected property objectName           as character         no-undo get. private   set.
    define protected property integrationOperation as character         no-undo get. private   set.
    define protected property methodType           as integer           no-undo get. private   set. 
    define protected property connectorType        as integer           no-undo get. private   set.
    define protected property integrationDirection as logical           no-undo get. private   set.
    define protected property executionMode        as integer           no-undo get. private   set.
    define protected property referenceCode        as character         no-undo get. protected set.
    define protected property errorHandler         as ErrorHandler      no-undo get. private   set.   
     
    constructor public Message ( objectName           as character ,
                                 integrationOperation as character ,
                                 methodType           as integer   ,
                                 connectorType        as integer   ,
                                 integrationDirection as logical   ,
                                 executionMode        as integer   ).
                                 
        assign this-object:objectName           = objectName
               this-object:integrationOperation = integrationOperation
               this-object:methodType           = methodType
               this-object:connectorType        = connectorType
               this-object:integrationDirection = integrationDirection
               this-object:executionMode        = executionMode
               this-object:repository           = new MessageRepository()
               this-object:errorHandler         = new ErrorHandler().
               .
               
    end constructor. 

    method public void appendItem().
        repository:createItemMessage(). 
    end method.
    
    method public void createMessage().
        repository:generateMessageCode ( ).
        repository:createMessage       ( this-object:objectName          , 
                                         this-object:integrationOperation,
                                         this-object:methodType          ,
                                         this-object:connectorType       ,
                                         this-object:integrationDirection,
                                         this-object:executionMode       ).
    end method. 
    
    method public logical hasReusableContentRequestMessage().
        repository:loadMessageContent( DirectionEnum:OUTBOUND:GetValue() ).
        return repository:hasExistingMessageContentForObject().
    end method.

    method public logical hasReusableMessage().
        repository:loadMessageItemByReference( this-object:objectName ). //
        return repository:hasExistingMessageItemForReference().
    end method.

    method public void loadByMessageCode( messageCode   as character).
        repository:messageCode = messageCode.
        reuseMessage().
    end method. 
        
    method public void loadByMessageItem().
        repository:loadMessageCodeFromItem().
        reuseMessage().
    end method. 
    
    method public longchar loadContent().
        return repository:loadContentMessage().
        //return cast( new ObjectModelParser():ParseFile( search('C:\Users\Lopes\Google\Workspace\THL-Libray\Utils\example\exemplo.json') ), JsonArray):GetJsonText().
    end method. 
    
    method protected void loadPersistedPayload().
        
        define variable content  as longchar no-undo.
    
        assign fix-codepage(content) = 'UTF-8' 
               content               = repository:loadContentMessage()
               payload               = new ObjectModelParser():Parse(content).

    end method.
    
    method protected void loadPersistedState().
        repository:loadMessage       ().
        repository:loadMessageContent( DirectionEnum:OUTBOUND:GetValue() ).
    end method.
    
    method protected void prepareResponseHistory ( isIncremental as logical ).          
        if isIncremental then 
            repository:createHistoryMessage().
    end method.
    
    method public void reuseMessage().
        this-object:loadPersistedState  ().
        this-object:loadPersistedPayload().
    end method.
    
    method public void saveContent().
        this-object:saveContentByType( DirectionEnum:OUTBOUND:GetValue(),
                                       getPayloadContentText()          ).
    end method.  
    
    method public void saveContentByType( input typeContent as int64    ,
                                          input content     as longchar ).

        repository:createMessageContent( typeContent ).
        repository:saveContentMessage  ( content     ).

    end method.
    
    method public void saveResponse( connectorResponse as ConnectorResponse,
                                     isIncremental     as logical          ).

        this-object:saveResponseExecutionResult( connectorResponse ). 
        this-object:prepareResponseHistory     ( isIncremental     ).
        this-object:saveResponseContent        ( connectorResponse:content ).

    end method.
    
    method protected void saveResponseContent(responseContent as longchar).
        repository:loadMessageContent( DirectionEnum:INBOUND:GetValue() ).

        if not repository:hasExistingMessageContentForObject() then
            repository:createMessageContent( DirectionEnum:INBOUND:GetValue() ).

        repository:saveContentMessage(responseContent).
    end method.

    method protected void saveResponseExecutionResult( connectorResponse as ConnectorResponse ).
        repository:saveResultMessage( connectorResponse:destination     ,
                                      connectorResponse:successRequest  ,
                                      connectorResponse:successResponse ,
                                      connectorResponse:successProcess  ,
                                      connectorResponse:statusCode      ,
                                      connectorResponse:statusMessage   ).
    end method.
    
    method protected void initializeArrayPayload().

        if valid-object( this-object:payload ) then
            delete object this-object:payload.
    
        assign this-object:payload = new JsonArray().
    
    end method.
    
    method protected void initializeObjectPayload().

        if valid-object( this-object:payload ) then
            delete object this-object:payload.
    
        assign this-object:payload = new JsonObject().
    
    end method.
    
    method public JsonConstruct getPayloadContent().

        if not valid-object( this-object:payload ) then
            return ?.
    
        return this-object:payload.
    
    end method.
    
    method public longchar getPayloadContentText().
    
        define variable payloadContent as longchar no-undo.
    
        assign fix-codepage( payloadContent ) = 'UTF-8'.
    
        if not valid-object( this-object:payload ) then
            return ''.
    
        if type-of(payload, JsonArray) then
            return cast(payload,  JsonArray):GetJsonText().
            
        if type-of(payload, JsonObject) then 
            return cast(payload, JsonObject):GetJsonText().
    
        return ?.
    
    end method.
    
    method public void setSuccessPayload( statusCode    as integer  ,
                                          statusMessage as character).
    
        define variable response as JsonObject no-undo.
    
        assign response = new JsonObject().
    
        response:Add( 'success', true ).
        response:Add( 'code'   , statusCode ).
        response:Add( 'message', statusMessage ).
    
        if valid-object( this-object:payload ) then
            delete object this-object:payload.
    
        assign this-object:payload = response.
    
    end method.
    
    method protected void appendMessageItemByReference( register as recid ).
    
        assign this-object:referenceCode = onLoadData( register )
               repository:referenceCode  = this-object:referenceCode.
    
        this-object:appendItem().
    
    end method.
    
    method public abstract character onLoadData         ( register as recid  ).
             
end class.
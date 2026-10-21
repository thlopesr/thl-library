 
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
using thl-lib.integration.messaging.enum.ContentStorageEnum.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.enum.ExecutionMode.
using thl-lib.core.error.ErrorHandler.

block-level on error undo, throw.

class thl-lib.integration.messaging.core.Message abstract.  

    define protected property payload               as JsonConstruct     no-undo get. set. 
    define protected property repository            as MessageRepository no-undo get. private   set. 
    define public    property objectName            as character         no-undo get. private   set.
    define public    property applicationName       as character         no-undo get. private   set.
    define protected property integrationOperation  as character         no-undo get. private   set.
    define protected property methodType            as integer           no-undo get. private   set. 
    define protected property connectorType         as integer           no-undo get. private   set.
    define protected property integrationDirection  as logical           no-undo get. private   set.
    define public    property executionMode_        as integer           no-undo get. private   set.
    define protected property referenceCode         as character         no-undo get. protected set.
    define protected property externalReferenceCode as character         no-undo get. protected set.
    define protected property errorHandler          as ErrorHandler      no-undo get. private   set.   

    //Gravacao do conteudo (thl-objeto-parametro.tipo-grava-conteudo, ContentStorageEnum).
    //A MessageFactory informa depois de criar a mensagem; sem isso vale Sempre.
    define protected property contentStorage        as integer           no-undo get. private   set.

    define private variable contentFailed       as logical  no-undo.
    define private variable hasDeferredContent  as logical  no-undo.
    define private variable deferredContentType as int64    no-undo.
    define private variable deferredContent     as longchar no-undo.
     
    constructor public Message ( objectName           as character ,
                                 applicationName      as character ,
                                 integrationOperation as character ,
                                 methodType           as integer   ,
                                 connectorType        as integer   ,
                                 integrationDirection as logical   ,
                                 executionMode_        as integer   ).
        // Invariante: repository e errorHandler sao criados aqui e devem permanecer validos durante todo o ciclo de vida da mensagem.
        assign this-object:objectName           = objectName
               this-object:applicationName      = applicationName
               this-object:integrationOperation = integrationOperation
               this-object:methodType           = methodType
               this-object:connectorType        = connectorType
               this-object:integrationDirection = integrationDirection
               this-object:executionMode_        = executionMode_
               this-object:contentStorage       = ContentStorageEnum:ALWAYS:GetValue()
               this-object:repository           = new MessageRepository()
               this-object:errorHandler         = new ErrorHandler( this-object:GetClass():TypeName ).
               .

    end constructor.

    method public void appendItem().
        assign repository:externalReferenceCode  = this-object:externalReferenceCode
               repository:referenceCode          = this-object:referenceCode.
        repository:createItemMessage(). 
    end method.
    
    method public void createMessage().
        repository:generateMessageCode ( ).
        repository:createMessage       ( this-object:objectName           ,
                                         this-object:applicationName      ,
                                         this-object:integrationOperation ,
                                         this-object:methodType           ,
                                         this-object:connectorType        ,
                                         this-object:integrationDirection ,
                                         this-object:executionMode_        ).
    end method. 
    
    method public logical hasReusableContentRequestMessage().
        repository:loadMessageContent( DirectionEnum:OUTBOUND:GetValue() ).
        return repository:hasExistingMessageContentForObject().
    end method.

    method public logical hasReusableMessage().
        repository:loadMessageItemByReference( this-object:objectName     ,
                                               this-object:applicationName ).
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
    end method. 
    
    method protected void loadPersistedPayload().
        
        define variable content  as longchar no-undo.
    
        assign fix-codepage(content) = 'UTF-8' 
               content               = repository:loadContentMessage()
               payload               = new ObjectModelParser():Parse(content)
               .
    
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

        if this-object:shouldStoreContent( typeContent ) then do.
            this-object:storeContent( typeContent, content ).
            return.
        end.

        //somente em erro: a requisicao fica em memoria e so vai para o banco se a mensagem falhar
        if this-object:contentStorage = ContentStorageEnum:ERROR_ONLY:GetValue() and
           this-object:isRequestContent( typeContent )                           then
            assign deferredContentType = typeContent
                   deferredContent     = content
                   hasDeferredContent  = true.

    end method.

    //Informada pela MessageFactory; valor fora do dominio vale Sempre
    method public void setContentStorage( input contentStorage as integer ).

        if contentStorage = ContentStorageEnum:ERROR_ONLY:GetValue() or
           contentStorage = ContentStorageEnum:NEVER:GetValue()      then
            assign this-object:contentStorage = contentStorage.
        else
            assign this-object:contentStorage = ContentStorageEnum:ALWAYS:GetValue().

    end method.

    //A mensagem falhou: na opcao somente em erro o conteudo passa a ser gravado,
    //inclusive a requisicao que estava em memoria
    method public void markFailed().

        assign contentFailed = true.

        if hasDeferredContent then do.
            this-object:storeContent( deferredContentType, deferredContent ).
            assign hasDeferredContent = false
                   deferredContent    = ''.
        end.

    end method.

    method protected logical shouldStoreContent( input typeContent as int64 ).

        //requisicao do outbound (reenvio) e do inbound fora do online (o RPW le
        //para processar): gravada sempre, qualquer que seja a opcao
        if this-object:isRequestContent( typeContent ) and
           ( this-object:integrationDirection or
             this-object:executionMode_ <> ExecutionMode:ONLINE:GetValue()  ) then
            return true.

        case this-object:contentStorage.
            when ContentStorageEnum:NEVER:GetValue()      then return false.
            when ContentStorageEnum:ERROR_ONLY:GetValue() then return contentFailed.
        end case.

        return true.

    end method.

    //No outbound a requisicao e o conteudo de saida; no inbound, o de entrada
    method private logical isRequestContent( input typeContent as int64 ).

        if this-object:integrationDirection then
            return typeContent = DirectionEnum:OUTBOUND:GetValue().

        return typeContent = DirectionEnum:INBOUND:GetValue().

    end method.

    method private void storeContent( input typeContent as int64    ,
                                      input content     as longchar ).

        repository:createMessageContent( typeContent ).
        repository:saveContentMessage  ( content     ).

    end method.
    
    method public void saveResponse( connectorResponse as ConnectorResponse,
                                     isIncremental     as logical          ).

        this-object:saveResponseExecutionResult( connectorResponse ). 
        this-object:prepareResponseHistory     ( isIncremental     ).

        if connectorResponse:successRequest  = false or
           connectorResponse:successResponse = false or
           connectorResponse:successProcess  = false then
            this-object:markFailed().

        this-object:saveResponseContent        ( connectorResponse:content ).

    end method.
    
    //Agendamento aceito (RPW ainda nao executou): situacao geral volta a pendente
    method public void markPending().
        repository:markMessagePending().
    end method.

    method protected void saveResponseContent(responseContent as longchar).
        repository:loadMessageContent( DirectionEnum:INBOUND:GetValue() ).

        //sem gravar: limpa o retorno de uma tentativa anterior, para nao ficar
        //conteudo de outra execucao junto de um resultado novo
        if not this-object:shouldStoreContent( DirectionEnum:INBOUND:GetValue() ) then do.
            if repository:hasExistingMessageContentForObject() then
                repository:saveContentMessage( '' ).
            return.
        end.

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

    method public character getMessageCode().
        return repository:messageCode.
    end method.

end class.
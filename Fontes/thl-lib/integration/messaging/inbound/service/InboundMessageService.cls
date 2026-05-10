 
 /*------------------------------------------------------------------------
    File        : InboundMessageService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed Apr 29 17:28:21 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.factory.*.
using thl-lib.integration.messaging.repository.MessageConfigLoader.
using thl-lib.integration.messaging.service.*.
using thl-lib.integration.messaging.strategy.*.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.inbound.core.*.

using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.service.InboundMessageService.

    define public    property configuration  as MessageConfig  no-undo get. set.
    define protected property inboundMessage as InboundMessage no-undo get. protected set.

    constructor public InboundMessageService( objectName as character,
                                              methodType as integer  ).
                                              
        assign configuration  = new MessageConfigLoader():load( objectName, methodType )
               inboundMessage = cast( new MessageFactory( configuration ):getMessage(), InboundMessage ).
       
        if not valid-object( inboundMessage ) then
            undo, throw new AppError( 'Inbound message was not initialized.', 17006 ).
            
        if not type-of( inboundMessage, InboundMessage ) then
            undo, throw new AppError(
                substitute(
                    'Message class for object &1 is not an inbound message.',
                    configuration:objectName
                ),
                17006
            ).
               
    end constructor.

    method public JsonConstruct receive( payload as JsonObject ).
        
        // Etapa 1 - criar thl-mensagem
        this-object:registerMessage().
    
        // Etapa 2 - salvar conteúdo recebido, se existir
        if configuration:methodType <> MethodTypeEnum:GET:GetValue() then
            this-object:registerContent( payload ).
    
        // Etapa 3 - processar
        this-object:process( payload ).
    
        // Etapa 4 - se o objeto não montou payload, monta resposta padrão
        if not valid-object( inboundMessage:getPayloadContent() ) then do.
            inboundMessage:setSuccessPayload(
                200,
                'Mensagem processada com sucesso.'
            ).
        end.
        // Etapa 5 - salva conteúdo devolvido
        inboundMessage:saveContent().
    
        // Etapa 6 - atualiza status
        inboundMessage:saveInboundSuccess().
    
        return inboundMessage:getPayloadContent().
        
        catch errorObject as Error.
        
            if valid-object( inboundMessage ) then
                inboundMessage:saveInboundError( errorObject ).
            
            undo, throw errorObject.
            
        end catch.
        
    end method.

    method private void registerMessage().
        inboundMessage:createMessage().
    end method.
    
    method private void registerContent( payload as JsonObject ).
        
        define variable payloadContent as longchar no-undo.
        
        assign fix-codepage( payloadContent ) = 'UTF-8'
               payloadContent                 = payload:GetJsonText().

        inboundMessage:saveContentByType( DirectionEnum:INBOUND:GetValue(), payloadContent ).
        
    end method.

    method private void process( payload  as JsonObject ). 
        inboundMessage:processInbound( payload ).
    end method.

end class.
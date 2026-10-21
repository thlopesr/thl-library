
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

using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.
using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.factory.*.
using thl-lib.integration.messaging.inbound.repository.InboundConfigLoader.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.enum.ExecutionMode.
using thl-lib.integration.messaging.inbound.core.*.
using thl-lib.integration.messaging.inbound.service.InboundSchedulingService.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.service.InboundMessageService.

    define private   property configuration  as MessageConfig  no-undo get. private set.
    define protected property inboundMessage as InboundMessage no-undo get. protected set.

    constructor public InboundMessageService( applicationName as character,
                                              objectName      as character,
                                              methodType      as integer  ,
                                              operation       as character).

        define variable inboundConfiguration as InboundMessageConfig no-undo.

        assign inboundConfiguration = new InboundConfigLoader():load( applicationName, objectName, methodType, operation )
               configuration        = inboundConfiguration
               inboundMessage       = cast( new MessageFactory( configuration ):getMessage(), InboundMessage ).

        if not valid-object( inboundMessage ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Mensagem inbound nao foi inicializada.' ).

        if not type-of( inboundMessage, InboundMessage ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Classe de mensagem para objeto &1 nao e uma mensagem inbound.', configuration:objectName ) ).

        //classes de orquestracao e de service do cadastro do objeto
        inboundMessage:setProcessing( inboundConfiguration:processorClass, inboundConfiguration:serviceClass ).

        //contrato do payload cadastrado na operacao (campos obrigatorios e chave externa)
        inboundMessage:setContract( inboundConfiguration:requiredFields, inboundConfiguration:externalReferenceFields ).

    end constructor.

    constructor public InboundMessageService( configuration_  as MessageConfig  ,
                                              inboundMessage_ as InboundMessage ).

        if not valid-object( configuration_ ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Configuracao nao informada.' ).

        if not valid-object( inboundMessage_ ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'InboundMessage nao informado.' ).

        if not type-of( inboundMessage_, InboundMessage ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Mensagem para objeto &1 nao e InboundMessage.', configuration_:objectName ) ).

        assign configuration  = configuration_
               inboundMessage = inboundMessage_.

        if type-of( configuration_, InboundMessageConfig ) then do.
            inboundMessage:setProcessing( cast( configuration_, InboundMessageConfig ):processorClass,
                                          cast( configuration_, InboundMessageConfig ):serviceClass   ).
            inboundMessage:setContract  ( cast( configuration_, InboundMessageConfig ):requiredFields,
                                          cast( configuration_, InboundMessageConfig ):externalReferenceFields ).
        end.

    end constructor.

    method public JsonConstruct receive( context as InboundObjectContext ).

        this-object:accept( context ).

        if configuration:executionModeValue = ExecutionMode:SCHEDULE then
            return this-object:scheduleProcessing().

        return this-object:processOnline( context ).

        catch errorObject as Error.

            if valid-object( inboundMessage ) then
                inboundMessage:saveInboundError( context:routePath, errorObject ).

            undo, throw errorObject.

        end catch.

    end method.

    method public JsonConstruct processScheduled( messageCode as character ).

        inboundMessage:restoreForScheduledProcessing( messageCode ).

        define variable context as InboundObjectContext no-undo.

        assign context = new InboundObjectContext().
        context:SetPayload  ( cast( inboundMessage:getPayloadContent(), JsonObject ) ).
        context:SetOperation( configuration:integrationOperation ).

        this-object:process( context ).
        return this-object:finalize( 'RPW' ).

        catch errorObject as Error.

            if valid-object( inboundMessage ) then
                inboundMessage:saveInboundError( 'RPW', errorObject ).

            undo, throw errorObject.

        end catch.

    end method.

    method private void accept( context as InboundObjectContext ).
        this-object:registerMessage().
        this-object:registerContent( context:payloadText ).
    end method.

    method private JsonConstruct processOnline( context as InboundObjectContext ).
        this-object:process( context ).
        return this-object:finalize( context:routePath ).
    end method.

    method private JsonConstruct finalize( routePath as character ).
        if not valid-object( inboundMessage:getPayloadContent() ) then do.
            inboundMessage:setSuccessPayload(
                200,
                'Mensagem processada com sucesso.'
            ).
        end.
        inboundMessage:saveContent().
        inboundMessage:saveInboundSuccess( routePath ).
        return inboundMessage:getPayloadContent().
    end method.

    method private JsonConstruct scheduleProcessing().
        return new InboundSchedulingService():schedule( inboundMessage, configuration ).
    end method.

    method private void registerMessage().
        inboundMessage:createMessage().
    end method.

    method private void registerContent( payloadContent as longchar ).
        inboundMessage:saveContentByType( DirectionEnum:INBOUND:GetValue(), payloadContent ).
    end method.

    method private void process( context as InboundObjectContext ).
        inboundMessage:processInbound( context ).
    end method.

end class.

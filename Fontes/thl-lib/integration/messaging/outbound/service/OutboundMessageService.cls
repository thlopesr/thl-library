
 
 /*------------------------------------------------------------------------
    File        : MessageService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.logging.LogUtil.

using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.

using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.factory.*.
using thl-lib.integration.messaging.enum.ExecutionMode.
using thl-lib.integration.messaging.outbound.repository.OutboundConfigLoader.
using thl-lib.integration.messaging.outbound.Strategy.*.
using thl-lib.integration.messaging.outbound.service.*.
using thl-lib.integration.messaging.outbound.core.*.

class thl-lib.integration.messaging.outbound.service.OutboundMessageService.

    define private   property configuration      as MessageConfig            no-undo get. private set.
    define protected property messageFactory     as MessageFactory           no-undo get. protected set.
    define protected property structureStrategy  as MessageStructureStrategy no-undo get. protected set.
    define protected property connectorResponse  as ConnectorResponse        no-undo get. protected set.
    define protected property buildStarted       as logical                  no-undo get. protected set.
    define protected property messageFinalized   as logical                  no-undo get. protected set.
    define protected property restoredForRetry   as logical                  no-undo get. protected set.
    
    constructor public OutboundMessageService( applicationName      as character,
                                               objectName           as character,
                                               integrationOperation as character).

        assign configuration = new OutboundConfigLoader():load( '*', applicationName, objectName, integrationOperation ).

        if not valid-object( configuration ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Configuracao nao encontrada para obj=&1 op=&2.', objectName, integrationOperation ) ).

        assign messageFactory = new MessageFactory( configuration ).

        if not valid-object( messageFactory ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'MessageFactory nao foi inicializado.' ).

        if not type-of( messageFactory:getMessage(), OutboundMessage ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Mensagem nao e OutboundMessage.' ).

    end constructor.

    method public void beginBuild().
        assign structureStrategy = messageFactory:createStructureStrategy().

        if not valid-object(structureStrategy) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'beginBuild', 'Estrategia de estrutura nao pode ser criada.' ).

        assign buildStarted      = true
               messageFinalized  = false
               restoredForRetry  = false.
        structureStrategy:buildMessage().
    end method.

    method public void addObject( register as recid ).
        this-object:addObject( new OutboundObjectContext( register ) ).
    end method.
    
    method public void addObject( objectContext as OutboundObjectContext ).
        this-object:ensureBuildStarted().
        structureStrategy:addObject( objectContext ).
    end method.

    method public void finishBuild().
        this-object:ensureBuildStarted().
        structureStrategy:finishMessage().
        messageFinalized = true.
    end method.

    method public void loadForReprocess(messageCode as character).
        messageFactory:restoreMessage(messageCode).
        
        if not valid-object(messageFactory:getMessage()) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadForReprocess',
                substitute( 'Mensagem &1 nao encontrada ou nao pode ser restaurada.', messageCode ), 17009 ).

        assign buildStarted     = false
               messageFinalized = true
               restoredForRetry = true.
               
    end method.

    method public logical reprocess(messageCode as character).
        this-object:loadForReprocess(messageCode).

        if messageFactory:getMessage():executionMode_ = ExecutionMode:SCHEDULE:getvalue() then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'reprocess',
                substitute( 'Mensagem &1 esta agendada via RPW. Cancele o job antes de reprocessar manualmente.', messageCode ) ).

        return this-object:process(ExecutionMode:ONLINE).
    end method.

    method public logical process().
        return this-object:process(configuration:executionModeValue).
    end method.
    
    method public logical process( executionModeValue as ExecutionMode ).

        this-object:ensureReadyForProcessing().

        assign connectorResponse = ?.

        case executionModeValue.
            when ExecutionMode:ONLINE   then assign connectorResponse = this-object:processOnline().
            when ExecutionMode:SCHEDULE then assign connectorResponse = this-object:scheduleProcessing().
            when ExecutionMode:BATCH    then return true. //Nao havera acao
            otherwise
                undo, throw new ThlError( this-object:GetClass():TypeName, 'process', substitute( 'Modo de execucao &1 invalido.', executionModeValue ) ).
        end case.

        return this-object:evaluateResponse( connectorResponse ).

        catch e as Progress.Lang.Error.
            
            if not valid-object( connectorResponse ) then do:
                define variable errResponse as ConnectorResponse no-undo.
                assign errResponse                 = new ConnectorResponse()
                       errResponse:successRequest  = false
                       errResponse:successResponse = false
                       errResponse:successProcess  = false
                       errResponse:statusCode      = 0
                       errResponse:statusMessage   = e:GetMessage(1)
                       errResponse:destination     = ''.

                if valid-object( messageFactory ) and valid-object( messageFactory:getMessage() ) then
                    messageFactory:getMessage():saveResponse( errResponse, false ).
            end.

            //LogUtil:write(
            //    substitute( 'OutboundMessageService: Erro em process - obj=&1 - erro=&2',
            //                configuration:objectName, e:GetMessage(1) ), 'OutboundMessageService' ).

            undo, throw e.
        end catch.

    end method.

    method private logical evaluateResponse( input response as ConnectorResponse ).
        if not valid-object(response) then
            return false.
        return response:successResponse.
    end method.
    
    method public ConnectorResponse getLastConnectorResponse().
        if not valid-object(connectorResponse) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'getLastConnectorResponse', 'connectorResponse invalido.' ).
        
        return connectorResponse.
    end method.

    method protected ConnectorResponse processOnline().
        return new MessageExecutionService():executeOnline( messageFactory:getMessage(), configuration ).
    end method.

    method protected ConnectorResponse scheduleProcessing().
        return new SchedulingService():schedule( messageFactory:getMessage(),
                                                 configuration              ).
    end method.

    method protected void ensureBuildStarted().
        if not buildStarted then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureBuildStarted', 'Build da mensagem nao foi iniciado.' ).
    end method.

    method protected void ensureReadyForProcessing().

        if not messageFinalized and not restoredForRetry then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureReadyForProcessing', 'Mensagem nao esta pronta para processamento.' ).

        if not valid-object(messageFactory) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureReadyForProcessing', 'MessageFactory nao foi inicializado.' ).

        if not valid-object(messageFactory:getMessage() ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureReadyForProcessing', 'Mensagem de integracao nao foi criada ou restaurada.', 17007 ).
            
    end method.

end class.


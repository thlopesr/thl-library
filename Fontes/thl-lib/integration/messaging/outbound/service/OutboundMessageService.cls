
 
 /*------------------------------------------------------------------------
    File        : MessageService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.factory.*.

using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.service.*.
using thl-lib.integration.messaging.repository.MessageConfigLoader.
using thl-lib.integration.messaging.repository.MessageConfigLoader.
using thl-lib.integration.messaging.outbound.Strategy.*.
using thl-lib.integration.messaging.outbound.service.*.

using thl-lib.integration.messaging.enum.ExecutionMode.


class thl-lib.integration.messaging.outbound.service.OutboundMessageService.

    define public    property configuration      as MessageConfig            no-undo get. set.
    define protected property messageFactory     as MessageFactory           no-undo get. protected set.
    define protected property structureStrategy  as MessageStructureStrategy no-undo get. protected set.
    define protected property buildStarted       as logical                  no-undo get. protected set.
    define protected property messageFinalized   as logical                  no-undo get. protected set.
    define protected property restoredForRetry   as logical                  no-undo get. protected set.
    
    constructor public OutboundMessageService( objectName           as character,
                                               integrationOperation as character  ).
        assign configuration  = new MessageConfigLoader():load( '*', objectName, integrationOperation )
               messageFactory = new MessageFactory( configuration ).
    end constructor.

    method public void beginBuild().
        assign structureStrategy = messageFactory:createStructureStrategy()
               buildStarted      = true
               messageFinalized  = false
               restoredForRetry  = false.
        structureStrategy:buildMessage().
    end method.

    method public void addObject(register as recid).
        this-object:ensureBuildStarted().
        structureStrategy:addObject(register).
    end method.

    method public void finishBuild().
        this-object:ensureBuildStarted().
        structureStrategy:finishMessage().
        messageFinalized = true.
    end method.

    method public void loadForReprocess(messageCode as character).
        messageFactory:restoreMessage(messageCode).
        
        if not valid-object(messageFactory:getMessage()) then
            undo, throw new AppError( substitute('Message &1 was not found or could not be restored.', messageCode ), 17009 ).

        assign buildStarted     = false
               messageFinalized = true
               restoredForRetry = true.
               
    end method.

    method public void reprocess(messageCode as character).
        this-object:loadForReprocess(messageCode).
        this-object:processOnline().
    end method.

    method public void process().
        this-object:ensureReadyForProcessing().

        case configuration:executionMode.
            when ExecutionMode:ONLINE:GetValue()   then this-object:processOnline().
            when ExecutionMode:SCHEDULE:GetValue() then this-object:scheduleProcessing().
            when ExecutionMode:BATCH:GetValue()    then return. //Nao havera acao
            otherwise
                undo, throw new AppError( substitute('Execution mode &1 is invalid.', configuration:executionMode), 17006).
        end case.
    end method.

    method protected void processOnline().
        new MessageExecutionService():executeOnline( messageFactory:getMessage(),
                                                     configuration              ).
    end method.

    method protected void scheduleProcessing().
        new SchedulingService():schedule( messageFactory:getMessage() ,
                                          configuration               ).
    end method.

    method protected void ensureBuildStarted().
        if not buildStarted then
            undo, throw new AppError('Message build has not been started.', 17006).
    end method.

    method protected void ensureReadyForProcessing().
    
        if not messageFinalized and not restoredForRetry then
            undo, throw new AppError('Message is not ready for processing.', 17006).
            
        if not valid-object(messageFactory) then
            undo, throw new AppError('Message factory has not been initialized.', 17006).

        if not valid-object(messageFactory:getMessage() ) then
            undo, throw new AppError('Integration message has not been created or restored.', 17007).
            
    end method.

end class.


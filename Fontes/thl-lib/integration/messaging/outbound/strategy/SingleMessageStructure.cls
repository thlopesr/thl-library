 
 /*------------------------------------------------------------------------
    File        : SingleMessageStructure
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.messaging.outbound.strategy.MessageStructureStrategy.
using thl-lib.integration.messaging.outbound.core.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.strategy.SingleMessageStructure inherits MessageStructureStrategy.  

    constructor public SingleMessageStructure( outboundMessage as OutboundMessage ).
        super( outboundMessage ).
    end constructor.

    method public override void buildMessage(  ). 
        //No-op by design. 
        //In single mode, structure resolution happens during addObject().
    end method. 

    method public override void addObject( objectContext as OutboundObjectContext ).

        outboundMessage:loadData( objectContext ).
        
        /*if outboundMessage:hasReusableMessage() then
            outboundMessage:loadByMessageItem().
        else */
            this-object:createNewMessageStructure( objectContext ).

    end method.
    
    method private void createNewMessageStructure( objectContext as OutboundObjectContext ).

        outboundMessage:createMessage().
        if objectContext:hasAdditionalData() then
            outboundMessage:appendPayloadObject( objectContext ).
        else
            outboundMessage:appendPayloadObject().
        outboundMessage:appendItem   ().
        
    end method.
    
    method public override void finishMessage().
        if not outboundMessage:hasReusableContentRequestMessage() then 
            outboundMessage:saveContent().
    end method. 

end class.
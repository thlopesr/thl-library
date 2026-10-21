 
 /*------------------------------------------------------------------------
    File        : MultipleMessageStructure
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.messaging.outbound.strategy.*.
using thl-lib.integration.messaging.outbound.core.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.strategy.MultipleMessageStructure inherits MessageStructureStrategy.  
 
    constructor public MultipleMessageStructure( outboundMessage as OutboundMessage ).
        super( outboundMessage ).
    end constructor.
 
    method public override void buildMessage(). 
        outboundMessage:createMessage().
    end method.
    
    method public override void addObject( objectContext as OutboundObjectContext ).
        
        outboundMessage:loadData  ( objectContext ).
        if objectContext:hasAdditionalData() then
            outboundMessage:appendPayloadObject( objectContext ).
        else
            outboundMessage:appendPayloadObject().
        outboundMessage:appendItem (). 

    end method. 
    
    method public override void finishMessage().
        outboundMessage:saveContent().
    end method. 

end class.
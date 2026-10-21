
/*------------------------------------------------------------------------
    File        : IMessageStructureFactory
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 18:22:34 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.outbound.core.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.strategy.MessageStructureStrategy abstract.       

    define protected property outboundMessage as OutboundMessage no-undo get. private set.
    
    constructor public MessageStructureStrategy( outboundMessage as OutboundMessage ).
        assign this-object:outboundMessage = outboundMessage.
    end constructor.

    method public abstract void buildMessage ( ).  
    method public abstract void addObject    ( objectContext as OutboundObjectContext ).
    method public abstract void finishMessage( ).
     
end class.
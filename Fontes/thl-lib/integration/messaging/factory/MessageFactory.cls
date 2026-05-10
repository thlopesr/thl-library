 
 /*------------------------------------------------------------------------
    File        : message_Repository
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*. 
using thl-lib.integration.messaging.outbound.strategy.*.
using thl-lib.integration.messaging.core.*.
using thl-lib.integration.messaging.Outbound.core.OutboundMessage.

block-level on error undo, throw.

class thl-lib.integration.messaging.factory.MessageFactory.
      
    define private   property isSingle as logical  no-undo get. set.
    define protected property message_ as Message  no-undo get. set.

    constructor public MessageFactory( configuration as MessageConfig ).
        
        define variable messageClass as character no-undo.
                                       
        assign this-object:isSingle = configuration:isSingle
               messageClass         = configuration:messageClass.
        
        message_ = dynamic-new messageClass( configuration:objectName          , 
                                             configuration:integrationOperation,
                                             configuration:methodType          , 
                                             configuration:connectorType       , 
                                             configuration:integrationDirection,
                                             configuration:executionMode       ).                          
               
    end constructor. 

    method public MessageStructureStrategy createStructureStrategy().

        if isSingle then return new SingleMessageStructure( cast( message_, OutboundMessage ) ).
        return new MultipleMessageStructure( cast( message_, OutboundMessage ) ).

    end method.   
    
    method public Message getMessage().
        return message_.
    end method. 

    method public void restoreMessage( messageCode as character ).
        message_:loadByMessageCode( messageCode ).
    end method.
    
end class.
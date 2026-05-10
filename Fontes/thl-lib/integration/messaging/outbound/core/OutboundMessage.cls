 
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

using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.messaging.core.Message.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.integration.messaging.Outbound.core.OutboundMessage abstract inherits Message.

    constructor public OutboundMessage ( objectName           as character ,
                                        integrationOperation as character ,
                                        methodType           as integer   ,
                                        connectorType        as integer   ,
                                        integrationDirection as logical   ,
                                        executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor.
    
    method public void loadData( register as recid ).
        assign this-object:referenceCode = onLoadData( register )
               repository:referenceCode  = this-object:referenceCode.
    end method. 
        
    method public abstract void      appendPayloadObject().     

end class.
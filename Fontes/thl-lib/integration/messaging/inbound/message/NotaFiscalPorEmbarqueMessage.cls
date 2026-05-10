/*------------------------------------------------------------------------
    File        : centroCusto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:41:22 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.integration.messaging.core.Message.
using thl-lib.integration.messaging.Inbound.core.InboundMessage.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.integration.messaging.Inbound.message.NotaFiscalPorEmbarqueMessage inherits InboundMessage.

    define buffer b-nota-fiscal for nota-fiscal.
    
    constructor public NotaFiscalPorEmbarqueMessage ( objectName           as character ,
                                     integrationOperation as character ,
                                     methodType           as integer   ,
                                     connectorType        as integer   ,
                                     integrationDirection as logical   ,
                                     executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor. 
    
    method protected override void methodPost( lpco as JsonObject ).

    end method.
    
    method public override character onLoadData( input register as recid ).
        return ( substitute(  '&1#&2'                    , 
                              b-nota-fiscal.co    , 
                              b-nota-fiscal.num-interno-lpco) ).
        
    end method.
    
    method protected override character getRequiredFields().
        return 'codigoEmitente,numeroInternoLpco'.
    end method.

end class.

using Progress.Json.ObjectModel.JsonObject from propath.

using thl-lib.util.json.JsonSetter.
using thl-lib.integration.messaging.Inbound.service.InboundMessageService.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using Progress.Json.ObjectModel.*.

/* ***************************  Definitions  ************************** */
define variable LPCO            as JsonObject    no-undo.
define variable responsePayload as JsonConstruct no-undo.

/* ***************************  Main Block  *************************** */
assign LPCO = new JsonObject().

LPCO:add('codigoEmitente'   , 13126 ).
LPCO:add('numeroInternoLpco', 1     ).       
LPCO:add('situacao'         , 4     ). 

assign responsePayload = new InboundMessageService ( 'LPCO', integer( MethodTypeEnum:GET:GetValue() )  ):receive( LPCO ).

if valid-object( responsePayload ) then do.

    if type-of( responsePayload, JsonArray ) then do.
        message 'JsonArray ' skip string( cast( responsePayload, JsonArray ):GetJsonText() )
            view-as alert-box.
    end.
    else if type-of( responsePayload, JsonObject ) then do.
        message 'JsonObject ' skip string( cast( responsePayload, JsonObject ):GetJsonText() )
            view-as alert-box.
    end.

end.

catch errorObject as Progress.Lang.Error.

    define variable count as integer no-undo.

    do count = 1 to errorObject:NumMessages. 
        message errorObject:GetMessageNum(count) skip
                errorObject:GetMessage(count)
            view-as alert-box.
    end. 

end catch.
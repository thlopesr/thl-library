/*------------------------------------------------------------------------
    File        : ServiceResponse
    Purpose     : Ponto unico de montagem do JsonObject de resposta dos
                  Services de dominio ERP ({success, code, message}).
                  Substitui os buildSuccessPayload duplicados por classe.
    Author(s)   : Lopes
    Created     : 2026-07-25
    Notes       : Mesmo shape de Message:setSuccessPayload (fallback do
                  InboundMessageService) — manter os dois alinhados.
                  A sobrecarga com referenceCode e opt-in: so adiciona o
                  campo quando informado, preservando o contrato atual
                  dos consumidores externos.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.erp.enum.ActionEnum.

block-level on error undo, throw.

class thl-lib.erp.core.ServiceResponse.

    method public static JsonObject success( input messageText as character  ,
                                             input actionName  as ActionEnum ,
                                             input referenceCode as character).
        return success( messageText, string(actionName), referenceCode ).
    end method.

    method public static JsonObject success( input messageText   as character ,
                                             input actionName    as character ,
                                             input referenceCode as character ).

        define variable response as JsonObject no-undo.

        assign response = new JsonObject().

        response:Add( 'success'      , true          ).
        response:Add( 'action'       , actionName    ).
        response:Add( 'code'         , 200           ).
        response:Add( 'referenceCode', referenceCode ).
        response:Add( 'message'      , messageText   ).
        
        return response.

    end method.

end class.

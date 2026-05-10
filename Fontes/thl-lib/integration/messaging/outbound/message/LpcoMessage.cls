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
using thl-lib.integration.messaging.Outbound.core.OutboundMessage.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.message.LpcoMessage inherits OutboundMessage.
    
    define private buffer b-nit-lpco for nit-lpco.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public LpcoMessage ( objectName           as character ,
                                     integrationOperation as character ,
                                     methodType           as integer   ,
                                     connectorType        as integer   ,
                                     integrationDirection as logical   ,
                                     executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor. 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override void appendPayloadObject().
  
        find first moeda of b-nit-lpco no-lock.
        
        this-object:initializeObjectPayload().
               
        cast(payload, JsonObject):add( 'codigo_emitente'       , b-nit-lpco.cod-emitente          ).                         
        cast(payload, JsonObject):add( 'numero_interno_lpco'   , b-nit-lpco.num-interno-lpco      ).                         
        cast(payload, JsonObject):add( 'codigo_cliente'        , string( b-nit-lpco.cod-emitente )).                         
        cast(payload, JsonObject):add( 'faixa'                 , if b-nit-lpco.faixa-mercadoria then 'A' else 'V' ).        
        cast(payload, JsonObject):add( 'moeda'                 , substring(moeda.char-2, 43, 3) ).                         
        cast(payload, JsonObject):add( 'quantidade'            , b-nit-lpco.quantidade           ).                         
        cast(payload, JsonObject):add( 'valor'                 , b-nit-lpco.valor-total          ).                         
        cast(payload, JsonObject):add( 'ncm'                   , b-nit-lpco.classif-fiscal       ).                         
        cast(payload, JsonObject):add( 'descricao'             , b-nit-lpco.descricao            ).                         
        cast(payload, JsonObject):add( 'informacoes_adicionais', b-nit-lpco.informacao-adicionais).                         

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-nit-lpco exclusive-lock
            where recid(b-nit-lpco) = register
            no-error.

        if not available b-nit-lpco then
            undo, throw new Progress.Lang.AppError( 'LPCO nao encontrado', 17006).

        return ( substitute( '&1#&2', b-nit-lpco.cod-emitente, b-nit-lpco.num-interno-lpco ) ).

    end method.

end class.

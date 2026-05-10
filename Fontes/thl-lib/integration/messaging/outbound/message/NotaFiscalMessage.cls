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

class thl-lib.integration.messaging.outbound.message.NotaFiscalMessage inherits OutboundMessage.
    
    define private buffer b-nota-fiscal for nota-fiscal.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public NotaFiscalMessage ( objectName           as character ,
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
  
        find first emitente  of b-nota-fiscal no-lock.
        find first estabelec of b-nota-fiscal no-lock.
        
        this-object:initializeObjectPayload().
               
        cast(payload, JsonObject):add ( 'embarqueResumo'  , b-nota-fiscal.nr-resumo   ).
        cast(payload, JsonObject):add ( 'cnpjCliente'     , emitente.cgc        ).
        cast(payload, JsonObject):add ( 'chaveNota'       , b-nota-fiscal.cod-chave-aces-nf-eletro ).
        cast(payload, JsonObject):add ( 'numeroEmbarque'  , string( b-nota-fiscal.cdd-embarq ) ).
        cast(payload, JsonObject):add ( 'numeroPedido'    , b-nota-fiscal.nr-pedcli   ).
        cast(payload, JsonObject):add ( 'estabelecimento' , estabelec.cgc             ).
        cast(payload, JsonObject):add ( 'serie'           , b-nota-fiscal.serie       ).
        cast(payload, JsonObject):add ( 'numeroNota'      , b-nota-fiscal.nr-nota-fis ).
        cast(payload, JsonObject):add ( 'valor'           , string( b-nota-fiscal.vl-tot-nota  ) ).         
        cast(payload, JsonObject):add ( 'peso'            , string( b-nota-fiscal.peso-bru-tot ) ).
        cast(payload, JsonObject):add ( 'dataCancelamento', b-nota-fiscal.dt-cancela  ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-nota-fiscal no-lock
            where recid(b-nota-fiscal) = register
            no-error.

        if not available b-nota-fiscal then
            undo, throw new Progress.Lang.AppError( 'Nota Fiscal nao encontrado', 17006).

        return ( substitute( '&1#&2#&3', b-nota-fiscal.cod-estabel, b-nota-fiscal.serie, b-nota-fiscal.nr-nota-fis ) ).

    end method.

end class.

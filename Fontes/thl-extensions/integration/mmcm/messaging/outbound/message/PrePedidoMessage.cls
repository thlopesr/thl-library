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
using thl-lib.integration.messaging.outbound.core.OutboundMessage.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-extensions.integration.mmcm.messaging.outbound.message.PrePedidoMessage inherits OutboundMessage.
    
    define private buffer b-embarque for embarque.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public PrePedidoMessage( objectName           as character ,
                                         applicationName      as character ,
                                         integrationOperation as character ,
                                         methodType           as integer   ,
                                         connectorType        as integer   ,
                                         integrationDirection as logical   ,
                                         executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor. 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override void appendPayloadObject().

        define variable items      as JsonArray  no-undo.
        define variable item       as JsonObject no-undo.
        define variable orders     as JsonArray  no-undo.
        define variable order      as JsonObject no-undo.
        
        assign orders = new JsonArray (). 
        
        for each pre-fatur no-lock
            where pre-fatur.cdd-embarq = b-embarque.cdd-embarq.
                     
            assign order = new JsonObject()
                   items = new JsonArray ().                     
            
            find first emitente  of pre-fatur no-lock no-error.
            find first estabelec of pre-fatur no-lock no-error.
            
            order:add('entrega', pre-fatur.dt-embarque ).
            order:add('cliente', estabelec.cgc         ).
            order:add('pedido' , pre-fatur.nr-pedcli   ). 
            order:add('pedido_cliente', pre-fatur.nr-pedcli  ).
            order:add('num_carga'     , pre-fatur.cdd-embarq ).
                     
            for each it-pre-fat of pre-fatur  no-lock,
                each it-dep-fat of it-pre-fat no-lock.
                
                assign item = new JsonObject().
                
                item:add('codigo' , it-dep-fat.it-codigo  ).
                item:add('qtde'   , it-dep-fat.qt-alocada ). 
                item:add('lote'   , it-dep-fat.nr-serlote ). 
                
                items :add( item  ).
                
            end.
   
            order :add( 'itens', items ).                
            orders:add( order ).
        
        end.
        
        this-object:initializeObjectPayload().
        
        cast(this-object:payload, JsonObject):add( 'pedidos', orders ). 
        cast(this-object:payload, JsonObject):add( 'token'  , ''     ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).

        find first b-embarque no-lock
            where recid(b-embarque) = register
            no-error.

        if not available b-embarque then
            this-object:errorHandler:throwError( 'onLoadData', 'Embarque nao encontrado.' ).

        return (
            substitute(
                '&1#&2',
                b-embarque.cdd-embarq  ,
                b-embarque.nr-embarque
            )
        ).

    end method.

    method protected override logical parseBusinessProcess( input response as longchar ).

        define variable content as JsonObject    no-undo.
        define variable parsed  as JsonConstruct no-undo.

        if not StringUtil:hasValue(response) then return false.

        assign parsed = new ObjectModelParser():Parse(response).

        if not type-of(parsed, JsonObject) then return false.

        assign content = cast(parsed, JsonObject).

        /* Payload sem campo 'data' nao pode ser avaliado — sinaliza Erro */
        if not content:Has('data') then 
            return false.

        return content:GetJsonObject('data'):GetLogical('success').
        
        catch error as Progress.Lang.Error.
            if StringUtil:hasValue( log-manager:logfile-name ) then
                log-manager:write-message( substitute( 'parseBusinessProcess: erro obj=&1 aplic=&2 erro=&3', this-object:objectName, this-object:applicationName, error:GetMessage(1) ),
                                           'PrePedidoMessage' ).
            return false.
        end.

    end method.

end class.

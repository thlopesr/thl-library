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

class thl-lib.integration.messaging.outbound.message.EntregaPedidoMessage inherits OutboundMessage.
    
    define private buffer b-ped-ent for ped-ent.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public EntregaPedidoMessage ( objectName           as character ,
                                              integrationOperation as character ,
                                              methodType           as integer   ,
                                              connectorType        as integer   ,
                                              integrationDirection as logical   ,
                                              executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor. 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override void appendPayloadObject().

        define variable delivereis as JsonArray  no-undo.
        define variable delivery   as JsonObject no-undo.
        define variable item       as JsonObject no-undo.
        define variable order      as JsonObject no-undo.
        define variable routes     as JsonArray  no-undo.
        define variable route      as JsonObject no-undo.
        
        if not valid-object(payload) then
            this-object:initializeArrayPayload().
        
        assign delivery   = new JsonObject()
               item       = new JsonObject()
               order      = new JsonObject()
               routes     = new JsonArray ().
               
        find first ped-item    of b-ped-ent no-lock no-error.
        find first item        of ped-item  no-lock no-error.
        find first fam-comerc  of item      no-lock no-error.
        find first ped-venda   of ped-item  no-lock no-error.
        find first canal-venda of ped-venda no-lock no-error.
        
        find first emitente    no-lock 
            where emitente.nome-abrev = ped-venda.nome-abrev 
            no-error.
                    
        find first es_ped_venda no-lock 
            where es_ped_venda.nr_pedido = ped-venda.nr-pedido   
            no-error.  
        
        find first es_ped_item no-lock
            where es_ped_item.nome_abrev   = ped-item.nome-abrev
              and es_ped_item.nr_pedcli    = ped-item.nr-pedcli
              and es_ped_item.nr_sequencia = ped-item.nr-sequencia
              and es_ped_item.it_codigo    = ped-item.it-codigo    
            no-error.   
              
        find first es_ped_ent no-lock
            where ES_PED_ENT.NOME_ABREV   = b-ped-ent.nome-abrev
              and ES_PED_ENT.NR_PEDCLI    = b-ped-ent.nr-pedcli
              and ES_PED_ENT.NR_SEQUENCIA = b-ped-ent.nr-sequencia
              and ES_PED_ENT.IT_CODIGO    = b-ped-ent.it-codigo
              and ES_PED_ENT.COD_REFER    = b-ped-ent.cod-refer
              and ES_PED_ENT.NR_ENTREGA   = b-ped-ent.nr-entrega
            no-error.             
        
        delivery:add('numeroPedido'      , ped-venda.nr-pedido    ).
        delivery:add('codigoProduto'     , b-ped-ent.it-codigo    ).
        delivery:add('sequenciaItem'     , b-ped-ent.nr-sequencia ).       
        delivery:add('numeroEntrega'     , b-ped-ent.nr-entrega   ).
        delivery:add('quantidadeEntrega' , b-ped-ent.qt-pedida    ).
        delivery:add('pesoEntrega'       , b-ped-ent.qt-pedida    ).
        delivery:add('valorTotalEntrega' , b-ped-ent.qt-pedida * ped-item.vl-preuni    ).
        delivery:add('valorFreteEntrega' , b-ped-ent.qt-pedida * if available es_ped_item then es_ped_item.vlr_unit_frete else 1 ).
        delivery:add('dataMinimaEntrega' , datetime( b-ped-ent.dt-entrega       ) ).
        delivery:add('dataMaximaEntrega' , datetime( b-ped-ent.dt-entrega + 7   ) ).               
        delivery:add('dataEntregaCliente', if available es_ped_ent then datetime( es_ped_ent.dat_ent_cliente ) else ? ).
        delivery:add('dataEntrega'       , datetime( b-ped-ent.dt-entrega       ) ).               
        
        //Pedido        
        order:add( 'numeroPedidoCliente', ped-venda.nr-pedcli       ).
        order:add( 'codigoCliente'      , ped-venda.cod-emitente    ).
        order:add( 'redespacho'         , ped-venda.nome-tr-red     ).
        order:add( 'codigoSegmento'     , ped-venda.cod-canal-venda ).
        order:add( 'tipoFrete'          , if ped-venda.cidade-cif > '0' then 'CIF' else 'FOB' ).        
        
        if available canal-venda then 
            order:add( 'descricaoSegmento'  , canal-venda.descricao     ).
        else
            order:add( 'descricaoSegmento'  , ''     ).    
            
        order:add( 'nomeCliente'        , emitente.nome-emit        ).
        order:add( 'tipo'               , '' ).

        if substring(ped-venda.char-1,162,5) = '54' or 
           substring(ped-venda.char-1,162,5) = '56' then order:set( 'tipo' , 'BONIFICACAO' ).
                                                    else order:set( 'tipo' , 'VENDA'       ). 

        if available es_ped_venda then do.
            order:add( 'rotaDetalhada' , es_ped_venda.detalhe-rota   ).
            order:add( 'tipoCarga'     , es_ped_venda.cod_tipo_carga ).
                        
            if trim(es_ped_venda.cod_tipo_carga) = ''                     and 
               emitente.nome-emit                begins 'COMPANHIA NITRO' then order:set( 'tipo' , 'TRANSFERENCIA' ). 
        end.
        else do.
            order:add( 'regional'      , '' ).
            order:add( 'rotaDetalhada' , '' ).
            order:add( 'tipoCarga'     , '' ).
        end.

        //Item            
        item:add( 'codigoProduto'             , ped-item.it-codigo      ).
        item:add( 'unidadeMedida'             , ped-item.cod-un         ).
        item:add( 'unidadeNegocio'            , ped-item.cod-unid-negoc ).
        item:add( 'codigoFamiliaComercial'    , item.fm-cod-com         ).
        item:add( 'descricaoFamiliaComercial' , fam-comerc.descricao    ).
        
        for first estabelec no-lock
            where estabelec.cod-estabel = ped-venda.cod-estabel.
        
            assign route = new JsonObject ().    
            
            route:add( 'tipo'     , 'ESTABELECIMENTO'       ).
            route:add( 'sequencia', 1                       ).
            route:add( 'codigo'   , estabelec.cod-emitente  ).
            route:add( 'nome'     , estabelec.nome          ).
            route:add( 'cnpj'     , estabelec.cgc           ).
            route:add( 'endereco' , estabelec.endereco      ).
            route:add( 'bairro'   , estabelec.bairro        ).
            route:add( 'cidade'   , estabelec.cidade        ).
            route:add( 'estado'   , estabelec.estado        ).
            route:add( 'cep'      , string( estabelec.cep ) ).                     
            route:add( 'pais'     , estabelec.pais          ).
            
            routes:add( route ).
            
        end.
        
        assign route = new JsonObject (). 
    
        route:add( 'tipo'     , 'CLIENTE'               ).  
        route:add( 'sequencia', 2                       ).
        route:add( 'codigo'   , ped-venda.cod-emitente  ). 
        route:add( 'nome'     , emitente.nome-emit      ).
        route:add( 'cnpj'     , ped-venda.cgc           ).
        route:add( 'endereco' , ped-venda.local-entreg  ).
        route:add( 'bairro'   , ped-venda.bairro        ).
        route:add( 'cidade'   , ped-venda.cidade        ).
        route:add( 'estado'   , ped-venda.estado        ).
        route:add( 'cep'      , ped-venda.cep           ).                     
        route:add( 'pais'     , ped-venda.pais          ).
        
        routes:add( route ).
        
        delivery:add  ( 'rotas' , routes ).
        delivery:add  ( 'pedido', order  ). 
        delivery:add  ( 'item'  , item   ).
        
        cast(payload, JsonArray):add( delivery ).  

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).
        
        find first b-ped-ent no-lock
            where recid(b-ped-ent) = register
            no-error.

        if not available b-ped-ent then
            undo, throw new Progress.Lang.AppError( 'Entraga pedido de venda nao encontrado.', 17006).

        return ( substitute(  '&1#&2#&3#&4#&5#&6#&7#&8', 
                              b-ped-ent.nome-abrev     , 
                              b-ped-ent.nr-pedcli      , 
                              b-ped-ent.nr-sequencia   , 
                              b-ped-ent.it-codigo      , 
                              b-ped-ent.cod-refer      , 
                              b-ped-ent.nr-programa    , 
                              b-ped-ent.dt-entrega     , 
                              b-ped-ent.hr-entrega     ) ).

    end method.

end class.

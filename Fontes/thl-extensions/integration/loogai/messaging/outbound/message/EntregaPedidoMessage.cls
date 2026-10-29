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
using thl-lib.integration.messaging.outbound.core.OutboundMessage.

block-level on error undo, throw.

class thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage inherits OutboundMessage.
    
    define private buffer b-ped-ent for ped-ent.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public EntregaPedidoMessage ( objectName           as character ,
                                              applicationName      as character ,
                                              integrationOperation as character ,
                                              methodType           as integer   ,
                                              connectorType        as integer   ,
                                              integrationDirection as logical   ,
                                              executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
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

        DEFINE VARIABLE i-idx          AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c-rota-detalha AS CHARACTER NO-UNDO.
        DEFINE VARIABLE c-tmp          AS CHARACTER   NO-UNDO.

        DEFINE VARIABLE de-vl-tot-ent AS DECIMAL FORMAT ">>>,>>>,>>9.99999" NO-UNDO.
        DEFINE VARIABLE de-vl-fre-ent AS DECIMAL FORMAT ">>>,>>>,>>9.99999" NO-UNDO.

        DEFINE VARIABLE dt-entrega-min AS DATE        NO-UNDO.
        DEFINE VARIABLE dt-entrega-max AS DATE        NO-UNDO.
        DEFINE VARIABLE c-tipo-frete   AS CHARACTER   NO-UNDO.

        DEF BUFFER b-emitente FOR emitente.
        
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
        find first estabelec   of ped-venda No-lock no-error.
        
        find first emitente    no-lock 
            where emitente.nome-abrev = ped-venda.nome-abrev 
            no-error.

        FIND FIRST repres
             WHERE repres.nome-abrev = ped-venda.no-ab-reppri NO-LOCK NO-ERROR.
                    
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

        FIND FIRST nit-loc-entr
             WHERE nit-loc-entr.nome-abrev  = ped-venda.nome-abrev
               AND nit-loc-entr.cod-entrega = ped-venda.cod-entrega NO-LOCK NO-ERROR.

        ASSIGN de-vl-tot-ent = b-ped-ent.qt-pedida * ped-item.vl-preuni
               de-vl-fre-ent = b-ped-ent.qt-pedida * if available es_ped_item then es_ped_item.vlr_unit_frete else 1
               c-tipo-frete  = if ped-venda.cidade-cif > '0' then 'CIF' else 'FOB'.

        IF ped-venda.mo-codigo > 0 THEN DO:
            run cdp/cd0812.p (input  ped-venda.mo-codigo,
                              input  0,
                              input  de-vl-tot-ent,
                              input  TODAY,
                              output de-vl-tot-ent).

            run cdp/cd0812.p (input  ped-venda.mo-codigo,
                              input  0,
                              input  de-vl-fre-ent,
                              input  TODAY,
                              output de-vl-fre-ent).
        END.

        /* Calcula dataMinimaEntrega - dataMaximaEntrega */
        IF AVAIL es_ped_venda AND AVAIL es_ped_ent THEN DO:
            IF es_ped_venda.cod_tipo_carga = "COMPOSTA" THEN DO:
               IF ped-venda.cod-estab = "202" AND ped-venda.estado = "MT" THEN DO:
                   CASE ABS(ped-venda.dt-emissao - es_ped_ent.dat_ent_cliente):
                       WHEN 7 THEN DO:
                           ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 3.
                       END.
                       WHEN 8 THEN DO:
                           ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 2.
                       END.
                       WHEN 9 THEN DO:
                           ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 1.
                       END.
                       WHEN 10 THEN DO:
                           ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 0.
                       END.
                       OTHERWISE DO:
                           ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 7
                                  dt-entrega-min = es_ped_ent.dat_ent_cliente - 7.
                       END.
                   END CASE.
    
                   ASSIGN dt-entrega-min = es_ped_ent.dat_ent_cliente - 7.
               END.
               ELSE DO:
                   ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 7
                          dt-entrega-min = es_ped_ent.dat_ent_cliente - 7.
               END.                       
            END.
            ELSE IF es_ped_venda.cod_tipo_carga = "FECHADA" THEN DO:
               IF canal-venda.descricao BEGINS "(B2B" THEN DO:
                   ASSIGN dt-entrega-max = ?
                          dt-entrega-min = ?.
               END.
               ELSE DO:
                   IF ped-venda.cod-estab = "202" AND ped-venda.estado = "MT" THEN DO:
                       CASE ABS(ped-venda.dt-emissao - es_ped_ent.dat_ent_cliente):
                           WHEN 7 THEN DO:
                               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 3.
                           END.
                           WHEN 8 THEN DO:
                               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 2.
                           END.
                           WHEN 9 THEN DO:
                               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 1.
                           END.
                           WHEN 10 THEN DO:
                               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 0.
                           END.
                           OTHERWISE DO:
                               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 7
                                      dt-entrega-min = es_ped_ent.dat_ent_cliente - 7.
                           END.
                       END CASE.
    
                       ASSIGN dt-entrega-min = es_ped_ent.dat_ent_cliente - 3.
                   END.
                   ELSE DO:
                       ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 3
                              dt-entrega-min = es_ped_ent.dat_ent_cliente - 3.
                   END.                           
               END.                       
            END.
            ELSE DO:
               ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente + 7
                      dt-entrega-min = es_ped_ent.dat_ent_cliente - 7.
            END.
    
            IF es_ped_venda.cod_tipo_carga = "REPIQUE" OR es_ped_venda.cod_tipo_carga = "FRACIONADA" OR c-tipo-frete = "FOB" THEN DO:
               ASSIGN dt-entrega-max = ?
                      dt-entrega-min = ?.
            END.
    
            IF c-tipo-frete = "FOB" THEN DO:
               ASSIGN dt-entrega-max = ?
                      dt-entrega-min = ?.
            END.
        END.

        IF (dt-entrega-max = ? OR dt-entrega-min = ?) AND AVAIL es_ped_ent THEN
            ASSIGN dt-entrega-max = es_ped_ent.dat_ent_cliente
                   dt-entrega-min = es_ped_ent.dat_ent_cliente.
        
        delivery:add('numeroPedido'         , ped-venda.nr-pedido    ).
        delivery:add('codigoProduto'        , b-ped-ent.it-codigo    ).
        delivery:add('sequenciaItem'        , b-ped-ent.nr-sequencia ).       
        delivery:add('numeroEntrega'        , b-ped-ent.nr-entrega   ).
        delivery:add('quantidadeEntrega'    , (b-ped-ent.qt-pedida - b-ped-ent.qt-alocada)  ).
        delivery:add('pesoEntrega'          , (b-ped-ent.qt-pedida - b-ped-ent.qt-alocada)  ).
        delivery:add('valorTotalEntrega'    , de-vl-tot-ent).
        delivery:add('valorFreteEntrega'    , de-vl-fre-ent).
        delivery:add('dataMinimaEntrega'    , datetime( dt-entrega-min  ) ).
        delivery:add('dataMaximaEntrega'    , datetime( dt-entrega-max  ) ).               
        delivery:add('dataEntregaCliente'   , if available es_ped_ent then datetime( es_ped_ent.dat_ent_cliente ) else ? ).
        delivery:add('dataEntrega'          , datetime( b-ped-ent.dt-entrega       ) ).               
        delivery:add('dataImplant'          , datetime( ped-venda.dt-implant       ) ).               
        delivery:add('nomeRepresentante'    , (IF AVAIL repres THEN repres.nome        ELSE "")).               
        delivery:add('telefoneRepresentante', (IF AVAIL repres THEN repres.telefone[1] ELSE "")).   
        delivery:add('mailRepresentante'    , (IF AVAIL repres THEN repres.e-mail      ELSE "")).   

        delivery:add( 'codigoCliente'        , ped-venda.cod-emitente  ). 
        delivery:add( 'nomeCliente'          , emitente.nome-emit      ).
        delivery:add( 'documentoCliente'     , ped-venda.cgc           ).
        
        delivery:add( 'codigoEstabelecimento', estabelec.cod-emitente  ).
        delivery:add( 'nomeEstabelecimento'  , estabelec.nome          ).
        delivery:add( 'cnpjEstabelecimento'  , estabelec.cgc           ).
        
        //Pedido        
        order:add( 'numeroPedidoCliente', ped-venda.nr-pedcli       ).
        order:add( 'codigoCliente'      , ped-venda.cod-emitente    ).
        order:add( 'redespacho'         , ped-venda.nome-tr-red     ).
        order:add( 'codigoSegmento'     , ped-venda.cod-canal-venda ).
        order:add( 'tipoFrete'          , c-tipo-frete ).        
        
        if available canal-venda then 
            order:add( 'descricaoSegmento'  , canal-venda.descricao     ).
        else
            order:add( 'descricaoSegmento'  , ''     ).    
            
        order:add( 'nomeCliente'        , emitente.nome-emit        ).
        order:add( 'tipo'               , '' ).

        if substring(ped-venda.char-1,162,5) = '54' or 
           substring(ped-venda.char-1,162,5) = '56' then      order:set( 'tipo' , 'BONIFICACAO' ).
        ELSE if substring(ped-venda.char-1,162,5) = '64' then order:set( 'tipo' , 'TRIANGULACAO').
                                                         else order:set( 'tipo' , 'VENDA'       ). 

        /* Pedido FOB */
        ASSIGN c-rota-detalha = "".
        if ped-venda.cidade-cif = '' OR ped-venda.cidade-cif = ? THEN DO:
            find last es_status_carregamento no-lock 
                where es_status_carregamento.situacao > 1
                  and es_status_carregamento.nr_pedido  = ped-venda.nr-pedido
                  and es_status_carregamento.nome_abrev = ped-venda.nome-abrev no-error.
            /*FIND FIRST es_status_carregamento no-lock 
                 WHERE es_status_carregamento.nr_pedido  = ped-venda.nr-pedido
                   and es_status_carregamento.nome_abrev = ped-venda.nome-abrev no-error.*/
            IF AVAIL es_status_carregamento THEN DO:
                ASSIGN c-tmp = es_status_carregamento.char_1.
                IF NUM-ENTRIES(c-tmp,"|") < 7 THEN DO:
                    DO i-idx = NUM-ENTRIES(c-tmp,"|") TO 7:
                        ASSIGN c-tmp = c-tmp + "|".
                    END.
                END.
                 
                IF es_status_carregamento.emitente-co <> ? AND es_status_carregamento.emitente-co <> 0 THEN DO:
                   FIND FIRST transporte NO-LOCK
                      WHERE transporte.cod-transp = es_status_carregamento.emitente-co  
                      NO-ERROR.
                   ASSIGN c-rota-detalha = "Transp: " + transporte.nome + " - Nome: " + es_status_carregamento.contato-co + " - CNPJ: " + transporte.cgc + " - Telefone: " + es_status_carregamento.telefone-co + CHR(10) + chr(13) + "Obs.: " + es_status_carregamento.rotaDetalhada.
                END.
                ELSE DO:
                   ASSIGN c-rota-detalha = "Nome: " + es_status_carregamento.contato-co + " - CPF: " + ENTRY(1,c-tmp, "|") + " - Telefone: " + es_status_carregamento.telefone-co + " - CNH: " + ENTRY(5,c-tmp, "|") + " (" + ENTRY(6,c-tmp, "|") + ") - Placa: " + ENTRY(2,c-tmp, "|") + " - Ve�culo: " + ENTRY(3,c-tmp, "|") + " RENAVAM: " + ENTRY(4,c-tmp, "|") + CHR(10) + chr(13) + "Obs.: " + es_status_carregamento.rotaDetalhada.
                END.
            END.
        END.
        ELSE IF AVAIL es_ped_venda THEN
            ASSIGN c-rota-detalha = es_ped_venda.detalhe-rota.

        if available es_ped_venda then do.
            //order:add( 'regional'    , es_ped_venda.regiao         ).
            order:add( 'rotaDetalhada' , c-rota-detalha).
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
        item:add( 'unidadeMedida'             , item.cod-un             ).
        item:add( 'unidadeNegocio'            , ped-item.cod-unid-negoc ).
        item:add( 'codigoFamiliaComercial'    , item.fm-cod-com         ).
        item:add( 'descricaoFamiliaComercial' , fam-comerc.descricao    ).
        
        IF es_ped_venda.cod_origem = 0 OR es_ped_venda.cod_origem = ? THEN DO:
            
            assign route = new JsonObject ().    
            
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

        END.
        ELSE DO:
            FOR FIRST b-emitente
                WHERE b-emitente.cod-emitente = es_ped_venda.cod_origem NO-LOCK:

                assign route = new JsonObject ().    
                
                route:add( 'sequencia', 1                        ).
                route:add( 'codigo'   , b-emitente.cod-emitente  ).
                route:add( 'nome'     , b-emitente.nome-abrev    ).
                route:add( 'cnpj'     , b-emitente.cgc           ).
                route:add( 'endereco' , b-emitente.endereco      ).
                route:add( 'bairro'   , b-emitente.bairro        ).
                route:add( 'cidade'   , b-emitente.cidade        ).
                route:add( 'estado'   , b-emitente.estado        ).
                route:add( 'cep'      , string( b-emitente.cep ) ).                     
                route:add( 'pais'     , b-emitente.pais          ).
                
                routes:add( route ).
            END.
        END.
        
        
        assign route = new JsonObject (). 
    
        route:add( 'sequencia', 2                       ).
        route:add( 'codigo'   , ped-venda.cod-emitente  ). 
        route:add( 'nome'     , emitente.nome-emit      ).
        route:add( 'cnpj'     , ped-venda.cgc           ).

        IF ped-venda.nome-tr-red <> "" THEN DO:
            FIND FIRST transporte
                 WHERE transporte.nome-abrev = ped-venda.nome-tr-red NO-LOCK NO-ERROR.

            route:add( 'endereco' , transporte.endereco).
            route:add( 'bairro'   , transporte.bairro  ).
            route:add( 'cidade'   , transporte.cidade  ).
            route:add( 'estado'   , transporte.estado  ).
            route:add( 'cep'      , transporte.cep     ).                     
            route:add( 'pais'     , transporte.pais    ).
            route:add( 'latitude' , '').                     
            route:add( 'longitude', '').
        END.
        ELSE IF es_ped_venda.cod_tipo_carga = "FRACIONADA-RETIRA" AND NUM-ENTRIES(es_ped_venda.detalhe-rota,"-") >= 5 THEN DO:
            route:add( 'endereco' , ENTRY(3,es_ped_venda.detalhe-rota,"-")).
            route:add( 'bairro'   , ENTRY(4,es_ped_venda.detalhe-rota,"-")).
            route:add( 'cidade'   , REPLACE(ENTRY(1,es_ped_venda.detalhe-rota,"-"),"Local Retirada: Cidade: ","")).
            route:add( 'estado'   , ENTRY(2,es_ped_venda.detalhe-rota,"-")).
            route:add( 'cep'      , ENTRY(5,es_ped_venda.detalhe-rota,"-")).                     
            route:add( 'pais'     , "Brasil").
            route:add( 'latitude' , '').
            route:add( 'longitude', '').
        END.
        ELSE DO:
            route:add( 'endereco' , ped-venda.local-entreg  ).
            route:add( 'bairro'   , ped-venda.bairro        ).
            route:add( 'cidade'   , ped-venda.cidade        ).
            route:add( 'estado'   , ped-venda.estado        ).
            route:add( 'cep'      , ped-venda.cep           ).                     
            route:add( 'pais'     , ped-venda.pais          ).
            route:add( 'latitude' , (IF AVAIL nit-loc-entr THEN nit-loc-entr.latidude  ELSE ?) ).                     
            route:add( 'longitude', (IF AVAIL nit-loc-entr THEN nit-loc-entr.longitude ELSE ?) ).
        END.
        
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



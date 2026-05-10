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

class thl-lib.integration.messaging.Inbound.message.LpcoMessage inherits InboundMessage.
    
    define private buffer b-nit-lpco for nit-lpco.

    constructor public LpcoMessage ( objectName           as character ,
                                     integrationOperation as character ,
                                     methodType           as integer   ,
                                     connectorType        as integer   ,
                                     integrationDirection as logical   ,
                                     executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor. 

    method protected override void methodPatch( lpco as JsonObject ).

        find first b-nit-lpco exclusive-lock
            where b-nit-lpco.cod-emitente     = lpco:GetInteger( 'codigoEmitente' )
              and b-nit-lpco.num-interno-lpco = lpco:GetInteger( 'numeroInternoLpco' )
            no-error.

        if not available b-nit-lpco then
            this-object:errorHandler:throwError( 17006, 'LPCO nao localizado. ******' ).

        this-object:appendMessageItemByReference( recid( b-nit-lpco ) ).

        assign JsonSetter:payload = lpco.

        JsonSetter:SetValue( input-output b-nit-lpco.classif-fiscal       , input 'classificacaoFiscal'   ).
        JsonSetter:SetValue( input-output b-nit-lpco.descricao            , input 'descricao'             ).
        JsonSetter:SetValue( input-output b-nit-lpco.faixa-mercadoria     , input 'faixaMercadoria'       ).
        JsonSetter:SetValue( input-output b-nit-lpco.informacao-adicionais, input 'informacoesAdicionais' ).
        JsonSetter:SetValue( input-output b-nit-lpco.mo-codigo            , input 'codigoMoeda'           ).
        JsonSetter:SetValue( input-output b-nit-lpco.num-lpco             , input 'numeroLpco'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.pais-destino         , input 'paisDestino'           ).
        JsonSetter:SetValue( input-output b-nit-lpco.quantidade           , input 'quantidade'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.saldo-quantidade     , input 'saldoQuantidade'       ).
        JsonSetter:SetValue( input-output b-nit-lpco.saldo-valor          , input 'saldoValor'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.situacao             , input 'situacao'              ).
        JsonSetter:SetValue( input-output b-nit-lpco.un                   , input 'unidade'               ).
        JsonSetter:SetValue( input-output b-nit-lpco.valor-total          , input 'valorTotal'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.valor-unitario       , input 'valorUnitario'         ).

        release b-nit-lpco no-error.

    end method.
    
    method protected override void methodPost( lpco as JsonObject ).

        if  can-find( first b-nit-lpco
                        where b-nit-lpco.cod-emitente     = LPCO:GetInteger('codigoEmitente') 
                          and b-nit-lpco.num-interno-lpco = LPCO:GetInteger('numeroInternoLpco') ) then do.
            undo, throw new Progress.Lang.AppError( 'LPCO ja existe' , 17006).  
        end.

        create b-nit-lpco.
        
        this-object:appendMessageItemByReference( recid( b-nit-lpco ) ).
        
        assign JsonSetter:payload = lpco.

        JsonSetter:SetValue( input-output b-nit-lpco.classif-fiscal       , input 'classificacaoFiscal'   ).
        JsonSetter:SetValue( input-output b-nit-lpco.descricao            , input 'descricao'             ).
        JsonSetter:SetValue( input-output b-nit-lpco.faixa-mercadoria     , input 'faixaMercadoria'       ).
        JsonSetter:SetValue( input-output b-nit-lpco.informacao-adicionais, input 'informacoesAdicionais' ).
        JsonSetter:SetValue( input-output b-nit-lpco.mo-codigo            , input 'codigoMoeda'           ).
        JsonSetter:SetValue( input-output b-nit-lpco.num-lpco             , input 'numeroLpco'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.pais-destino         , input 'paisDestino'           ).
        JsonSetter:SetValue( input-output b-nit-lpco.quantidade           , input 'quantidade'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.saldo-quantidade     , input 'saldoQuantidade'       ).
        JsonSetter:SetValue( input-output b-nit-lpco.saldo-valor          , input 'saldoValor'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.situacao             , input 'situacao'              ).
        JsonSetter:SetValue( input-output b-nit-lpco.un                   , input 'unidade'               ).
        JsonSetter:SetValue( input-output b-nit-lpco.valor-total          , input 'valorTotal'            ).
        JsonSetter:SetValue( input-output b-nit-lpco.valor-unitario       , input 'valorUnitario'         ).
        
        release b-nit-lpco no-error.

    end method.
    
    method protected override void methodDelete( lpco as JsonObject ).

        find first b-nit-lpco exclusive-lock
            where b-nit-lpco.cod-emitente     = LPCO:GetInteger('codigoEmitente') 
              and b-nit-lpco.num-interno-lpco = LPCO:GetInteger('numeroInternoLpco') no-error.
    
        if not available b-nit-lpco then 
            undo, throw new Progress.Lang.AppError( 'LPCO nao localizado' , 17006).                
        
        this-object:appendMessageItemByReference( recid( b-nit-lpco ) ).
            
        delete b-nit-lpco no-error. 
        
    end method.
    
    method protected override void methodGet().
            
        define variable LPCO as JsonObject no-undo.
        
        this-object:initializeArrayPayload().
     
        for each b-nit-lpco no-lock.
        
            assign LPCO = new JsonObject().
            
            LPCO:Add( 'classificacaoFiscal'  , b-nit-lpco.classif-fiscal        ). 
            LPCO:Add( 'codigoEmitente'       , b-nit-lpco.cod-emitente          ).
            LPCO:Add( 'descricao'            , b-nit-lpco.descricao             ).
            LPCO:Add( 'faixaMercadoria'      , b-nit-lpco.faixa-mercadoria      ).
            LPCO:Add( 'informacoesAdicionais', b-nit-lpco.informacao-adicionais ).
            LPCO:Add( 'codigoMoeda'          , b-nit-lpco.mo-codigo             ).
            LPCO:Add( 'numeroInternoLpco'    , b-nit-lpco.num-interno-lpco      ).
            LPCO:Add( 'numeroLpco'           , b-nit-lpco.num-lpco              ).
            LPCO:Add( 'paisDestino'          , b-nit-lpco.pais-destino          ).
            LPCO:Add( 'quantidade'           , b-nit-lpco.quantidade            ).
            LPCO:Add( 'saldoQuantidade'      , b-nit-lpco.saldo-quantidade      ).
            LPCO:Add( 'saldoValor'           , b-nit-lpco.saldo-valor           ).
            LPCO:Add( 'situacao'             , b-nit-lpco.situacao              ).
            LPCO:Add( 'unidade'              , b-nit-lpco.un                    ).
            LPCO:Add( 'valorTotal'           , b-nit-lpco.valor-total           ). 
            LPCO:Add( 'valorUnitario'        , b-nit-lpco.valor-unitario        ). 
                
            this-object:appendPayloadObject( LPCO ).
    
            this-object:appendMessageItemByReference( recid( b-nit-lpco ) ).
            
        end.
        
    end method.

    method public override character onLoadData( input register as recid ).

        return ( substitute(  '&1#&2'                    , 
                              b-nit-lpco.cod-emitente    , 
                              b-nit-lpco.num-interno-lpco) ).
        
    end method.
    
    method protected override character getRequiredFields().
        return 'codigoEmitente,numeroInternoLpco'.
    end method.

end class.

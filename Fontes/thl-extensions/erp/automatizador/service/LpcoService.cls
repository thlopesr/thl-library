/*------------------------------------------------------------------------
    File        : LpcoService
    Purpose     : Servico de dominio para manutencao de LPCO (nit-lpco):
                  criacao, atualizacao, exclusao e listagem paginada.
                  Modelo canonico de Service standalone (sem heranca de
                  BusinessObjectService/ApplicationProgramInterfaceService).
    Author(s)   : Lopes
    Created     : 2026-07-24
    Notes       : Paginacao via PaginationHelper (composicao, SRP).
                  Metodos individuais (create/update/delete/get) em vez de
                  dispatcher execute(operation) — padrao canonico P3.
                  Movido de thl-lib.erp.service para thl-extensions.erp.automatizador
                  em 2026-09-24: nit-lpco e schema do cliente (sistema Automatizador).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.automatizador.service.LpcoService inherits Service.

    define private buffer b-nit-lpco for nit-lpco.

    method public override character getEntityName().
        return 'LPCO'.
    end method.

    method public override void initialize().
        this-object:positionRecord().
    end method.

    method public override void create().
    
        define variable jsonSetter as JsonSetter no-undo.

        if available b-nit-lpco then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'criarLpco', 'LPCO ja existe.' ).

        find last b-nit-lpco no-lock
            where b-nit-lpco.cod-emitente =  inContext:GetInteger( 'codigoEmitente' )
            no-error.

        inContext:add( 'numeroInternoLpco', if available b-nit-lpco then b-nit-lpco.num-interno-lpco + 1 else 1 ).
        inContext:add( 'situacao'         , 1 ).

        assign jsonSetter = new JsonSetter( inContext ).

        do transaction.

            create b-nit-lpco.
            
            jsonSetter:SetValue( input-output b-nit-lpco.cod-emitente    , input 'codigoEmitente'   ).
            jsonSetter:SetValue( input-output b-nit-lpco.num-interno-lpco, input 'numeroInternoLpco').
            
            this-object:mapFields( jsonSetter ).

        end.

    end method.

    method public override void update().

        define variable jsonSetter as JsonSetter no-undo.

        assign jsonSetter = new JsonSetter( inContext ).

        if not available b-nit-lpco then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'atualizarLpco', 'LPCO nao localizado.' ).

        this-object:mapFields( jsonSetter ).

    end method.

    method public override void delete().

        if not available b-nit-lpco then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'excluirLpco', 'LPCO nao localizado.' ).

        delete b-nit-lpco.

    end method.

    //GET pelo Processor: le os filtros da query; a lista vira { items, hasNext }
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getInteger( 'NumeroInternoIni', 0         ),
                                queryParameters:getInteger( 'NumeroInternoFin', 999999999 ) ).
    end method.

    method public JsonArray get ( pager         as PaginationHelper,
                                  numInternoIni as integer         ,
                                  numInternoFin as integer         ).

        define variable LPCO   as JsonObject no-undo.
        define variable LPCOS  as JsonArray  no-undo.

        assign LPCOS     = new JsonArray().

        for each b-nit-lpco no-lock
            where b-nit-lpco.num-interno-lpco >= numInternoIni
              and b-nit-lpco.num-interno-lpco <= numInternoFin.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.
            
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
            LPCO:Add( 'dataValidade'         , b-nit-lpco.dat-validade          ).
            LPCO:Add( 'referenceCode'        , this-object:loadReferenceCode()  ).

            LPCOS:Add( LPCO ).

        end.

        return LPCOS.

    end method.

    method private void mapFields( input jsonSetter as JsonSetter ).

        jsonSetter:SetValue( input-output b-nit-lpco.classif-fiscal       , input 'classificacaoFiscal'   ).
        jsonSetter:SetValue( input-output b-nit-lpco.descricao            , input 'descricao'             ).
        jsonSetter:SetValue( input-output b-nit-lpco.faixa-mercadoria     , input 'faixaMercadoria'       ).
        jsonSetter:SetValue( input-output b-nit-lpco.informacao-adicionais, input 'informacoesAdicionais' ).
        jsonSetter:SetValue( input-output b-nit-lpco.mo-codigo            , input 'codigoMoeda'           ).
        jsonSetter:SetValue( input-output b-nit-lpco.num-lpco             , input 'numeroLpco'            ).
        jsonSetter:SetValue( input-output b-nit-lpco.pais-destino         , input 'paisDestino'           ).
        jsonSetter:SetValue( input-output b-nit-lpco.quantidade           , input 'quantidade'            ).
        jsonSetter:SetValue( input-output b-nit-lpco.saldo-quantidade     , input 'saldoQuantidade'       ).
        jsonSetter:SetValue( input-output b-nit-lpco.saldo-valor          , input 'saldoValor'            ).
        jsonSetter:SetValue( input-output b-nit-lpco.situacao             , input 'situacao'              ).
        jsonSetter:SetValue( input-output b-nit-lpco.un                   , input 'unidade'               ).
        jsonSetter:SetValue( input-output b-nit-lpco.valor-total          , input 'valorTotal'            ).
        jsonSetter:SetValue( input-output b-nit-lpco.valor-unitario       , input 'valorUnitario'         ).
        jsonSetter:SetValue( input-output b-nit-lpco.dat-validade         , input 'dataValidade'          ).

    end method.

    //le do buffer posicionado — nao do payload de entrada — para que o
    //metodo sirva tanto ao fluxo de escrita quanto a listagem do get()
    method public override character loadReferenceCode().
        if available b-nit-lpco then
           return substitute( '&1#&2', b-nit-lpco.cod-emitente, b-nit-lpco.num-interno-lpco ).
        else do.
            if inContext:has( 'codigoEmitente' )    and
               inContext:has( 'numeroInternoLpco' ) then 
               return substitute( '&1#&2', inContext:GetInteger( 'codigoEmitente' ), inContext:GetInteger( 'numeroInternoLpco' ) ).
        end.
        return ''.
    end method.
    
    method private void positionRecord().
        find first b-nit-lpco exclusive-lock
            where b-nit-lpco.cod-emitente     = inContext:GetInteger( 'codigoEmitente' )
              and b-nit-lpco.num-interno-lpco = inContext:GetInteger( 'numeroInternoLpco' )
            no-error.
    end method.
    
end class.

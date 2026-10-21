/*------------------------------------------------------------------------
    File        : RequisicaoService
    Purpose     : Servico de dominio para criacao de requisicao de material
                  via BOFs (boin385/boin168). Orquestra a criacao do
                  cabecalho (requisicao) e dos itens (it-requisicao),
                  propagando campos do cabecalho para cada item antes de
                  chamar o boin168.
    Author(s)   : Lopes
    Created     : 2026-08-17
    Notes       : Herda BusinessObject (RowErrors para BOFs). O hook
                  prepareRequisicaoData e protected para que extensoes por
                  cliente especializem o mapeamento sem repetir a
                  orquestracao de BOFs.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.BusinessObject.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.erp.service.RequisicaoService inherits BusinessObject.

    define protected temp-table tt-requisicao    no-undo serialize-name 'requisicao'    like requisicao
        field r-rowid as rowid.

    define protected temp-table tt-it-requisicao no-undo serialize-name 'it-requisicao' like it-requisicao
        field r-rowid as rowid.

    define private temp-table tt-it-boin168 no-undo like it-requisicao
        field r-rowid as rowid.

    method public override character getEntityName().
        return 'Requisicao'.
    end method.

    method public override void create().

        empty temp-table tt-requisicao    no-error.
        empty temp-table tt-it-requisicao no-error.

        this-object:prepareRequisicaoData( inContext ).

        this-object:executeBOFs().

    end method.

    method public override void delete().

        define variable h-boin385         as handle  no-undo.
        define variable requisitionNumber as integer no-undo.

        assign requisitionNumber = inContext:GetInteger('nr-requisicao').
        
        if not can-find( first requisicao no-lock
                            where requisicao.nr-requisicao = requisitionNumber ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Requisicao nao localizada' ).

        run inbo/boin385.p persistent set h-boin385.

        do transaction.

            run openQueryStatic   in h-boin385 ( input 'main' ).
            run goToKeyRequisicao in h-boin385 ( input requisitionNumber ).
            run deleteRecord      in h-boin385.
            run getRowErrors      in h-boin385 ( output table RowErrors ).
            this-object:throwRowErrorsIfAny( 'delete**', 'boin385' ).

        end.

        finally.
            if valid-handle( h-boin385 ) then delete procedure h-boin385 no-error.
        end finally.

    end method.

    method public override character loadReferenceCode().
        find first tt-requisicao no-lock no-error.
        if available tt-requisicao then
            return string( tt-requisicao.nr-requisicao ).
        else 
            if inContext:has('nr-requisicao') then 
                return string( inContext:GetInteger('nr-requisicao') ).
            
        return ''.
    end method.

    // hook: extensoes por cliente podem sobrescrever para especializar o mapeamento de campos
    method protected void prepareRequisicaoData( input context as JsonObject ).

        define variable items      as JsonArray  no-undo.
        define variable jsonSetter as JsonSetter no-undo.
        define variable counter    as integer    no-undo.

        if not context:Has('items') then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'prepareRequisicaoData',
                'Requisicao sem item' ).

        assign items = context:GetJsonArray('items').

        do counter = 1 to items:Length.

            create tt-it-requisicao.
            assign tt-it-requisicao.situacao = 1
                   tt-it-requisicao.estado   = 1.

            assign jsonSetter = new JsonSetter( items:GetJsonObject(counter) ).
            jsonSetter:SetValue( input-output tt-it-requisicao.sequencia,        input 'sequencia'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.it-codigo,        input 'it-codigo'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.qt-requisitada,   input 'qt-requisitada'   ).
            jsonSetter:SetValue( input-output tt-it-requisicao.qt-atendida,      input 'qt-atendida'      ).
            jsonSetter:SetValue( input-output tt-it-requisicao.qt-a-atender,     input 'qt-a-atender'     ).
            jsonSetter:SetValue( input-output tt-it-requisicao.ct-codigo,        input 'ct-codigo'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.sc-codigo,        input 'sc-codigo'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.narrativa,        input 'narrativa'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.dt-entrega,       input 'dt-entrega'       ).
            jsonSetter:SetValue( input-output tt-it-requisicao.situacao,         input 'situacao'         ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-estabel,      input 'cod-estabel'      ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-depos,        input 'cod-depos'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.lote,             input 'lote'             ).
            jsonSetter:SetValue( input-output tt-it-requisicao.qt-devolvida,     input 'qt-devolvida'     ).
            jsonSetter:SetValue( input-output tt-it-requisicao.qt-a-devolver,    input 'qt-a-devolver'    ).
            jsonSetter:SetValue( input-output tt-it-requisicao.nome-abrev,       input 'nome-abrev'       ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-refer,        input 'cod-refer'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.dt-atend,         input 'dt-atend'         ).
            jsonSetter:SetValue( input-output tt-it-requisicao.numero-ordem,     input 'numero-ordem'     ).
            jsonSetter:SetValue( input-output tt-it-requisicao.num-ord-inv,      input 'num-ord-inv'      ).
            jsonSetter:SetValue( input-output tt-it-requisicao.ep-codigo,        input 'ep-codigo'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.seq-planej,       input 'seq-planej'       ).
            jsonSetter:SetValue( input-output tt-it-requisicao.val-item,         input 'val-item'         ).
            jsonSetter:SetValue( input-output tt-it-requisicao.un,               input 'un'               ).
            jsonSetter:SetValue( input-output tt-it-requisicao.preco-unit,       input 'preco-unit'       ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-localiz,      input 'cod-localiz'      ).
            jsonSetter:SetValue( input-output tt-it-requisicao.conta-contabil,   input 'conta-contabil'   ).
            jsonSetter:SetValue( input-output tt-it-requisicao.check-sum,        input 'check-sum'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.prioridade-aprov, input 'prioridade-aprov' ).
            jsonSetter:SetValue( input-output tt-it-requisicao.estado,           input 'estado'           ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-unid-negoc,   input 'cod-unid-negoc'   ).
            jsonSetter:SetValue( input-output tt-it-requisicao.hra-entrega,      input 'hra-entrega'      ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-grp-compra,   input 'cod-grp-compra'   ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-comprado,     input 'cod-comprado'     ).
            jsonSetter:SetValue( input-output tt-it-requisicao.tp-requis,        input 'tp-requis'        ).
            jsonSetter:SetValue( input-output tt-it-requisicao.cod-id-solum-mov, input 'cod-id-solum-mov' ).

        end.

        create tt-requisicao.
        assign tt-requisicao.situacao  = 1
               tt-requisicao.tp-requis = 1.

        assign jsonSetter = new JsonSetter( context ).
        jsonSetter:SetValue( input-output tt-requisicao.nome-abrev,       input 'nome-abrev'       ).
        jsonSetter:SetValue( input-output tt-requisicao.dt-requisicao,    input 'dt-requisicao'    ).
        jsonSetter:SetValue( input-output tt-requisicao.ct-codigo,        input 'ct-codigo'        ).
        jsonSetter:SetValue( input-output tt-requisicao.sc-codigo,        input 'sc-codigo'        ).
        jsonSetter:SetValue( input-output tt-requisicao.situacao,         input 'situacao'         ).
        jsonSetter:SetValue( input-output tt-requisicao.dt-atend,         input 'dt-atend'         ).
        jsonSetter:SetValue( input-output tt-requisicao.loc-entrega,      input 'loc-entrega'      ).
        jsonSetter:SetValue( input-output tt-requisicao.dt-devol,         input 'dt-devol'         ).
        jsonSetter:SetValue( input-output tt-requisicao.narrativa,        input 'narrativa'        ).
        jsonSetter:SetValue( input-output tt-requisicao.estado,           input 'estado'           ).
        jsonSetter:SetValue( input-output tt-requisicao.nome-aprov,       input 'nome-aprov'       ).
        jsonSetter:SetValue( input-output tt-requisicao.impressa,         input 'impressa'         ).
        jsonSetter:SetValue( input-output tt-requisicao.cod-estabel,      input 'cod-estabel'      ).
        jsonSetter:SetValue( input-output tt-requisicao.tp-requis,        input 'tp-requis'        ).
        jsonSetter:SetValue( input-output tt-requisicao.num-id-documento, input 'num-id-documento' ).
        jsonSetter:SetValue( input-output tt-requisicao.check-sum,        input 'check-sum'        ).

    end method.

    method private void executeBOFs().

        define variable h-boin385 as handle no-undo.
        define variable h-boin168 as handle no-undo.

        run inbo/boin385.p persistent set h-boin385.

        find first tt-requisicao no-lock no-error.

        if not available tt-requisicao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeBOFs',
                'Cabecalho de requisicao nao localizado apos prepareRequisicaoData.' ).

        do transaction.

            run openQueryStatic   in h-boin385 ( input 'main' ).
            run proximaRequisicao in h-boin385 ( output tt-requisicao.nr-requisicao ).
            run setRecord         in h-boin385 ( input table tt-requisicao ).
            run createRecord      in h-boin385.
            run getRowErrors      in h-boin385 ( output table RowErrors ).
            this-object:throwRowErrorsIfAny( 'executeBOFs', 'boin385' ).

            for each tt-it-requisicao.

                empty temp-table tt-it-boin168 no-error.

                create tt-it-boin168.
                buffer-copy tt-it-requisicao to tt-it-boin168
                    assign tt-it-boin168.nr-requisicao = tt-requisicao.nr-requisicao
                           tt-it-boin168.nome-abrev    = tt-requisicao.nome-abrev
                           tt-it-boin168.situacao      = tt-requisicao.situacao
                           tt-it-boin168.dt-atend      = tt-requisicao.dt-atend
                           tt-it-boin168.estado        = tt-requisicao.estado
                           tt-it-boin168.nome-aprov    = tt-requisicao.nome-aprov
                           tt-it-boin168.cod-estabel   = tt-requisicao.cod-estabel
                           tt-it-boin168.tp-requis     = tt-requisicao.tp-requis
                           tt-it-boin168.check-sum     = tt-requisicao.check-sum.

                run inbo/boin168.p persistent set h-boin168.

                run openQueryStatic in h-boin168 ( input 'main' ).
                run setRecord       in h-boin168 ( input table tt-it-boin168 ).
                run createRecord    in h-boin168.
                run getRowErrors    in h-boin168 ( output table RowErrors ).
                this-object:throwRowErrorsIfAny(
                    substitute( 'executeBOFs - requisicao &1 - sequencia &2',
                                tt-requisicao.nr-requisicao, tt-it-requisicao.sequencia ),
                    'boin168' ).

                if valid-handle( h-boin168 ) then delete procedure h-boin168 no-error.

            end. // for each tt-it-requisicao

        end. // do transaction

        finally.
            if valid-handle( h-boin385 ) then delete procedure h-boin385 no-error.
            if valid-handle( h-boin168 ) then delete procedure h-boin168 no-error.
        end finally.

    end method.

end class.

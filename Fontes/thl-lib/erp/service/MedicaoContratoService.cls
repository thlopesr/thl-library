/*------------------------------------------------------------------------
    File        : MedicaoContratoService
    Purpose     : Servico de dominio generico para criacao de medicao de
                  contrato (medicao-contrat) e da matriz de rateio
                  (matriz-rat-med) via API padrao cnp/cnapi040.p.
    Author(s)   : Lopes
    Created     : 2026-10-21
    Notes       : Herda ApplicationProgrammingInterface (tt-erro +
                  throwApiErrorsIfAny). tt-medicao e tt-rateio-medicao sao
                  LIKE das tabelas, como na documentacao da API. A API valida
                  o que faltar: o servico so mapeia o que veio no JSON.
                  O JSON usa o nome do campo em camelCase (nr-contrato ->
                  nrContrato); matrizRateio[] e a filha matriz-rat-med.
                  Hooks protected (validateMedicao, beforeExecuteApi,
                  afterExecuteApi, onCreateFailed) permitem que extensoes por
                  cliente acrescentem regras e gravacoes na mesma transacao,
                  sem repetir a orquestracao. Avisos (nao bloqueantes) vao
                  para o array "avisos" da resposta.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.ApplicationProgrammingInterface.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.erp.service.MedicaoContratoService inherits ApplicationProgrammingInterface.

    define protected temp-table tt-medicao no-undo like medicao-contrat.

    define protected temp-table tt-rateio-medicao no-undo like matriz-rat-med.

    //avisos nao bloqueantes, devolvidos no corpo de sucesso
    define protected property warnings as JsonArray no-undo get. private set.

    method public override character getEntityName().
        return 'MedicaoContrato'.
    end method.

    method public override void create().

        assign this-object:warnings = new JsonArray().

        this-object:prepareMedicaoData( inContext ).
        this-object:loadOutContext().

        //uma transacao so: regras, gravacoes do cliente, API padrao e pos-gravacao
        do transaction.

            this-object:validateMedicao().
            this-object:beforeExecuteApi().
            this-object:executeApi().
            this-object:afterExecuteApi().

        end.

        //a transacao ja foi desfeita; quem gravou fora do banco (arquivos) desfaz aqui
        catch err as Progress.Lang.Error.
            this-object:onCreateFailed().
            undo, throw err.
        end catch.

    end method.

    //chave da medicao: contrato#item#ordem#evento#medicao, lida so do outContext (carregado antes
    //da API, para valer tambem com a medicao rejeitada e sem depender de tt-medicao)
    method public override character loadReferenceCode().

        if not valid-object( outContext ) or not outContext:Has( 'nrContrato' ) then
            return ''.

        return substitute( '&1#&2#&3#&4#&5', outContext:GetInteger( 'nrContrato' ),
                                             outContext:GetInteger( 'numSeqItem' ),
                                             outContext:GetInteger( 'numeroOrdem' ),
                                             outContext:GetInteger( 'numSeqEvent' ),
                                             outContext:GetInteger( 'numSeqMedicao' ) ).

    end method.

    //Chave da medicao no outContext. Hoje sai da tt-medicao montada no create(); um GET futuro
    //carrega a mesma chave dos parametros da consulta, sem tt-medicao.
    method protected void loadOutContext():

        find first tt-medicao no-lock no-error.

        if not available tt-medicao then
            return.

        assign this-object:outContext = new JsonObject().

        outContext:Add( 'nrContrato'   , tt-medicao.nr-contrato      ).
        outContext:Add( 'numSeqItem'   , tt-medicao.num-seq-item     ).
        outContext:Add( 'numeroOrdem'  , tt-medicao.numero-ordem     ).
        outContext:Add( 'numSeqEvent'  , tt-medicao.num-seq-event    ).
        outContext:Add( 'numSeqMedicao', tt-medicao.num-seq-medicao  ).

    end method.

    method public override JsonObject buildResponse( input action        as ActionEnum,
                                                     input referenceCode as character ).

        define variable response as JsonObject no-undo.

        assign response = super:buildResponse( action, referenceCode ).

        //chave da medicao como objeto, alem do referenceCode em texto
        if valid-object( outContext ) and outContext:Has( 'nrContrato' ) then
            response:Add( 'medicao', outContext ).

        if valid-object( this-object:warnings ) and this-object:warnings:Length > 0 then
            response:Add( 'avisos', this-object:warnings ).

        return response.

    end method.

    //hook: regras antes de gravar qualquer coisa (extensao por cliente)
    method protected void validateMedicao().
    end method.

    //hook: gravacoes do cliente que precisam existir antes da API
    method protected void beforeExecuteApi().
    end method.

    //hook: gravacoes do cliente depois da API (a medicao ja existe)
    method protected void afterExecuteApi().
    end method.

    //hook: desfaz o que nao e transacional (arquivos) quando algo falha
    method protected void onCreateFailed().
    end method.

    method protected void addWarning( input warningText as character ).
        this-object:warnings:Add( warningText ).
    end method.

    //Mapeia o JSON para tt-medicao e tt-rateio-medicao. Nao valida: a API valida.
    method protected void prepareMedicaoData( input context as JsonObject ).

        define variable jsonSetter as JsonSetter no-undo.
        define variable rateios    as JsonArray  no-undo.
        define variable counter    as integer    no-undo.

        empty temp-table tt-medicao         no-error.
        empty temp-table tt-rateio-medicao  no-error.

        create tt-medicao.

        assign jsonSetter = new JsonSetter( context ).

        jsonSetter:SetValue( input-output tt-medicao.usuario          , input 'usuario'         ).
        jsonSetter:SetValue( input-output tt-medicao.nr-contrato      , input 'nrContrato'      ).
        jsonSetter:SetValue( input-output tt-medicao.hra-medicao      , input 'hraMedicao'      ).
        jsonSetter:SetValue( input-output tt-medicao.dat-medicao      , input 'datMedicao'      ).
        jsonSetter:SetValue( input-output tt-medicao.perc-medicao     , input 'percMedicao'     ).
        jsonSetter:SetValue( input-output tt-medicao.num-seq-event    , input 'numSeqEvent'     ).
        jsonSetter:SetValue( input-output tt-medicao.it-codigo        , input 'itCodigo'        ).
        jsonSetter:SetValue( input-output tt-medicao.num-seq-item     , input 'numSeqItem'      ).
        jsonSetter:SetValue( input-output tt-medicao.un               , input 'un'              ).
        jsonSetter:SetValue( input-output tt-medicao.observacao       , input 'observacao'      ).
        jsonSetter:SetValue( input-output tt-medicao.qtd-medicao      , input 'qtdMedicao'      ).
        jsonSetter:SetValue( input-output tt-medicao.val-medicao      , input 'valMedicao'      ).
        jsonSetter:SetValue( input-output tt-medicao.num-seq-medicao  , input 'numSeqMedicao'   ).
        jsonSetter:SetValue( input-output tt-medicao.responsavel      , input 'responsavel'     ).
        jsonSetter:SetValue( input-output tt-medicao.numero-ordem     , input 'numeroOrdem'     ).
        jsonSetter:SetValue( input-output tt-medicao.dat-prev-medicao , input 'datPrevMedicao'  ).
        jsonSetter:SetValue( input-output tt-medicao.perc-lib-previsto, input 'percLibPrevisto' ).
        jsonSetter:SetValue( input-output tt-medicao.qtd-prevista     , input 'qtdPrevista'     ).
        jsonSetter:SetValue( input-output tt-medicao.val-previsto     , input 'valPrevisto'     ).
        jsonSetter:SetValue( input-output tt-medicao.ind-sit-medicao  , input 'indSitMedicao'   ).
        jsonSetter:SetValue( input-output tt-medicao.cod-estabel      , input 'codEstabel'      ).
        jsonSetter:SetValue( input-output tt-medicao.num-ord-inv      , input 'numOrdInv'       ).
        jsonSetter:SetValue( input-output tt-medicao.ep-codigo        , input 'epCodigo'        ).
        jsonSetter:SetValue( input-output tt-medicao.val-sdo-aloc-med , input 'valSdoAlocMed'   ).
        jsonSetter:SetValue( input-output tt-medicao.num-ord-invest   , input 'numOrdInvest'    ).
        jsonSetter:SetValue( input-output tt-medicao.seq-comp         , input 'seqComp'         ).
        jsonSetter:SetValue( input-output tt-medicao.nr-ord-produ     , input 'nrOrdProdu'      ).
        jsonSetter:SetValue( input-output tt-medicao.log-rec-medicao, input 'logRecMedicao' ).
        jsonSetter:SetValue( input-output tt-medicao.dat-receb, input 'datReceb' ).
        jsonSetter:SetValue( input-output tt-medicao.num-nota, input 'numNota' ).
        jsonSetter:SetValue( input-output tt-medicao.val-antecip, input 'valAntecip' ).
        jsonSetter:SetValue( input-output tt-medicao.sld-val-medicao, input 'sldValMedicao' ).
        jsonSetter:SetValue( input-output tt-medicao.sld-rec-medicao, input 'sldRecMedicao' ).

        //matriz de rateio: a chave da medicao e a da filha (vale a da medicao, salvo se a filha informar outra)
        if context:Has( 'matrizRateio' ) then do.

            assign rateios = context:GetJsonArray( 'matrizRateio' ).

            do counter = 1 to rateios:Length.

                create tt-rateio-medicao.

                assign tt-rateio-medicao.nr-contrato     = tt-medicao.nr-contrato
                       tt-rateio-medicao.num-seq-item    = tt-medicao.num-seq-item
                       tt-rateio-medicao.numero-ordem    = tt-medicao.numero-ordem
                       tt-rateio-medicao.num-seq-event   = tt-medicao.num-seq-event
                       tt-rateio-medicao.num-seq-medicao = tt-medicao.num-seq-medicao
                       tt-rateio-medicao.nr-ord-produ    = tt-medicao.nr-ord-produ.

                assign jsonSetter = new JsonSetter( rateios:GetJsonObject( counter ) ).

                jsonSetter:SetValue( input-output tt-rateio-medicao.nr-contrato, input 'nrContrato' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.num-seq-item, input 'numSeqItem' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.numero-ordem, input 'numeroOrdem' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.num-seq-event, input 'numSeqEvent' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.num-seq-medicao, input 'numSeqMedicao' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.conta-contabil, input 'contaContabil' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.perc-rateio, input 'percRateio' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.ct-codigo, input 'ctCodigo' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.sc-codigo, input 'scCodigo' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.cod-unid-negoc, input 'codUnidNegoc' ).
                jsonSetter:SetValue( input-output tt-rateio-medicao.nr-ord-produ, input 'nrOrdProdu' ).

            end.

        end.

    end method.

    //API padrao (cnp/cnapi040.p), chamada no modo batch: RUN normal com as temp-tables
    method protected void executeApi().

        define variable productionOrder as integer no-undo.

        find first tt-medicao no-lock no-error.

        if not available tt-medicao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeApi',
                'Medicao nao montada apos prepareMedicaoData.' ).

        assign productionOrder = tt-medicao.nr-ord-produ.

        empty temp-table tt-erro no-error.

        run cnp/cnapi040.p ( input  table tt-medicao       ,
                             input  table tt-rateio-medicao,
                             input  productionOrder        ,
                             output table tt-erro          ).

        this-object:throwApiErrorsIfAny( 'executeApi', 'cnapi040' ).

    end method.

end class.

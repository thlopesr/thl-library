/*------------------------------------------------------------------------
    File        : SolicitacaoCompraMessage
    Purpose     : Envia dados de ordens de compra e solicitacoes ao Power Automate
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Fri Sep 05 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.integration.messaging.outbound.core.OutboundMessage.
using thl-lib.util.string.StringUtil.
using thl-extensions.integration.powerautomate.messaging.outbound.enum.OrderStatusEnum.
using thl-extensions.integration.powerautomate.messaging.outbound.enum.RequestStatusEnum.

block-level on error undo, throw.

class thl-extensions.integration.powerautomate.messaging.outbound.message.SolicitacaoCompraMessage inherits OutboundMessage.

    define private buffer b-ordem-compra  for ordem-compra.
    define private buffer b-oc-preco      for ordem-compra.
    define private buffer b-it-requisicao for it-requisicao.
    define private buffer b-item          for item.
    define private buffer b-requisicao    for requisicao.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    constructor public SolicitacaoCompraMessage ( objectName           as character ,
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

        if not valid-object(payload) then
            this-object:initializeArrayPayload().

        if available b-ordem-compra then
            appendPurchaseOrder().
        else
            appendPurchaseRequest().

    end method.

    /*------------------------------------------------------------------------------
     Purpose: Monta payload de uma ordem de compra
     Notes:   Logica baseada na procedure pi-ordem
    ------------------------------------------------------------------------------*/
    method private void appendPurchaseOrder().

        define variable jsonObject         as JsonObject no-undo.
        define variable itemDescription    as character  no-undo.
        define variable itemFamilyCode     as character  no-undo.
        define variable itemUnit           as character  no-undo.
        define variable itemNarrative      as character  no-undo.
        define variable itemContractType   as integer    no-undo.
        define variable strategicFlag      as character  no-undo.
        define variable buyerCode          as character  no-undo.
        define variable projectNumber      as integer    no-undo.
        define variable projectDescription as character  no-undo.

        loadItemData( b-ordem-compra.it-codigo,
                      output itemDescription  ,
                      output itemFamilyCode   ,
                      output itemUnit         ,
                      output itemContractType ,
                      output itemNarrative    ).

        loadItemEstablishment( b-ordem-compra.it-codigo  ,
                               b-ordem-compra.cod-estabel,
                               output strategicFlag      ,
                               output buyerCode          ).

        loadInvestmentProject( b-ordem-compra.ep-codigo  ,
                               b-ordem-compra.num-ord-inv,
                               b-ordem-compra.cod-estabel,
                               output projectNumber      ,
                               output projectDescription ).

        assign jsonObject = new JsonObject().

        jsonObject:add( 'nome'          , getRequesterName( b-ordem-compra.requisitante ) ).
        jsonObject:add( 'nr-requisicao' , b-ordem-compra.nr-requisicao ).
        jsonObject:add( 'dt-requisicao' , StringUtil:formatIsoDate( b-ordem-compra.data-emissao ) ).
        jsonObject:add( 'situacao'      , if b-ordem-compra.nr-requisicao <> 0 then 'Com Ordem' else '' ).
        jsonObject:add( 'numero-ordem'  , b-ordem-compra.numero-ordem  ).
        jsonObject:add( 'cod-comprado'  , b-ordem-compra.cod-comprado  ).
        jsonObject:add( 'sit-ordem'     , getOrderStatusLabel()        ).
        jsonObject:add( 'nr-processo'   , b-ordem-compra.nr-processo   ).
        jsonObject:add( 'qt-requisitada', getOutstandingBalance()      ).
        jsonObject:add( 'preco-unit'    , getUnitPrice()               ).
        jsonObject:add( 'fm-codigo'     , itemFamilyCode               ).
        jsonObject:add( 'un'            , itemUnit                     ).
        jsonObject:add( 'estrat'        , strategicFlag                ).
        jsonObject:add( 'it-codigo'     , b-ordem-compra.it-codigo     ).
        jsonObject:add( 'narrativa'     , itemDescription              ).
        jsonObject:add( 'num-projeto'   , projectNumber                ).
        jsonObject:add( 'descricao'     , projectDescription           ).
        jsonObject:add( 'narrativa'     , itemNarrative                ).
        jsonObject:add( 'narrativa-ord' , b-ordem-compra.narrativa     ).

        cast(payload, JsonArray):add( jsonObject ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose: Monta payload de uma solicitacao de compra aprovada
     Notes:   Logica baseada na procedure pi-solicitacao
    ------------------------------------------------------------------------------*/
    method private void appendPurchaseRequest().

        define variable jsonObject         as JsonObject no-undo.
        define variable itemDescription    as character  no-undo.
        define variable itemFamilyCode     as character  no-undo.
        define variable itemUnit           as character  no-undo.
        define variable itemContractType   as integer    no-undo.
        define variable itemNarrative      as character  no-undo.
        define variable strategicFlag      as character  no-undo.
        define variable buyerCode          as character  no-undo.
        define variable projectNumber      as integer    no-undo.
        define variable projectDescription as character  no-undo.

        find first b-requisicao no-lock
            where b-requisicao.nr-requisicao = b-it-requisicao.nr-requisicao
            no-error.

        loadItemData( b-it-requisicao.it-codigo,
                      output itemDescription   ,
                      output itemFamilyCode    ,
                      output itemUnit          ,
                      output itemContractType  ,
                      output itemNarrative     ).

        loadItemEstablishment( b-it-requisicao.it-codigo  ,
                               b-it-requisicao.cod-estabel,
                               output strategicFlag       ,
                               output buyerCode           ).

        loadInvestmentProject( b-it-requisicao.ep-codigo  ,
                               b-it-requisicao.num-ord-inv,
                               b-it-requisicao.cod-estabel,
                               output projectNumber       ,
                               output projectDescription  ).

        assign jsonObject = new JsonObject().

        jsonObject:add( 'nome'          , getRequesterName( b-requisicao.nome-abrev ) ).
        jsonObject:add( 'nr-requisicao' , b-it-requisicao.nr-requisicao  ).
        jsonObject:add( 'dt-requisicao' , StringUtil:formatIsoDate( b-requisicao.dt-requisicao ) ).
        jsonObject:add( 'situacao'      , getRequestStatusLabel()        ).
        jsonObject:add( 'numero-ordem'  , 0                              ).
        jsonObject:add( 'cod-comprado'  , buyerCode                      ).
        jsonObject:add( 'sit-ordem'     , ''                             ).
        jsonObject:add( 'nr-processo'   , 0                              ).
        jsonObject:add( 'qt-requisitada', b-it-requisicao.qt-requisitada ).
        jsonObject:add( 'preco-unit'    , b-it-requisicao.preco-unit     ).
        jsonObject:add( 'fm-codigo'     , itemFamilyCode                 ).
        jsonObject:add( 'un'            , itemUnit                       ).
        jsonObject:add( 'estrat'        , strategicFlag                  ).
        jsonObject:add( 'it-codigo'     , b-it-requisicao.it-codigo      ).
        jsonObject:add( 'narrativa'     , getNarrative( itemDescription, itemContractType ) ).
        jsonObject:add( 'num-projeto'   , projectNumber                  ).
        jsonObject:add( 'descricao'     , projectDescription             ).
        jsonObject:add( 'narrativa'     , itemNarrative                  ).

        cast(payload, JsonArray):add( jsonObject ).

    end method.

    /* Carrega dados do item pelo codigo */
    method private void loadItemData(  input  itemCode        as character ,
                                      output itemDescription  as character ,
                                      output itemFamilyCode   as character ,
                                      output itemUnit         as character ,
                                      output itemContractType as integer   ,
                                      output itemNarrative    as character ).

        assign itemDescription  = ''
               itemFamilyCode   = ''
               itemUnit         = ''
               itemContractType = 0.

        find first b-item no-lock
            where b-item.it-codigo = itemCode
            no-error.

        if available b-item then
            assign itemDescription  = b-item.desc-item
                   itemFamilyCode   = b-item.fm-codigo
                   itemUnit         = b-item.un
                   itemContractType = b-item.tipo-contr
                   itemNarrative    = b-item.narrativa.
                   

    end method.

    /* Resolve narrativa: tipo-contr = 4 prioriza requisicao/item-requisicao */
    method private character getNarrative( input  itemDescription as character,
                                           input  contractType   as integer   ).

        if contractType <> 4 then
            return itemDescription.

        if b-requisicao.narrativa <> '' then
            assign itemDescription = b-requisicao.narrativa.

        if b-it-requisicao.narrativa <> '' then
            assign itemDescription = b-it-requisicao.narrativa.

        return itemDescription.

    end method.

    /* Calcula saldo pendente dos prazos da ordem de compra */
    method private decimal getOutstandingBalance().

        define variable balance as decimal no-undo.
        
        for each prazo-compra of b-ordem-compra no-lock
            where prazo-compra.quant-saldo > 0.
            assign balance = balance + prazo-compra.quant-saldo.
        end.

        return balance.

    end method.

    /* Retorna label textual da situacao da ordem de compra */
    method private character getOrderStatusLabel().

        case b-ordem-compra.situacao.
            when OrderStatusEnum:NAO_CONFIRMADA:GetValue() then return 'Nao Confirmada'.
            when OrderStatusEnum:CONFIRMADA:GetValue()     then return 'Confirmada'.
            when OrderStatusEnum:COTADA:GetValue()         then return 'Cotada'.
            when OrderStatusEnum:EM_COTACAO:GetValue()     then return 'Em Cotacao'.
        end case.

        return ''.

    end method.

    /* Retorna label textual da situacao do item de requisicao */
    method private character getRequestStatusLabel().

        case b-it-requisicao.situacao.
            when RequestStatusEnum:ABERTA:GetValue()         then return 'Aberta'.
            when RequestStatusEnum:FECHADA:GetValue()        then return 'Fechada'.
            when RequestStatusEnum:PENDENTE_COMPL:GetValue() then return 'Pendente Compl'.
        end case.

        return 'Com Ordem'.

    end method.

    /* Retorna nome do requisitante pela abreviacao */
    method private character getRequesterName( input abbreviation as character ).

        find first requisitante no-lock
            where requisitante.nome-abrev = abbreviation
            no-error.

        return if available requisitante then requisitante.nome else ''.

    end method.

    /* Carrega dados do item-uni-estab (flag estrategico e comprador) */
    method private void loadItemEstablishment( input  itemCode          as character,
                                               input  establishmentCode as character,
                                               output strategicFlag     as character,
                                               output buyerCode         as character ).

        assign strategicFlag = 'Nao'
               buyerCode     = ''.

        find first item-uni-estab no-lock
            where item-uni-estab.it-codigo   = itemCode
              and item-uni-estab.cod-estabel = establishmentCode
            no-error.

        if available item-uni-estab then
            assign strategicFlag = if item-uni-estab.tp-ressup = 3 then 'SIM' else 'Nao'
                   buyerCode     = item-uni-estab.cod-comprado.

    end method.

    /* Carrega dados do projeto de investimento via sub-div-ordem/proj-inv */
    method private void loadInvestmentProject( input  companyCode         as character,
                                               input  investmentOrder     as integer  ,
                                               input  establishmentCode   as character,
                                               output projectNumber       as integer  ,
                                               output projectDescription  as character ).

        assign projectNumber      = 0
               projectDescription = ''.

        find first sub-div-ordem no-lock
            where sub-div-ordem.ep-codigo      = companyCode
              and sub-div-ordem.num-ord-magnus = investmentOrder
            no-error.

        if available sub-div-ordem then do:
            find first proj-inv no-lock
                where proj-inv.ep-codigo    = companyCode
                  and proj-inv.cod-est-exec = establishmentCode
                  and proj-inv.num-projeto  = sub-div-ordem.num-projeto
                no-error.

            if available proj-inv then
                assign projectNumber      = proj-inv.num-projeto
                       projectDescription = proj-inv.descricao.
        end.

    end method.

    /* Preco unitario com prioridade: cotacao-item > it-requisicao > ultima ordem-compra */
    method private decimal getUnitPrice().

        find first cotacao-item of b-ordem-compra no-lock
            where cotacao-item.cot-aprovada
            no-error.

        find first it-requisicao no-lock
            where it-requisicao.nr-requisicao = b-ordem-compra.nr-requisicao
              and it-requisicao.sequencia     = b-ordem-compra.sequencia
              and it-requisicao.it-codigo     = b-ordem-compra.it-codigo
            no-error.

        find last b-oc-preco no-lock
            where b-oc-preco.it-codigo     = b-ordem-compra.it-codigo
              and b-oc-preco.numero-ordem <> b-ordem-compra.numero-ordem
              and b-oc-preco.preco-unit    > 0
            no-error.

        return ( if available cotacao-item   then cotacao-item.preco-unit
            else if available it-requisicao  then it-requisicao.preco-unit
            else if available b-oc-preco     then b-oc-preco.preco-unit
            else 0 ).

    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method public override character onLoadData( register as recid ).

        find first b-ordem-compra no-lock
            where recid(b-ordem-compra) = register
            no-error.

        if available b-ordem-compra then
            return substitute( '&1', b-ordem-compra.numero-ordem ).

        find first b-it-requisicao no-lock
            where recid(b-it-requisicao) = register
            no-error.

        if available b-it-requisicao then
            return substitute( '&1#&2#&3',
                               b-it-requisicao.nr-requisicao,
                               b-it-requisicao.sequencia    ,
                               b-it-requisicao.it-codigo    ).

        undo, throw new Progress.Lang.AppError( 'Registro nao encontrado.', 17006 ).

    end method.

end class.

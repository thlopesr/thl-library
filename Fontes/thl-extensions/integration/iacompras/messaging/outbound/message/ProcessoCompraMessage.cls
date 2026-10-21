/*------------------------------------------------------------------------
    File        : ProcessoCompraMessage
    Purpose     : Envia dados de processo de compra para IA Compras
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Tue Sep 16 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.
using thl-lib.core.error.ThlError.
using thl-lib.integration.messaging.outbound.core.OutboundMessage.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-extensions.integration.iacompras.messaging.outbound.message.ProcessoCompraMessage inherits OutboundMessage.

    define private buffer b-proc-compra  for proc-compra.
    define private buffer b-proc-fornec  for proc-fornec.
    define private buffer b-emitente     for emitente.
    define private buffer b-cont-emit    for cont-emit.
    define private buffer b-ordem-compra for ordem-compra.
    define private buffer b-item         for item.
    define private buffer b-prazo-compra for prazo-compra.

    constructor public ProcessoCompraMessage ( objectName           as character ,
                                                applicationName      as character ,
                                                integrationOperation as character ,
                                                methodType           as integer   ,
                                                connectorType        as integer   ,
                                                integrationDirection as logical   ,
                                                executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor.

    method public override void appendPayloadObject().

        if not available b-proc-compra then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'appendPayloadObject', 'Registro de processo de compra nao encontrado.' ).

        this-object:initializeObjectPayload().

        buildProcessData  ().
        addSuppliers      ().
        addOrders         ().

    end method.

    /* Monta os campos raiz do processo */
    method private void buildProcessData().

        define variable processo as JsonObject no-undo.

        assign processo = cast(payload, JsonObject).

        processo:add( 'Processo'   , b-proc-compra.nr-processo  ).
        processo:add( 'Descricao'  , b-proc-compra.descricao    ).
        processo:add( 'Comprador'  , b-proc-compra.cod-comprado ).
        processo:add( 'Data_Inicio', StringUtil:formatIsoDate( b-proc-compra.dt-inicio ) ).
        processo:add( 'Narrativa'  , b-proc-compra.narrativa    ).

    end method.

    /* Monta array de fornecedores vinculados ao processo com contato sequencia 10 */
    method private void addSuppliers().

        define variable suppliers as JsonArray  no-undo.
        define variable supplier  as JsonObject no-undo.

        assign suppliers = new JsonArray().

        for each b-proc-fornec of b-proc-compra no-lock,
           first b-emitente no-lock
           where b-emitente.cod-emitente = b-proc-fornec.cod-emitente,
           first b-cont-emit no-lock
           where b-cont-emit.cod-emitente = b-emitente.cod-emitente
             and b-cont-emit.sequencia    = 10:

            assign supplier = new JsonObject().

            supplier:add( 'Fornec'    , b-proc-fornec.cod-emitente ).
            supplier:add( 'Nome_Abrev', b-emitente.nome-abrev      ).
            supplier:add( 'Nome'      , b-emitente.nome-emit       ).
            supplier:add( 'Email'     , b-cont-emit.e-mail         ).

            suppliers:add( supplier ).
        end.

        cast(payload, JsonObject):add( 'Fornecedor', suppliers ).

    end method.

    /* Monta array de ordens de compra vinculadas ao processo */
    method private void addOrders().

        define variable orders as JsonArray  no-undo.
        define variable order  as JsonObject no-undo.

        assign orders = new JsonArray().

        for each b-ordem-compra no-lock
           where b-ordem-compra.nr-processo = b-proc-compra.nr-processo,
           first b-item no-lock
           where b-item.it-codigo = b-ordem-compra.it-codigo:

            assign order = new JsonObject().

            order:add( 'Ordem'    , b-ordem-compra.numero-ordem ).
            order:add( 'Item'     , b-ordem-compra.it-codigo    ).
            order:add( 'Descricao', b-item.desc-item            ).
            order:add( 'Qtd'      , calculateOrderQuantity()    ).

            orders:add( order ).
        end.

        cast(payload, JsonObject):add( 'Ordem', orders ).

    end method.

    /* Soma quantidade dos prazos da ordem de compra corrente */
    method private decimal calculateOrderQuantity().

        define variable dQuantity as decimal no-undo.

        for each b-prazo-compra fields (numero-ordem quantidade) no-lock
           where b-prazo-compra.numero-ordem = b-ordem-compra.numero-ordem:
            assign dQuantity = dQuantity + b-prazo-compra.quantidade.
        end.

        return dQuantity.

    end method.

    method protected override character onLoadData( register as recid ).

        find first b-proc-compra no-lock
            where recid(b-proc-compra) = register
            no-error.

        if not available b-proc-compra then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'onLoadData', 'Registro de processo de compra nao encontrado.' ).

        return substitute( '&1', b-proc-compra.nr-processo ).

    end method.

end class.

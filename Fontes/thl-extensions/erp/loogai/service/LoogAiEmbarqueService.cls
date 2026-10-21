/*------------------------------------------------------------------------
    File        : LoogAiEmbarqueService
    Purpose     : Especializacao de EmbarqueService para a Loog.ai.
                  Concentra as particularidades do contrato Loog.ai:
                  estabelecimento por CNPJ, usuario fixo 'loogai', data de
                  embarque/entrega correntes e sequencia unica - campos que
                  o integrador nao envia no payload.
    Author(s)   : Lopes
    Created     : 2026-07-30
    Notes       : Segue o mesmo padrao de LoogAiDocumentoService.
                  Em 2026-09-30 passou a gravar ext-embarque (valorFrete,
                  telefoneMotorista) na criacao e na alteracao.
                  Em 2026-07-31 os defaults sairam de
                  LoogAiEmbarqueMessage:methodPost (que enriquecia o
                  payload) para hooks aqui - o Service passa a funcionar
                  tambem quando chamado fora do fluxo de mensageria.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.erp.service.EmbarqueService.
using thl-lib.util.json.JsonUtil.

block-level on error undo, throw.

class thl-extensions.erp.loogai.service.LoogAiEmbarqueService inherits EmbarqueService.

    define private temp-table tt-deposito no-undo
        field sequen as integer
        field cod-depos like deposito.cod-depos
        index ch-aeq-dep is primary unique sequen.

    define private static property EXTENSION_FIELDS as character no-undo
        init 'valorFrete,telefoneMotorista' get.

    //lookup de estabelecimento por CNPJ (contrato Loog.ai)
    method protected override void resolveEstablishment().

        find first b-estabelec no-lock
            where b-estabelec.cgc = inContext:GetCharacter( 'codigoEstabelecimento' )
            no-error.

        if not available b-estabelec then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEstablishment',
                'Estabelecimento nao localizado.' ).

    end method.

    //usuario fixo: identifica no ERP que o embarque veio da Loog.ai
    method protected override character resolveIntegrationUser().
        return 'loogai'.
    end method.

    //o contrato Loog.ai nao envia data de embarque - assume a data corrente
    method protected override date resolveShipmentDate().
        return today.
    end method.

    //o contrato Loog.ai trata uma viagem como embarque unico
    method protected override integer resolveSequence().
        return 1.
    end method.

    //o contrato Loog.ai nao envia data por entrega - assume a data corrente
    method protected override date resolveDeliveryDate( input delivery as JsonObject ).
        return today.
    end method.
    
    //depositos de alocacao: o parametro de deposito exclusivo (param-dep-exc)
    //do estabelecimento + tipo de operacao do pedido; sem ele, todos os
    //depositos de acabado que nao sao exclusivos de outra operacao
    method protected override void prepareWarehouseData().

        define variable sequen as integer initial 1 no-undo.

        empty temp-table tt-deposito no-error.

        find first param-dep-exc no-lock
             where param-dep-exc.cod-estabel       = b-ped-venda.cod-estabel
               and param-dep-exc.cdn-tipo-op-venda = integer( substring( b-ped-venda.char-1,162,5 ) )
            no-error.

        if available param-dep-exc then do.
            if can-find( first tt-deposito
                            where tt-deposito.cod-depos = param-dep-exc.cod-depos ) then return.
            create tt-deposito.
            assign tt-deposito.sequen    = sequen
                   tt-deposito.cod-depos = param-dep-exc.cod-depos.
        end.
        else do.

            for each deposito fields (cod-depos ind-acabado)
               where deposito.ind-acabado.

                if can-find( first param-dep-exc
                                where param-dep-exc.cod-estabel = b-ped-venda.cod-estabel
                                  and param-dep-exc.cod-depos   = deposito.cod-depos ) then next.

                if can-find( first tt-deposito
                                where tt-deposito.cod-depos = deposito.cod-depos ) then next.

                create tt-deposito.
                assign tt-deposito.sequen    = sequen
                       tt-deposito.cod-depos = deposito.cod-depos.

                assign sequen = sequen + 1.

            end.

        end.

        if not temp-table tt-deposito:has-records then
            return.

        empty temp-table tt-erro no-error.

        run pi-elimina-tt-deposito in eqapi300.
        run pi-recebe-tt-deposito  in eqapi300 (  input table tt-deposito).
        run pi-devolve-tt-erro     in eqapi300 ( output table tt-erro ).

        this-object:throwApiErrorsIfAny(
            'prepareWarehouseData',
            substitute(
                'Alocar Pedido &1',
                b-ped-venda.nr-pedcli
            )
        ).

    end method.

    //criacao: embarque via base + dados complementares em ext-embarque
    method public override void create().

        super:create().

        inContext:add( 'codigoEmbarque',  string( inContext:GetDecimal('embarque') ) ).

        //a base devolve o codigo gerado em codigoEmbarque
        this-object:saveShipmentExtension( inContext:GetDecimal( 'embarque' ) ).

    end method.

    //alteracao: transporte via base + dados complementares em ext-embarque
    method public override void update().

        super:update().

        this-object:saveShipmentExtension( inContext:GetDecimal( 'embarque' ) ).

    end method.

    //grava ext-embarque (valor do frete e telefone do motorista). Os dois
    //campos sao opcionais: sem nenhum deles nao grava; ausente mantem o valor atual
    method private void saveShipmentExtension( input shipmentCode as decimal ).

        if not JsonUtil:hasAnyProperty( inContext, EXTENSION_FIELDS ) then
            return.

        find first ext-embarque exclusive-lock
            where ext-embarque.cdd-embarq = shipmentCode
            no-error.

        if not available ext-embarque then do.
            create ext-embarque.
            assign ext-embarque.cdd-embarq = shipmentCode.
        end.
        
        assign ext-embarque.telefone-motorista = if inContext:has('telefoneMotorista')    then inContext:GetCharacter( 'telefoneMotorista')
                                                                                          else '' 
               ext-embarque.valor-frete        = if inContext:GetType( 'valorFrete' ) = 1 then 
                                                    if inContext:GetCharacter( 'valorFrete' ) = '' then 0
                                                                                                   else decimal( inContext:GetCharacter( 'valorFrete' ) )
                                                                                          else inContext:GetDecimal( 'valorFrete' ). 

        release ext-embarque.

    end method.

end class.

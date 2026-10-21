/*------------------------------------------------------------------------
    File        : EmbarqueService
    Purpose     : Servico de dominio generico para criacao, alteracao
                  (dados de transporte) e exclusao de embarques Datasul
                  via API eqapi300. Orquestra o fluxo completo: validacao,
                  montagem de tt-embarque/tt-ped-ent, chamada da API e
                  encerramento.
                  Hooks protected permitem que extensoes (ex:
                  LoogAiEmbarqueService) especializem o mapeamento de
                  dados sem repetir a orquestracao de API.
    Author(s)   : Lopes
    Created     : 2026-07-17
    Notes       : Herda ApplicationProgrammingInterface (tt-erro + throwApiErrorsIfAny).
                  Movido de integration.messaging.inbound.service para
                  erp.service em 2026-07-24 (sessao 6).
                  Refatorado em 2026-07-30 - hooks protected extraidos
                  para extensibilidade (mesma abordagem de DocumentoService).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.ApplicationProgrammingInterface.
using thl-lib.erp.enum.SituacaoEmbarqueEnum.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.

block-level on error undo, throw.

class thl-lib.erp.service.EmbarqueService inherits ApplicationProgrammingInterface.

    define protected buffer b-estabelec for estabelec.
    define protected buffer b-ped-venda for ped-venda.

    define protected temp-table tt-embarque no-undo like embarque use-index ch-emb
        field i-sequen as integer
        field ind-oper as integer.

    define protected temp-table tt-ped-ent no-undo
        field nome-abrev          like ped-ent.nome-abrev
        field nr-pedcli           like ped-ent.nr-pedcli
        field nr-sequencia        like ped-ent.nr-sequencia
        field it-codigo           like ped-ent.it-codigo
        field cod-refer           like ped-ent.cod-refer
        field qt-alocada          like ped-ent.qt-alocada
        field qt-log-aloca        like ped-ent.qt-log-aloca
        field qt-pedida           like ped-ent.qt-pedida
        field qt-atendida         like ped-ent.qt-atendida
        field dt-entrega          like ped-ent.dt-entrega
        field nr-entrega          like ped-ent.nr-entrega
        field hr-entrega          like ped-ent.hr-entrega
        field nr-proc-exp         like ped-ent.nr-proc-exp
        field num-sequencia-bonif like ped-item.num-sequencia-bonif
        field nat-operacao        like ped-item.nat-operacao
        field dec-1               like ped-ent.dec-1
        field qt-a-alocar         as decimal
        field i-sequen            as integer
        field cdd-embarq          as decimal
        field nr-seq-registro     as integer init 1
        index ch-ent is primary
            nr-proc-exp nome-abrev nr-pedcli nr-sequencia
            it-codigo cod-refer nr-entrega.

    define protected temp-table tt-ped-venda no-undo
        field i-sequen   as integer
        field cdd-embarq like embarque.cdd-embarq
        field nome-abrev like ped-venda.nome-abrev
        field nr-pedcli  like ped-venda.nr-pedcli
        field ind-oper   as integer
        index ch-pedido is primary nome-abrev nr-pedcli.

    define protected static property OPER_INCLUSAO          as integer no-undo init 1 get.
    define protected static property OPER_ALTER_EMBARQ      as integer no-undo init 2 get.
    define protected static property OPER_ELIMINACAO_EMBARQ as integer no-undo init 3 get.
    define protected static property OPER_ELIMINACAO_PED    as integer no-undo init 2 get.
    define protected static property MAX_SEQ_RETRIES        as integer no-undo init 3 get.

    define protected property eqapi300  as handle     no-undo get. protected set.

    method public override character getEntityName().
        return 'Embarque'.
    end method.

    method public override character loadReferenceCode().
        return string( inContext:GetDecimal( 'embarque' ) ).
    end method.

    //criar embarque completo: validar, montar, processar API, alocar entregas, encerrar
    method public override void create().

        define variable shipmentCode as decimal no-undo.
        define variable deliveries   as JsonArray  no-undo.
        define variable deliveryIdx  as integer    no-undo.
        define variable retryCount   as integer    no-undo.

        this-object:validateShipmentContext().

        this-object:resolveEstablishment().

        //retry para proteger contra concorrencia no sequencial
        do retryCount = 1 to MAX_SEQ_RETRIES:
            find last embarque exclusive-lock no-wait no-error.
            if not locked embarque then leave.
            if retryCount = MAX_SEQ_RETRIES then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'create',
                    'Sequencial de embarque em uso por outro processo apos 3 tentativas.' ).
            pause 1 no-message.
        end.
        
        assign shipmentCode = if available embarque then embarque.cdd-embarq + 1 else 1
               deliveries   = inContext:GetJsonArray( 'entregas' ).

        release embarque no-error.
        
        inContext:add( 'embarque',  shipmentCode ).

        run eqp/eqapi300.p persistent set eqapi300.

        empty temp-table tt-embarque no-error.

        this-object:findSalesOrderOrThrow( deliveries:GetJsonObject(1):GetInteger('numeroPedido') ).
        this-object:prepareShipmentData( shipmentCode ).
        this-object:processShipment().
        
        do deliveryIdx = 1 to deliveries:Length.
            this-object:findSalesOrderOrThrow( deliveries:GetJsonObject( deliveryIdx ):GetInteger('numeroPedido') ).
            this-object:prepareDeliveryData( shipmentCode, deliveryIdx, deliveries:GetJsonObject( deliveryIdx ) ).
            this-object:prepareWarehouseData().
        end.

        this-object:closeShipment().

        finally.
            if valid-handle( eqapi300 ) then
                run pi-finalizar in eqapi300 no-error.
        end finally.

    end method.

    //hook: localizar estabelecimento a partir do payload
    method protected void resolveEstablishment().

        find first b-estabelec no-lock
            where b-estabelec.cod-estabel = inContext:GetCharacter( 'codigoEstabelecimento' )
            no-error.

        if not available b-estabelec then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEstablishment',
                'Estabelecimento nao localizado.' ).

    end method.

    //hook: montar tt-embarque com dados do cabecalho a partir do payload
    method protected void prepareShipmentData( input shipmentCode   as decimal ).

        define variable jsonSetter as JsonSetter no-undo.
        define variable cUser      as character  no-undo.

        assign jsonSetter = new JsonSetter( inContext )
               cUser      = this-object:resolveIntegrationUser().
               
        find first proc-ped-venda no-lock
            where proc-ped-venda.nr-pedcli  = b-ped-venda.nr-pedcli 
              and proc-ped-venda.nome-abrev = b-ped-venda.nome-abrev 
            no-error
            .
            
        create tt-embarque.
        assign tt-embarque.cdd-embarq  = shipmentCode
               tt-embarque.usuario     = cUser
               tt-embarque.identific   = cUser
               tt-embarque.cod-estabel = b-estabelec.cod-estabel
               tt-embarque.situacao    = SituacaoEmbarqueEnum:ATIVA:GetValue( )
               tt-embarque.ind-oper    = OPER_INCLUSAO
               tt-embarque.dt-embarque = this-object:resolveShipmentDate()
               tt-embarque.i-sequen    = this-object:resolveSequence    ()
               tt-embarque.nr-proc-exp = if available proc-ped-venda then proc-ped-venda.nr-proc-exp
                                                                     else ''
               .
    
        //Dados de transporte sao opcionais - ausentes no payload
        //permanecem em branco (semantica do JsonSetter)
        jsonSetter:SetValue( input-output tt-embarque.cod-tipo   , input 'codigoTipo'         ).
        jsonSetter:SetValue( input-output tt-embarque.cod-rota   , input 'codigoRota'         ).
        jsonSetter:SetValue( input-output tt-embarque.nome-transp, input 'nomeTransportadora' ).
        jsonSetter:SetValue( input-output tt-embarque.placa      , input 'placa'              ).

    end method.

    //hook: resolver usuario de integracao a partir do payload
    method protected character resolveIntegrationUser().

        if inContext:Has( 'codigoUsuario' ) then
            return inContext:GetCharacter( 'codigoUsuario' ).

        undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveIntegrationUser',
            'codigoUsuario nao informado no payload.' ).

    end method.

    //hook: resolver data do embarque. O contrato generico exige o campo
    //(getRequiredFields); extensoes com contrato proprio sobrescrevem.
    method protected date resolveShipmentDate().

        if inContext:Has( 'dataEmbarque' ) then
            return inContext:GetDate( 'dataEmbarque' ).

        undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveShipmentDate',
            'dataEmbarque nao informada no payload.' ).

    end method.

    //hook: resolver sequencia do embarque
    method protected integer resolveSequence().

        if inContext:Has( 'sequencia' ) then
            return inContext:GetInteger( 'sequencia' ).

        undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveSequence',
            'sequencia nao informada no payload.' ).

    end method.

    //hook: resolver data de uma entrega individual
    method protected date resolveDeliveryDate( input delivery as JsonObject ).

        if delivery:Has( 'dataEntrega' ) then
            return delivery:GetDate( 'dataEntrega' ).

        undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveDeliveryDate',
            'dataEntrega nao informada na entrega.' ).

    end method.
    
    //hook: definir depositos de alocacao da entrega corrente (b-ped-venda) no
    //eqapi300. Vazio na base: a API usa o comportamento padrao.
    method protected void prepareWarehouseData().
    end method.

    method private void findSalesOrderOrThrow( input deliveryNumber as integer ).
        
        find first b-ped-venda no-lock
            where b-ped-venda.nr-pedido = deliveryNumber
            no-error.

        if not available b-ped-venda then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'findSalesOrderOrThrow',
                substitute(
                    'Pedido de venda nao localizado &1',
                    deliveryNumber
                )
            ).
            
    end method.
    
    //hook: preparar e alocar uma entrega individual via API
    method protected void prepareDeliveryData( input shipmentCode  as decimal    ,
                                               input deliveryIndex as integer    ,
                                               input delivery      as JsonObject ).

        empty temp-table tt-ped-ent no-error.

        find first ped-ent no-lock
            where ped-ent.nome-abrev   = b-ped-venda.nome-abrev
              and ped-ent.nr-pedcli    = b-ped-venda.nr-pedcli
              and ped-ent.nr-sequencia = delivery:GetInteger  ( 'sequenciaItem'  )
              and ped-ent.it-codigo    = delivery:GetCharacter( 'codigoProduto'  )
              and ped-ent.nr-entrega   = delivery:GetInteger  ( 'numeroEntrega'  )
            no-error.

        if not available ped-ent then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'prepareDeliveryData',
                substitute( 'Entrega do pedido &1/&2/&3 nao localizada.',
                            b-ped-venda.nr-pedcli                       ,
                            delivery:GetInteger( 'sequenciaItem'  )     ,
                            delivery:GetInteger( 'numeroEntrega'  ) ) ).

        create tt-ped-ent.
        buffer-copy ped-ent to tt-ped-ent
            assign tt-ped-ent.cdd-embarq  = shipmentCode
                   tt-ped-ent.dt-entrega  = this-object:resolveDeliveryDate( delivery )
                   tt-ped-ent.qt-a-alocar = delivery:GetDecimal( 'quantidade'  )
                   tt-ped-ent.i-sequen    = delivery:GetInteger( 'sequencia'   ).

        empty temp-table tt-erro no-error.

        run pi-recebe-tt-ped-ent in eqapi300 ( input table tt-ped-ent ).
        run pi-trata-tt-ped-ent  in eqapi300 ( input true ).
        run pi-devolve-tt-erro   in eqapi300 ( output table tt-erro ).

        this-object:throwApiErrorsIfAny(
            'prepareDeliveryData',
            substitute(
                'Alocar Pedido &1/&2/&3',
                ped-ent.nr-pedcli       ,
                ped-ent.nr-sequencia    ,
                ped-ent.nr-entrega
            )
        ).

    end method.
    
    //alterar dados de transporte do embarque (PATCH, ind-oper OPER_ALTER_EMBARQ).
    //So os campos presentes no payload mudam; os demais mantem o valor atual.
    method public override void update().

        define variable jsonSetter as JsonSetter no-undo.

        find first embarque no-lock
            where embarque.cdd-embarq = inContext:GetDecimal( 'embarque' )
            no-error.

        if not available embarque then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update',
                substitute( 'Embarque &1 nao localizado.', inContext:GetDecimal( 'embarque' ) ) ).


        assign jsonSetter = new JsonSetter( inContext ).

        run eqp/eqapi300.p persistent set eqapi300.

        empty temp-table tt-embarque no-error.

        //parte do registro atual para a API nao receber os demais campos em branco
        create tt-embarque.
        buffer-copy embarque to tt-embarque
            assign tt-embarque.i-sequen = 1
                   tt-embarque.ind-oper = OPER_ALTER_EMBARQ.

        jsonSetter:SetValue( input-output tt-embarque.nome-transp, input 'nomeTransportadora' ).
        jsonSetter:SetValue( input-output tt-embarque.motorista  , input 'motorista'          ).
        jsonSetter:SetValue( input-output tt-embarque.placa      , input 'placa'              ).
        jsonSetter:SetValue( input-output tt-embarque.uf-placa   , input 'ufPlaca'            ).

        this-object:processShipment().

        finally.
            if valid-handle( eqapi300 ) then
                run pi-finalizar in eqapi300 no-error.
        end finally.

    end method.

    //excluir embarque: desalocar pre-faturas e processar exclusao
    method public override void delete().

        define variable deliveryIdx as integer no-undo initial 1.

        find first embarque no-lock
            where embarque.cdd-embarq = inContext:GetDecimal( 'embarque' )
            no-error.

        if not available embarque then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
                'Embarque nao localizado.' ).

        run eqp/eqapi300.p persistent set eqapi300.

        empty temp-table tt-embarque no-error.

        create tt-embarque.
        assign tt-embarque.cdd-embarq = embarque.cdd-embarq
               tt-embarque.i-sequen   = 1
               tt-embarque.ind-oper   = OPER_ELIMINACAO_EMBARQ.

        do transaction.

            for each pre-fatur no-lock
                where pre-fatur.cdd-embarq = embarque.cdd-embarq.
                create tt-ped-venda.
                assign tt-ped-venda.i-sequen   = deliveryIdx
                       tt-ped-venda.cdd-embarq = pre-fatur.cdd-embarq
                       tt-ped-venda.nome-abrev = pre-fatur.nome-abrev
                       tt-ped-venda.nr-pedcli  = pre-fatur.nr-pedcli
                       tt-ped-venda.ind-oper   = OPER_ELIMINACAO_PED
                       deliveryIdx             = deliveryIdx + 1.
            end.

            run pi-recebe-tt-ped-venda in eqapi300 ( input table tt-ped-venda ).
            run pi-trata-tt-ped-venda  in eqapi300 ( input yes ).
            run pi-devolve-tt-erro     in eqapi300 ( output table tt-erro ).

            this-object:throwApiErrorsIfAny( 'delete' ).

            this-object:processShipment().

        end.

        finally.
            if valid-handle( eqapi300 ) then
                run pi-finalizar in eqapi300 no-error.
        end finally.

    end method.

    //enviar tt-embarque ao eqapi300 e validar erros
    method private void processShipment().

        empty temp-table tt-erro no-error.

        run pi-recebe-tt-embarque in eqapi300 ( input table tt-embarque ).
        run pi-trata-tt-embarque  in eqapi300 ( input 'mgs', input true ).
        run pi-devolve-tt-erro    in eqapi300 ( output table tt-erro ).

        this-object:throwApiErrorsIfAny( 'processShipment' ).

    end method.

    //encerrar embarque via eqapi300
    method private void closeShipment().

        empty temp-table tt-erro no-error.

        run pi-recebe-tt-embarque in eqapi300 ( input table tt-embarque ).
        run pi-encerra-embarque   in eqapi300 ( input true ).
        run pi-devolve-tt-erro    in eqapi300 ( output table tt-erro ).

        this-object:throwApiErrorsIfAny( 'closeShipment' ).

    end method.

    //validar que o payload contem pelo menos uma entrega
    method protected void validateShipmentContext().

        if inContext:GetJsonArray( 'entregas' ):Length = 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateShipmentContext',
                'Nenhuma entrega informada para geracao do embarque.' ).

    end method.

    method public override JsonObject buildResponse( input action        as ActionEnum,
                                                     input referenceCode as character ).
                                               
                                               
        define variable response as JsonObject no-undo.

        assign response = new JsonObject().

        response:Add( 'success' , true          ).
        response:Add( 'code'    , 200           ).
        response:Add( 'message' , substitute ('Embarque &1 com sucesso.', lc(action:toString()) ) ).
        response:Add( 'embarque', inContext:GetDecimal( 'embarque' ) ).

        return response.

    end method.

end class.

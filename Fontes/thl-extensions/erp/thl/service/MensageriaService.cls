/*------------------------------------------------------------------------
    File        : MensageriaService
    Purpose     : Servico de dominio para consulta de mensagens de
                  integracao (thl-mensagem). Somente leitura - busca por
                  ranges (padrao thl0120), detalhe por codigo.
    Author(s)   : Lopes
    Created     : Wed Sep 10 2026
    Notes       : Segue padrao canonico LpcoService - herda Service,
                  paginacao via PaginationHelper (composicao).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.enum.MessageStatusEnum.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.connectors.enum.ConnectorTypeEnum.
using thl-lib.util.date.DateTimeUtil.
using thl-lib.util.pagination.PaginationHelper.
using thl-lib.core.context.ContextService.
using thl-extensions.erp.thl.interfaces.IMetricsService.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.MensageriaService inherits Service implements IMetricsService.

    define private buffer b-mensagem          for thl-mensagem.
    
    method public override character getEntityName().
        return 'Mensageria'.
    end method.

    method public override character loadReferenceCode().
        if available b-mensagem then
            return b-mensagem.codigo-mensagem.
        return ''.
    end method.

    //Consulta: a listagem. Datas de criacao e integracao em yyyy-MM-ddTHH:mm (mesmo
    //formato das metricas); padrao: as ultimas 24 horas. Metricas e consultMetrics(), chamado pelo Processor;
    //a operacao conteudo e desviada por ele para o MensageriaConteudoService.
    method public override JsonConstruct consult().

        //padrao das duas faixas: ultimas 24 horas
        return this-object:get( queryParameters:getPager( 1000 ),
                                queryParameters:getText( 'codigoIni'   , ''               ),
                                queryParameters:getText( 'codigoFin'   , fill( 'z', 64 )  ),
                                queryParameters:getText( 'objetoIni'   , ''               ),
                                queryParameters:getText( 'objetoFin'   , fill( 'z', 60 )  ),
                                queryParameters:getText( 'operacaoIni' , ''               ),
                                queryParameters:getText( 'operacaoFin' , fill( 'z', 60 )  ),
                                queryParameters:getText( 'aplicacaoIni', ''               ),
                                queryParameters:getText( 'aplicacaoFin', fill( 'z', 100 ) ),
                                queryParameters:getDateTime( 'dtCriacaoIni'   , DateTimeUtil:addHours( now, -24 ) ),
                                queryParameters:getDateTime( 'dtCriacaoFin'   , DateTimeUtil:currentDateTime()      ),
                                queryParameters:getDateTime( 'dtIntegracaoIni', DateTimeUtil:addHours( now, -24 ) ),
                                queryParameters:getDateTime( 'dtIntegracaoFin', DateTimeUtil:currentDateTime()      ) ).

    end method.

    //Metricas do periodo (IMetricsService): padrao, as ultimas 24 horas
    method public JsonConstruct consultMetrics().
        return this-object:getMetrics( queryParameters:getDateTime( 'dtCriacaoIni', DateTimeUtil:addHours( now, -24 ) ),
                                       queryParameters:getDateTime( 'dtCriacaoFin', DateTimeUtil:currentDateTime()    )).
    end method.

    method public JsonArray get ( pager           as PaginationHelper ,
                                  codigoIni       as character        ,
                                  codigoFin       as character        ,
                                  objetoIni       as character        ,
                                  objetoFin       as character        ,
                                  operacaoIni     as character        ,
                                  operacaoFin     as character        ,
                                  aplicacaoIni    as character        ,
                                  aplicacaoFin    as character        ,
                                  dtCriacaoIni    as datetime         ,
                                  dtCriacaoFin    as datetime         ,
                                  dtIntegracaoIni as datetime         ,
                                  dtIntegracaoFin as datetime         ).

        define variable messages as JsonArray no-undo.
        define variable user_    as character no-undo.

        assign user_    = ContextService:getErpUser()
               messages = new JsonArray().

        for each thl-objeto-usuario no-lock
            where thl-objeto-usuario.cod-usuario  = user_ 
              and thl-objeto-usuario.aplicacao   >= aplicacaoIni
              and thl-objeto-usuario.aplicacao   <= aplicacaoFin
              and thl-objeto-usuario.objeto      >= objetoIni
              and thl-objeto-usuario.objeto      <= objetoFin,
            each b-mensagem no-lock
                where b-mensagem.aplicacao        = thl-objeto-usuario.aplicacao
                  and b-mensagem.objeto           = thl-objeto-usuario.objeto
                  and b-mensagem.dt-criacao      >= dtCriacaoIni
                  and b-mensagem.dt-criacao      <= dtCriacaoFin
                  and ( b-mensagem.dt-integracao >= dtIntegracaoIni
                  and   b-mensagem.dt-integracao <= dtIntegracaoFin
                   or   b-mensagem.dt-integracao  = ? )
                  and b-mensagem.operacao        >= operacaoIni
                  and b-mensagem.operacao        <= operacaoFin
                  and b-mensagem.codigo-mensagem >= codigoIni
                  and b-mensagem.codigo-mensagem <= codigoFin.
                  
            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            messages:Add( buildMessageJson() ).

        end.

        return messages.

    end method.

    method public JsonArray getMetrics ( dtCriacaoIni as datetime ,
                                         dtCriacaoFin as datetime ).

        define variable objects        as JsonArray  no-undo.
        define variable objectItem     as JsonObject no-undo.
        define variable objectMessages as JsonArray  no-undo.
        define variable msg            as JsonObject no-undo.

        assign objects = new JsonArray().

        for each thl-aplicacao no-lock.

            for each thl-objeto no-lock
                where thl-objeto.aplicacao = thl-aplicacao.aplicacao.

                assign objectMessages = new JsonArray().

                for each b-mensagem no-lock
                    where b-mensagem.aplicacao   = thl-objeto.aplicacao
                      and b-mensagem.objeto      = thl-objeto.objeto
                      and b-mensagem.dt-criacao >= dtCriacaoIni
                      and b-mensagem.dt-criacao <= dtCriacaoFin.

                    assign msg = new JsonObject().

                    msg:Add( 'dispositivo'     , getDirectionLabel( b-mensagem.sentido-fluxo ) ).
                    msg:Add( 'sitRequisicao'   , getStatusLabel( b-mensagem.sit-requisicao   ) ).
                    msg:Add( 'sitProcessamento', getStatusLabel( b-mensagem.sit-processamento) ).
                    msg:Add( 'sitRetorno'      , getStatusLabel( b-mensagem.sit-retorno      ) ).
                    msg:Add( 'dtCriacao'       , b-mensagem.dt-criacao ).

                    objectMessages:Add( msg ).

                end.

                if objectMessages:Length = 0 then
                    next.

                assign objectItem = new JsonObject().

                objectItem:Add( 'aplicacao', thl-objeto.aplicacao ).
                objectItem:Add( 'objeto'   , thl-objeto.objeto    ).
                objectItem:Add( 'interna'  , thl-aplicacao.ind-interna ).
                objectItem:Add( 'mensagens', objectMessages       ).

                objects:Add( objectItem ).

            end.

        end.

        return objects.

    end method.

    method private JsonObject buildMessageJson().

        define variable msg as JsonObject no-undo.

        assign msg = new JsonObject().

        msg:Add( 'id',                  b-mensagem.codigo-mensagem ).
        msg:Add( 'codMsg',              b-mensagem.codigo-mensagem ).
        msg:Add( 'objeto',              b-mensagem.objeto          ).
        msg:Add( 'operacao',            b-mensagem.operacao        ).
        msg:Add( 'aplicacao',           b-mensagem.aplicacao       ).
        msg:Add( 'modelo',              getConnectorTypeLabel( b-mensagem.modelo-integracao ) ).
        msg:Add( 'metodo',              getMethodLabel( b-mensagem.metodo ) ).
        msg:Add( 'dispositivo',         getDirectionLabel( b-mensagem.sentido-fluxo ) ).
        msg:Add( 'dtIntegracao',        if b-mensagem.dt-integracao <> ? then iso-date( b-mensagem.dt-integracao ) else '' ).
        msg:Add( 'dtCriacao',           if b-mensagem.dt-criacao    <> ? then iso-date( b-mensagem.dt-criacao )    else '' ).
        msg:Add( 'statusRequisicao',    getStatusLabel( b-mensagem.sit-requisicao    ) ).
        msg:Add( 'statusRetorno',       getStatusLabel( b-mensagem.sit-retorno       ) ).
        msg:Add( 'statusProcessamento', getStatusLabel( b-mensagem.sit-processamento ) ).
        msg:Add( 'statusMensagem',      getStatusLabel( b-mensagem.sit-mensagem      ) ).
        msg:Add( 'destino',             b-mensagem.destino            ).
        msg:Add( 'codStatusRetorno',    b-mensagem.cod-status-retorno ).
        msg:Add( 'descrRetorno',        b-mensagem.descr-retorno      ).
        
        msg:Add( 'conteudo',             hasDetails() ).
        
        return msg.

    end method.
    
    method private logical hasDetilValue( input contemType as integer ).
        return can-find( first thl-mensagem-conteudo of b-mensagem no-lock
                            where thl-mensagem-conteudo.tipo-conteudo = contemType ).
    end method.
    
    method public JsonObject hasDetails( ).

        define variable detail as JsonObject no-undo.
        
        assign detail = new JsonObject().

        detail:Add( 'temRequisicao', hasDetilValue( integer( DirectionEnum:INBOUND  ) ) ).
        detail:Add( 'temResposta'  , hasDetilValue( integer( DirectionEnum:OUTBOUND ) ) ).

        return detail.

    end method.

    method private character getStatusLabel( statusValue as integer ).
        case statusValue:
            when MessageStatusEnum:PENDING:GetValue()        then return 'Pendente'.
            when MessageStatusEnum:ERROR:GetValue()          then return 'Erro'.
            when MessageStatusEnum:SUCCESS:GetValue()        then return 'Sucesso'.
            when MessageStatusEnum:NOT_APPLICABLE:GetValue() then return 'N/A'.
            otherwise                                             return ''.
        end case.

    end method.

    method private character getMethodLabel( methodValue as integer ).
        return MethodTypeEnum:GetEnum(methodValue):toString().
    end method.

    method private character getConnectorTypeLabel( connectorType as integer ).
        return ConnectorTypeEnum:GetEnum(connectorType):toString().
    end method.

    method private character getDirectionLabel( direction as logical ).
        if direction then return 'Saida'.
        return 'Entrada'.
    end method.

end class.

/*------------------------------------------------------------------------
    File        : EmailService
    Purpose     : Servico de dominio para consulta de registros de
                  e-mail (thl-email). Somente leitura - busca por
                  ranges de data-envio, id e cod-prog-dtsul com paginacao.
    Author(s)   : Lopes
    Created     : Mon Sep 15 2026
    Notes       : Segue padrao canonico MensageriaService - herda Service,
                  paginacao via PaginationHelper (composicao).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.erp.core.Service.
using thl-lib.util.date.DateTimeUtil.
using thl-lib.util.pagination.PaginationHelper.
using thl-lib.core.context.ContextService.
using thl-extensions.erp.thl.interfaces.IMetricsService.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.EmailService inherits Service implements IMetricsService.

    define private buffer b-email for thl-email.

    method public override character getEntityName().
        return 'Email'.
    end method.

    method public override character loadReferenceCode().
        if available b-email then
            return b-email.id.
        return ''.
    end method.

    //Metricas do periodo (IMetricsService): padrao, as ultimas 24 horas.
    //Chamado pelo MetricsProcessor na operacao metricas.
    method public JsonConstruct consultMetrics().
        return this-object:getMetrics( queryParameters:getDateTime( 'dtEnvioIni', DateTimeUtil:addHours( now, -24 ) ),
                                       queryParameters:getDateTime( 'dtEnvioFin', DateTimeUtil:currentDateTime()    ) ).
    end method.

    //Consulta: a listagem
    method public override JsonConstruct consult().

        return this-object:get( queryParameters:getPager( 1000 ),
                                queryParameters:getDateTime( 'dtEnvioIni', DateTimeUtil:addHours( now, -24 ) ),
                                queryParameters:getDateTime( 'dtEnvioFin', DateTimeUtil:currentDateTime()    ),
                                queryParameters:getText( 'idIni'          , ''              ),
                                queryParameters:getText( 'idFin'          , fill( 'z', 64 ) ),
                                queryParameters:getText( 'codProgDtsulIni', ''              ),
                                queryParameters:getText( 'codProgDtsulFin', fill( 'z', 60 ) )).

    end method.

    method public JsonArray get ( pager          as PaginationHelper ,
                                  dtEnvioIni     as datetime         ,
                                  dtEnvioFin     as datetime         ,
                                  idIni          as character        ,
                                  idFin          as character        ,
                                  codProgDtsulIni as character       ,
                                  codProgDtsulFin as character       ).

        define variable emails as JsonArray no-undo.

        assign emails = new JsonArray().

        for each b-email no-lock
            where b-email.data-envio     >= dtEnvioIni
              and b-email.data-envio     <= dtEnvioFin
              and b-email.id             >= idIni
              and b-email.id             <= idFin
              and b-email.cod-prog-dtsul >= codProgDtsulIni
              and b-email.cod-prog-dtsul <= codProgDtsulFin.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            emails:Add( buildEmailJson() ).

        end.

        return emails.

    end method.

    //Telas de metricas (rota email/metricas):
    //array -> objeto (programa, paramAmbiente) -> array "emails" -> objeto (atributos).
    //So a faixa de envio, sem paginacao e sem validacao de usuario.
    //situacao como texto (Pendente, Sucesso, Erro), como na listagem.
    //destino = lista de enderecos do e-mail, como gravada (o front separa).
    //Nao ha cadastro de programas para percorrer: o agrupamento sai da propria
    //leitura (break by). O indice de thl-email comeca pelo programa, entao a
    //faixa so por data le a tabela.
    method public JsonArray getMetrics ( dtEnvioIni as datetime ,
                                         dtEnvioFin as datetime ).

        define variable programs      as JsonArray  no-undo.
        define variable programItem   as JsonObject no-undo.
        define variable programEmails as JsonArray  no-undo.
        define variable email         as JsonObject no-undo.

        assign programs = new JsonArray().

        for each b-email no-lock
            where b-email.data-envio >= dtEnvioIni
              and b-email.data-envio <= dtEnvioFin
            break by b-email.cod-prog-dtsul
                  by b-email.cod-param-ambiente.

            if first-of( b-email.cod-param-ambiente ) then
                assign programEmails = new JsonArray().

            assign email = new JsonObject().

            email:Add( 'situacao', getLogEnvioLabel( b-email.log-envio ) ).
            email:Add( 'destino' , b-email.destino    ).
            email:Add( 'dtEnvio' , b-email.data-envio ).

            programEmails:Add( email ).

            if last-of( b-email.cod-param-ambiente ) then do.

                assign programItem = new JsonObject().

                programItem:Add( 'programa'     , b-email.cod-prog-dtsul     ).
                programItem:Add( 'paramAmbiente', b-email.cod-param-ambiente ).
                programItem:Add( 'emails'       , programEmails              ).

                programs:Add( programItem ).

            end.

        end.

        return programs.

    end method.

    method private JsonObject buildEmailJson().

        define variable email as JsonObject no-undo.

        assign email = new JsonObject().

        email:Add( 'id',              b-email.id                 ).
        email:Add( 'dtEnvio',         if b-email.data-envio <> ? then iso-date( b-email.data-envio ) else '' ).
        email:Add( 'codProgDtsul',    b-email.cod-prog-dtsul     ).
        email:Add( 'codParamAmbiente',b-email.cod-param-ambiente ).
        email:Add( 'remetente',       b-email.remetente          ).
        email:Add( 'destino',         b-email.destino            ).
        email:Add( 'assunto',         b-email.assunto            ).
        email:Add( 'arqAnexo',        b-email.arq-anexo          ).
        email:Add( 'logEnvio',        getLogEnvioLabel( b-email.log-envio ) ).
        email:Add( 'mensagem',        b-email.mensagem           ).
        email:Add( 'retorno' ,        b-email.retorno            ).
        email:Add( 'informacao' ,     b-email.info-envio         ).
        
        return email.

    end method.

    method private character getLogEnvioLabel( logEnvio as integer ).

        case logEnvio:
            when 1 then return 'Pendente'.
            when 2 then return 'Sucesso'.
            when 3 then return 'Erro'.
            otherwise    return ''.
        end case.

    end method.

end class.

/*------------------------------------------------------------------------
    File        : AuditoriaTabelaService
    Purpose     : Servico de dominio do cadastro de tabelas auditadas
                  (thl-audit-tabela, tela thl0050): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate e do local-delete-record da tela thl0050:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (banco, tabela) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.context.ContextService.
using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaTabelaService inherits Service.

    define private buffer b-thl-audit-tabela for thl-audit-tabela.

    method public override character getEntityName().
        return 'Tabela de Auditoria'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'banco,tabela', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable databaseName as character no-undo.
        define variable tableName    as character no-undo.

        assign databaseName = inContext:GetCharacter( 'banco'  )
               tableName    = inContext:GetCharacter( 'tabela' ).

        if databaseName = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Banco nao informado. Informe o banco da tabela auditada.' ).

        if tableName = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela nao informada. Informe a tabela auditada.' ).

        if available b-thl-audit-tabela then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela ja cadastrada. Esta tabela ja esta configurada para auditoria.' ).

        do transaction.

            create b-thl-audit-tabela.
            assign b-thl-audit-tabela.banco  = databaseName
                   b-thl-audit-tabela.tabela = tableName.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:stampControlFields().

        end.

    end method.

    method public override void update().

        if not available b-thl-audit-tabela then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Tabela de Auditoria nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:stampControlFields().

    end method.

    method public override void delete().

        if not available b-thl-audit-tabela then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Tabela de Auditoria nao localizada.' ).

        //elimina tambem campo, acesso, notificacao e expurgo da tabela (thl0051), como o local-delete-record do thl0050
        do transaction.

            for each thl-audit-tabela-campo exclusive-lock
                where thl-audit-tabela-campo.banco = b-thl-audit-tabela.banco and thl-audit-tabela-campo.tabela = b-thl-audit-tabela.tabela.
                delete thl-audit-tabela-campo.
            end.

            for each thl-audit-tabela-acesso exclusive-lock
                where thl-audit-tabela-acesso.banco = b-thl-audit-tabela.banco and thl-audit-tabela-acesso.tabela = b-thl-audit-tabela.tabela.
                delete thl-audit-tabela-acesso.
            end.

            for each thl-audit-tabela-notificacao exclusive-lock
                where thl-audit-tabela-notificacao.banco = b-thl-audit-tabela.banco and thl-audit-tabela-notificacao.tabela = b-thl-audit-tabela.tabela.
                delete thl-audit-tabela-notificacao.
            end.

            for each thl-audit-tabela-purge exclusive-lock
                where thl-audit-tabela-purge.banco = b-thl-audit-tabela.banco and thl-audit-tabela-purge.tabela = b-thl-audit-tabela.tabela.
                delete thl-audit-tabela-purge.
            end.

            delete b-thl-audit-tabela.

        end.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'bancoIni', '' ),
                                queryParameters:getText( 'bancoFin', fill( 'z', 100 ) ),
                                queryParameters:getText( 'tabelaIni', '' ),
                                queryParameters:getText( 'tabelaFin', fill( 'z', 100 ) ) ).
    end method.

    method public JsonArray get ( pager             as PaginationHelper ,
                                  databaseNameStart as character        ,
                                  databaseNameEnd   as character        ,
                                  tableNameStart    as character        ,
                                  tableNameEnd      as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-audit-tabela no-lock
            where b-thl-audit-tabela.banco  >= databaseNameStart
              and b-thl-audit-tabela.banco  <= databaseNameEnd
              and b-thl-audit-tabela.tabela >= tableNameStart
              and b-thl-audit-tabela.tabela <= tableNameEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'banco'             , b-thl-audit-tabela.banco ).
            recordItem:Add( 'tabela'            , b-thl-audit-tabela.tabela ).
            recordItem:Add( 'pk'                , b-thl-audit-tabela.pk ).
            recordItem:Add( 'indAtivoCreate'    , b-thl-audit-tabela.ind-ativo-create ).
            recordItem:Add( 'indAtivoUpdate'    , b-thl-audit-tabela.ind-ativo-update ).
            recordItem:Add( 'indAtivoDelete'    , b-thl-audit-tabela.ind-ativo-delete ).
            recordItem:Add( 'nivelSensibilidade', b-thl-audit-tabela.nivel-sensibilidade ).
            recordItem:Add( 'indAuditTabela'    , b-thl-audit-tabela.ind-audit-tabela ).
            recordItem:Add( 'dtAtualizacao'     , b-thl-audit-tabela.dt-atualizacao ).
            recordItem:Add( 'usuario'           , b-thl-audit-tabela.cod-usuario ).
            recordItem:Add( 'referenceCode'     , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.pk                 , input 'pk'                 ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.ind-ativo-create   , input 'indAtivoCreate'     ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.ind-ativo-update   , input 'indAtivoUpdate'     ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.ind-ativo-delete   , input 'indAtivoDelete'     ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.nivel-sensibilidade, input 'nivelSensibilidade' ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela.ind-audit-tabela   , input 'indAuditTabela'     ).
    end method.

    method private void stampControlFields().
        //campos de controle: gravados pelo servico, nunca pelo payload
        assign b-thl-audit-tabela.dt-atualizacao = now
               b-thl-audit-tabela.cod-usuario    = ContextService:getErpUser().
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-audit-tabela then
            return substitute( '&1#&2', b-thl-audit-tabela.banco,
                                        b-thl-audit-tabela.tabela ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-audit-tabela exclusive-lock
            where b-thl-audit-tabela.banco  = inContext:GetCharacter( 'banco'  )
              and b-thl-audit-tabela.tabela = inContext:GetCharacter( 'tabela' )
            no-error.
    end method.

end class.

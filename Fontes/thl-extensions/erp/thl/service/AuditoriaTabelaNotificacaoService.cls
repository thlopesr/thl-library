/*------------------------------------------------------------------------
    File        : AuditoriaTabelaNotificacaoService
    Purpose     : Servico de dominio do cadastro de notificacoes por nivel de sensibilidade da tabela auditada
                  (thl-audit-tabela-notificacao, tela thl0051d): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0051d:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (banco, tabela, nivel-sensibilidade) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaTabelaNotificacaoService inherits Service.

    define private buffer b-thl-audit-tabela-notificacao for thl-audit-tabela-notificacao.

    method public override character getEntityName().
        return 'Notificacao da Tabela de Auditoria'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'banco,tabela,nivelSensibilidade', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable databaseName     as character no-undo.
        define variable tableName        as character no-undo.
        define variable sensitivityLevel as integer   no-undo.

        assign databaseName     = inContext:GetCharacter( 'banco'              )
               tableName        = inContext:GetCharacter( 'tabela'             )
               sensitivityLevel = inContext:GetInteger( 'nivelSensibilidade' ).

        if not can-find( thl-audit-tabela
                         where thl-audit-tabela.banco  = databaseName
                           and thl-audit-tabela.tabela = tableName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela de Auditoria nao cadastrada.', 2 ).

        if available b-thl-audit-tabela-notificacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Notificacao ja cadastrada. Ja existe notificacao para este nivel de sensibilidade na tabela.' ).

        do transaction.

            create b-thl-audit-tabela-notificacao.
            assign b-thl-audit-tabela-notificacao.banco               = databaseName
                   b-thl-audit-tabela-notificacao.tabela              = tableName
                   b-thl-audit-tabela-notificacao.nivel-sensibilidade = sensitivityLevel.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-audit-tabela-notificacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Notificacao nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-audit-tabela-notificacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Notificacao nao localizada.' ).

        delete b-thl-audit-tabela-notificacao.

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

        for each b-thl-audit-tabela-notificacao no-lock
            where b-thl-audit-tabela-notificacao.banco               >= databaseNameStart
              and b-thl-audit-tabela-notificacao.banco               <= databaseNameEnd
              and b-thl-audit-tabela-notificacao.tabela              >= tableNameStart
              and b-thl-audit-tabela-notificacao.tabela              <= tableNameEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'banco'             , b-thl-audit-tabela-notificacao.banco ).
            recordItem:Add( 'tabela'            , b-thl-audit-tabela-notificacao.tabela ).
            recordItem:Add( 'nivelSensibilidade', b-thl-audit-tabela-notificacao.nivel-sensibilidade ).
            recordItem:Add( 'grupoEmail'        , b-thl-audit-tabela-notificacao.grupo-email ).
            recordItem:Add( 'indAtivo'          , b-thl-audit-tabela-notificacao.ind-ativo ).
            recordItem:Add( 'referenceCode'     , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-notificacao.grupo-email, input 'grupoEmail' ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-notificacao.ind-ativo  , input 'indAtivo'   ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-audit-tabela-notificacao.grupo-email = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Grupo de e-mail nao informado. Informe o grupo de e-mail a notificar.' ).

        if not can-find( thl-ambiente-param-grupo
                         where thl-ambiente-param-grupo.cod-grp-usuar = b-thl-audit-tabela-notificacao.grupo-email ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Grupo de e-mail nao cadastrado.', 2 ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-audit-tabela-notificacao then
            return substitute( '&1#&2#&3', b-thl-audit-tabela-notificacao.banco,
                                           b-thl-audit-tabela-notificacao.tabela,
                                           b-thl-audit-tabela-notificacao.nivel-sensibilidade ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-audit-tabela-notificacao exclusive-lock
            where b-thl-audit-tabela-notificacao.banco               = inContext:GetCharacter( 'banco'              )
              and b-thl-audit-tabela-notificacao.tabela              = inContext:GetCharacter( 'tabela'             )
              and b-thl-audit-tabela-notificacao.nivel-sensibilidade = inContext:GetInteger( 'nivelSensibilidade' )
            no-error.
    end method.

end class.

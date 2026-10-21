/*------------------------------------------------------------------------
    File        : AuditoriaTabelaAcessoService
    Purpose     : Servico de dominio do cadastro de usuarios com acesso a auditoria da tabela
                  (thl-audit-tabela-acesso, tela thl0051b): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0051b:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (banco, tabela, cod-usuario) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaTabelaAcessoService inherits Service.

    define private buffer b-thl-audit-tabela-acesso for thl-audit-tabela-acesso.

    method public override character getEntityName().
        return 'Acesso da Tabela de Auditoria'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'banco,tabela,usuario', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable databaseName as character no-undo.
        define variable tableName    as character no-undo.
        define variable userCode     as character no-undo.

        assign databaseName = inContext:GetCharacter( 'banco'   )
               tableName    = inContext:GetCharacter( 'tabela'  )
               userCode     = inContext:GetCharacter( 'usuario' ).

        if not can-find( thl-audit-tabela
                         where thl-audit-tabela.banco  = databaseName
                           and thl-audit-tabela.tabela = tableName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela de Auditoria nao cadastrada.', 2 ).

        if userCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao informado. Informe o usuario Datasul.' ).

        if not can-find( first usuar_mestre
                         where usuar_mestre.cod_usuario = userCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao cadastrado.', 2 ).

        if available b-thl-audit-tabela-acesso then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario ja cadastrado. Este usuario ja tem acesso configurado para a tabela.' ).

        do transaction.

            create b-thl-audit-tabela-acesso.
            assign b-thl-audit-tabela-acesso.banco       = databaseName
                   b-thl-audit-tabela-acesso.tabela      = tableName
                   b-thl-audit-tabela-acesso.cod-usuario = userCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-audit-tabela-acesso then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Acesso nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-audit-tabela-acesso then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Acesso nao localizado.' ).

        delete b-thl-audit-tabela-acesso.

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

        for each b-thl-audit-tabela-acesso no-lock
            where b-thl-audit-tabela-acesso.banco       >= databaseNameStart
              and b-thl-audit-tabela-acesso.banco       <= databaseNameEnd
              and b-thl-audit-tabela-acesso.tabela      >= tableNameStart
              and b-thl-audit-tabela-acesso.tabela      <= tableNameEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'banco'        , b-thl-audit-tabela-acesso.banco ).
            recordItem:Add( 'tabela'       , b-thl-audit-tabela-acesso.tabela ).
            recordItem:Add( 'usuario'      , b-thl-audit-tabela-acesso.cod-usuario ).
            recordItem:Add( 'nivelAcesso'  , b-thl-audit-tabela-acesso.nivel-acesso ).
            recordItem:Add( 'indAtivo'     , b-thl-audit-tabela-acesso.ind-ativo ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-acesso.nivel-acesso, input 'nivelAcesso' ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-acesso.ind-ativo   , input 'indAtivo'    ).
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-audit-tabela-acesso then
            return substitute( '&1#&2#&3', b-thl-audit-tabela-acesso.banco,
                                           b-thl-audit-tabela-acesso.tabela,
                                           b-thl-audit-tabela-acesso.cod-usuario ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-audit-tabela-acesso exclusive-lock
            where b-thl-audit-tabela-acesso.banco       = inContext:GetCharacter( 'banco'   )
              and b-thl-audit-tabela-acesso.tabela      = inContext:GetCharacter( 'tabela'  )
              and b-thl-audit-tabela-acesso.cod-usuario = inContext:GetCharacter( 'usuario' )
            no-error.
    end method.

end class.

/*------------------------------------------------------------------------
    File        : AuditoriaTabelaCampoService
    Purpose     : Servico de dominio do cadastro de campos auditados da tabela
                  (thl-audit-tabela-campo, tela thl0051c): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0051c:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (banco, tabela, campo) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaTabelaCampoService inherits Service.

    define private buffer b-thl-audit-tabela-campo for thl-audit-tabela-campo.

    method public override character getEntityName().
        return 'Campo da Tabela de Auditoria'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'banco,tabela,campo', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable databaseName as character no-undo.
        define variable tableName    as character no-undo.
        define variable fieldCode    as character no-undo.

        assign databaseName = inContext:GetCharacter( 'banco'  )
               tableName    = inContext:GetCharacter( 'tabela' )
               fieldCode    = inContext:GetCharacter( 'campo'  ).

        if not can-find( thl-audit-tabela
                         where thl-audit-tabela.banco  = databaseName
                           and thl-audit-tabela.tabela = tableName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela de Auditoria nao cadastrada.', 2 ).

        if fieldCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Campo nao informado. Informe o campo auditado.' ).

        if available b-thl-audit-tabela-campo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Campo ja cadastrado. Este campo ja esta configurado para a tabela.' ).

        do transaction.

            create b-thl-audit-tabela-campo.
            assign b-thl-audit-tabela-campo.banco  = databaseName
                   b-thl-audit-tabela-campo.tabela = tableName
                   b-thl-audit-tabela-campo.campo  = fieldCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-audit-tabela-campo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Campo nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-audit-tabela-campo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Campo nao localizado.' ).

        delete b-thl-audit-tabela-campo.

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

        for each b-thl-audit-tabela-campo no-lock
            where b-thl-audit-tabela-campo.banco  >= databaseNameStart
              and b-thl-audit-tabela-campo.banco  <= databaseNameEnd
              and b-thl-audit-tabela-campo.tabela >= tableNameStart
              and b-thl-audit-tabela-campo.tabela <= tableNameEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'banco'             , b-thl-audit-tabela-campo.banco ).
            recordItem:Add( 'tabela'            , b-thl-audit-tabela-campo.tabela ).
            recordItem:Add( 'campo'             , b-thl-audit-tabela-campo.campo ).
            recordItem:Add( 'nivelSensibilidade', b-thl-audit-tabela-campo.nivel-sensibilidade ).
            recordItem:Add( 'indAtivo'          , b-thl-audit-tabela-campo.ind-ativo ).
            recordItem:Add( 'referenceCode'     , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-campo.nivel-sensibilidade, input 'nivelSensibilidade' ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-campo.ind-ativo          , input 'indAtivo'           ).
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-audit-tabela-campo then
            return substitute( '&1#&2#&3', b-thl-audit-tabela-campo.banco,
                                           b-thl-audit-tabela-campo.tabela,
                                           b-thl-audit-tabela-campo.campo ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-audit-tabela-campo exclusive-lock
            where b-thl-audit-tabela-campo.banco  = inContext:GetCharacter( 'banco'  )
              and b-thl-audit-tabela-campo.tabela = inContext:GetCharacter( 'tabela' )
              and b-thl-audit-tabela-campo.campo  = inContext:GetCharacter( 'campo'  )
            no-error.
    end method.

end class.

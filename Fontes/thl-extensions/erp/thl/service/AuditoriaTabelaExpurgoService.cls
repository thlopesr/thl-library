/*------------------------------------------------------------------------
    File        : AuditoriaTabelaExpurgoService
    Purpose     : Servico de dominio do cadastro de retencao (expurgo) da auditoria por tabela
                  (thl-audit-tabela-purge, tela thl0051e): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0051e:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (banco, tabela) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaTabelaExpurgoService inherits Service.

    define private buffer b-thl-audit-tabela-purge for thl-audit-tabela-purge.

    method public override character getEntityName().
        return 'Expurgo da Tabela de Auditoria'.
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

        if not can-find( thl-audit-tabela
                         where thl-audit-tabela.banco  = databaseName
                           and thl-audit-tabela.tabela = tableName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Tabela de Auditoria nao cadastrada.', 2 ).

        if available b-thl-audit-tabela-purge then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Retencao ja cadastrada. A tabela ja tem retencao configurada; altere a existente.' ).

        do transaction.

            create b-thl-audit-tabela-purge.
            assign b-thl-audit-tabela-purge.banco  = databaseName
                   b-thl-audit-tabela-purge.tabela = tableName.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-audit-tabela-purge then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Retencao nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-audit-tabela-purge then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Retencao nao localizada.' ).

        delete b-thl-audit-tabela-purge.

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

        for each b-thl-audit-tabela-purge no-lock
            where b-thl-audit-tabela-purge.banco  >= databaseNameStart
              and b-thl-audit-tabela-purge.banco  <= databaseNameEnd
              and b-thl-audit-tabela-purge.tabela >= tableNameStart
              and b-thl-audit-tabela-purge.tabela <= tableNameEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'banco'           , b-thl-audit-tabela-purge.banco ).
            recordItem:Add( 'tabela'          , b-thl-audit-tabela-purge.tabela ).
            recordItem:Add( 'retencaoDias'    , b-thl-audit-tabela-purge.retencao-dias ).
            recordItem:Add( 'dtUltimaExecucao', b-thl-audit-tabela-purge.dt-ultima-execucao ).
            recordItem:Add( 'referenceCode'   , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-audit-tabela-purge.retencao-dias, input 'retencaoDias' ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-audit-tabela-purge.retencao-dias < 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Retencao invalida. Informe 0 (sem expurgo) ou a quantidade de dias a manter.' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-audit-tabela-purge then
            return substitute( '&1#&2', b-thl-audit-tabela-purge.banco,
                                        b-thl-audit-tabela-purge.tabela ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-audit-tabela-purge exclusive-lock
            where b-thl-audit-tabela-purge.banco  = inContext:GetCharacter( 'banco'  )
              and b-thl-audit-tabela-purge.tabela = inContext:GetCharacter( 'tabela' )
            no-error.
    end method.

end class.

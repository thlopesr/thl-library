/*------------------------------------------------------------------------
    File        : ConexaoRestPathService
    Purpose     : Servico de dominio do cadastro de paths (endpoints) REST
                  (thl-conexao-rest-path, tela thl0031): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0031:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-path) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ConexaoRestPathService inherits Service.

    define private buffer b-thl-conexao-rest-path for thl-conexao-rest-path.

    method public override character getEntityName().
        return 'Path da Conexao REST'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'endpoint', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable pathCode as character no-undo.

        assign pathCode = inContext:GetCharacter( 'endpoint' ).

        if pathCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Path nao informado. Informe o codigo do path REST.' ).

        if available b-thl-conexao-rest-path then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Path ja cadastrado. Informe outro codigo.' ).

        do transaction.

            create b-thl-conexao-rest-path.
            assign b-thl-conexao-rest-path.cod-path = pathCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-conexao-rest-path then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Path nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-conexao-rest-path then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Path nao localizado.' ).

        delete b-thl-conexao-rest-path.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'endpointIni', '' ),
                                queryParameters:getText( 'endpointFin', fill( 'z', 40 ) ) ).
    end method.

    method public JsonArray get ( pager         as PaginationHelper ,
                                  pathCodeStart as character        ,
                                  pathCodeEnd   as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-conexao-rest-path no-lock
            where b-thl-conexao-rest-path.cod-path >= pathCodeStart
              and b-thl-conexao-rest-path.cod-path <= pathCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'endpoint'     , b-thl-conexao-rest-path.cod-path ).
            recordItem:Add( 'descricao'    , b-thl-conexao-rest-path.des-path ).
            recordItem:Add( 'path'         , b-thl-conexao-rest-path.path ).
            recordItem:Add( 'contentType'  , b-thl-conexao-rest-path.content-type ).
            recordItem:Add( 'accept'       , b-thl-conexao-rest-path.accept ).
            recordItem:Add( 'timeout'      , b-thl-conexao-rest-path.timeout ).
            recordItem:Add( 'parameters'   , b-thl-conexao-rest-path.parameters ).
            recordItem:Add( 'headers'      , b-thl-conexao-rest-path.headers ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.des-path    , input 'descricao'   ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.path        , input 'path'        ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.content-type, input 'contentType' ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.accept      , input 'accept'      ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.timeout     , input 'timeout'     ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.parameters  , input 'parameters'  ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-path.headers     , input 'headers'     ).
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-conexao-rest-path then
            return b-thl-conexao-rest-path.cod-path.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-conexao-rest-path exclusive-lock
            where b-thl-conexao-rest-path.cod-path = inContext:GetCharacter( 'endpoint' )
            no-error.
    end method.

end class.

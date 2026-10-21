/*------------------------------------------------------------------------
    File        : ConexaoRestHeaderService
    Purpose     : Servico de dominio do cadastro de cabecalho (IHeaderProvider) da conexao REST
                  (thl-conexao-rest-header, tela thl0033): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0033:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-conexao) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ConexaoRestHeaderService inherits Service.

    define private buffer b-thl-conexao-rest-header for thl-conexao-rest-header.

    method public override character getEntityName().
        return 'Cabecalho da Conexao REST'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'conexao', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable connectionCode as character no-undo.

        assign connectionCode = inContext:GetCharacter( 'conexao' ).

        if not can-find( thl-conexao-rest
                         where thl-conexao-rest.cod-conexao = connectionCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Conexao REST nao cadastrada.', 2 ).

        if available b-thl-conexao-rest-header then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Cabecalho ja cadastrado para a conexao. Cada conexao tem uma unica configuracao; altere a existente.' ).

        do transaction.

            create b-thl-conexao-rest-header.
            assign b-thl-conexao-rest-header.cod-conexao = connectionCode.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-conexao-rest-header then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Cabecalho nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-conexao-rest-header then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Cabecalho nao localizado.' ).

        delete b-thl-conexao-rest-header.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'conexaoIni', '' ),
                                queryParameters:getText( 'conexaoFin', fill( 'z', 40 ) ) ).
    end method.

    method public JsonArray get ( pager               as PaginationHelper ,
                                  connectionCodeStart as character        ,
                                  connectionCodeEnd   as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-conexao-rest-header no-lock
            where b-thl-conexao-rest-header.cod-conexao >= connectionCodeStart
              and b-thl-conexao-rest-header.cod-conexao <= connectionCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'conexao'      , b-thl-conexao-rest-header.cod-conexao ).
            recordItem:Add( 'classeParser' , b-thl-conexao-rest-header.classe-parser ).
            recordItem:Add( 'parameters'   , b-thl-conexao-rest-header.parameters ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-header.classe-parser, input 'classeParser' ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-header.parameters   , input 'parameters'   ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-conexao-rest-header.classe-parser = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe nao informada. Informe o nome completo da classe que implementa IHeaderProvider.' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-conexao-rest-header then
            return b-thl-conexao-rest-header.cod-conexao.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-conexao-rest-header exclusive-lock
            where b-thl-conexao-rest-header.cod-conexao = inContext:GetCharacter( 'conexao' )
            no-error.
    end method.

end class.

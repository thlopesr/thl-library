/*------------------------------------------------------------------------
    File        : ConexaoRestService
    Purpose     : Servico de dominio do cadastro de conexoes REST (URL base)
                  (thl-conexao-rest, tela thl0030): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate e do local-delete-record da tela thl0030:
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

class thl-extensions.erp.thl.service.ConexaoRestService inherits Service.

    define private buffer b-thl-conexao-rest for thl-conexao-rest.

    method public override character getEntityName().
        return 'Conexao REST'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'conexao', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable connectionCode as character no-undo.

        assign connectionCode = inContext:GetCharacter( 'conexao' ).

        if connectionCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Conexao nao informada. Informe o codigo da conexao REST.' ).

        if available b-thl-conexao-rest then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Conexao ja cadastrada. Informe outro codigo.' ).

        do transaction.

            create b-thl-conexao-rest.
            assign b-thl-conexao-rest.cod-conexao = connectionCode.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-conexao-rest then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Conexao nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-conexao-rest then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Conexao nao localizada.' ).

        //elimina tambem a autenticacao (thl0032) e os cabecalhos (thl0033) da conexao, como o local-delete-record do thl0030
        do transaction.

            for each thl-conexao-rest-autenticacao exclusive-lock
                where thl-conexao-rest-autenticacao.cod-conexao = b-thl-conexao-rest.cod-conexao.
                delete thl-conexao-rest-autenticacao.
            end.

            for each thl-conexao-rest-header exclusive-lock
                where thl-conexao-rest-header.cod-conexao = b-thl-conexao-rest.cod-conexao.
                delete thl-conexao-rest-header.
            end.

            delete b-thl-conexao-rest.

        end.

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

        for each b-thl-conexao-rest no-lock
            where b-thl-conexao-rest.cod-conexao >= connectionCodeStart
              and b-thl-conexao-rest.cod-conexao <= connectionCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'conexao'                 , b-thl-conexao-rest.cod-conexao ).
            recordItem:Add( 'descricao'               , b-thl-conexao-rest.des-conexao ).
            recordItem:Add( 'urlBase'                 , b-thl-conexao-rest.url-base ).
            recordItem:Add( 'indRequisitaAutenticacao', b-thl-conexao-rest.ind-requisita-autenticacao ).
            recordItem:Add( 'indRequisitaHeader'      , b-thl-conexao-rest.ind-requisita-header ).
            recordItem:Add( 'referenceCode'           , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest.des-conexao               , input 'descricao'                ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest.url-base                  , input 'urlBase'                  ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest.ind-requisita-autenticacao, input 'indRequisitaAutenticacao' ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest.ind-requisita-header      , input 'indRequisitaHeader'       ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-conexao-rest.url-base = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'URL base nao informada. Informe a URL base da API (ex.: https://api.exemplo.com).' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-conexao-rest then
            return b-thl-conexao-rest.cod-conexao.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-conexao-rest exclusive-lock
            where b-thl-conexao-rest.cod-conexao = inContext:GetCharacter( 'conexao' )
            no-error.
    end method.

end class.

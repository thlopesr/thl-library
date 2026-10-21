/*------------------------------------------------------------------------
    File        : ConexaoRestAutenticacaoService
    Purpose     : Servico de dominio do cadastro de autenticacao da conexao REST
                  (thl-conexao-rest-autenticacao, tela thl0032): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0032:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-conexao) so e gravada na criacao.
                  Campos sensiveis saem mascarados no get(); no PATCH, o valor
                  mascarado mantem o valor gravado (ADR api-rest-cadastros-thl 2.7).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ConexaoRestAutenticacaoService inherits Service.

    define public property MaskedValue     as character no-undo initial '********' get.
    define public property SensitiveFields as character no-undo initial 'headersToken,parametersToken,senha,token,rawTokenData' get.

    define private buffer b-thl-conexao-rest-autenticacao for thl-conexao-rest-autenticacao.

    method public override character getEntityName().
        return 'Autenticacao da Conexao REST'.
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

        if available b-thl-conexao-rest-autenticacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Autenticacao ja cadastrada para a conexao. Cada conexao tem uma unica configuracao; altere a existente.' ).

        do transaction.

            create b-thl-conexao-rest-autenticacao.
            assign b-thl-conexao-rest-autenticacao.cod-conexao = connectionCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-conexao-rest-autenticacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Autenticacao nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-conexao-rest-autenticacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Autenticacao nao localizada.' ).

        delete b-thl-conexao-rest-autenticacao.

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

        for each b-thl-conexao-rest-autenticacao no-lock
            where b-thl-conexao-rest-autenticacao.cod-conexao >= connectionCodeStart
              and b-thl-conexao-rest-autenticacao.cod-conexao <= connectionCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'conexao'          , b-thl-conexao-rest-autenticacao.cod-conexao ).
            recordItem:Add( 'urlToken'         , b-thl-conexao-rest-autenticacao.url-token ).
            recordItem:Add( 'contentTypeToken' , b-thl-conexao-rest-autenticacao.content-type-token ).
            recordItem:Add( 'acceptToken'      , b-thl-conexao-rest-autenticacao.accept-token ).
            recordItem:Add( 'headersToken'     , this-object:maskValue( b-thl-conexao-rest-autenticacao.headers-token ) ).
            recordItem:Add( 'parametersToken'  , this-object:maskValue( b-thl-conexao-rest-autenticacao.parameters-token ) ).
            recordItem:Add( 'tipoAutenticacao' , b-thl-conexao-rest-autenticacao.tipo-autenticacao ).
            recordItem:Add( 'indRequisitaToken', b-thl-conexao-rest-autenticacao.ind-requisita-token ).
            recordItem:Add( 'usuario'          , b-thl-conexao-rest-autenticacao.usuario ).
            recordItem:Add( 'senha'            , this-object:maskValue( b-thl-conexao-rest-autenticacao.senha ) ).
            recordItem:Add( 'classeParserToken', b-thl-conexao-rest-autenticacao.classe-parser-token ).
            recordItem:Add( 'token'            , this-object:maskValue( b-thl-conexao-rest-autenticacao.token ) ).
            recordItem:Add( 'rawTokenData'     , this-object:maskValue( b-thl-conexao-rest-autenticacao.raw-token-data ) ).
            recordItem:Add( 'dtExpiracaoToken' , b-thl-conexao-rest-autenticacao.dt-expiracao-token ).
            recordItem:Add( 'referenceCode'    , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.url-token          , input 'urlToken'          ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.content-type-token , input 'contentTypeToken'  ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.accept-token       , input 'acceptToken'       ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.tipo-autenticacao  , input 'tipoAutenticacao'  ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.ind-requisita-token, input 'indRequisitaToken' ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.usuario            , input 'usuario'           ).
        jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.classe-parser-token, input 'classeParserToken' ).

        //valor mascarado recebido mantem o valor gravado
        if not this-object:isMasked( 'headersToken' ) then
            jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.headers-token, input 'headersToken' ).
        if not this-object:isMasked( 'parametersToken' ) then
            jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.parameters-token, input 'parametersToken' ).
        if not this-object:isMasked( 'senha' ) then
            jsonSetter:SetValue( input-output b-thl-conexao-rest-autenticacao.senha, input 'senha' ).
    end method.

    method private logical isMasked( input fieldName as character ).
        return inContext:Has( fieldName ) and
               inContext:GetType( fieldName ) = JsonDataType:STRING and
               inContext:GetCharacter( fieldName ) = this-object:MaskedValue.
    end method.

    //campo sensivel vazio continua vazio, para a tela saber que nao ha valor
    method private character maskValue( input fieldValue as character ).
        if fieldValue = ? or fieldValue = '' then
            return ''.
        return this-object:MaskedValue.
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-conexao-rest-autenticacao then
            return b-thl-conexao-rest-autenticacao.cod-conexao.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-conexao-rest-autenticacao exclusive-lock
            where b-thl-conexao-rest-autenticacao.cod-conexao = inContext:GetCharacter( 'conexao' )
            no-error.
    end method.

end class.

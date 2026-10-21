/*------------------------------------------------------------------------
    File        : AplicacaoService
    Purpose     : Servico de dominio do cadastro de aplicacoes (thl-aplicacao,
                  tela thl0020): criacao, atualizacao, exclusao e listagem
                  paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras iguais as da tela thl0020 (ADR api-rest-cadastros-thl):
                  17006 para validacao, 2 para registro relacionado inexistente.
                  A chave (aplicacao) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AplicacaoService inherits Service.

    define private buffer b-thl-aplicacao for thl-aplicacao.

    method public override character getEntityName().
        return 'Aplicacao'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'aplicacao', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable applicationCode as character no-undo.

        assign applicationCode = inContext:GetCharacter( 'aplicacao' ).

        if applicationCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Aplicacao nao informada. Informe o codigo da aplicacao.' ).

        if available b-thl-aplicacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Aplicacao ja cadastrada. Informe outro codigo.' ).

        do transaction.

            create b-thl-aplicacao.
            assign b-thl-aplicacao.aplicacao = applicationCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-aplicacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Aplicacao nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-aplicacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Aplicacao nao localizada.' ).

        if can-find( first thl-objeto
                     where thl-objeto.aplicacao = b-thl-aplicacao.aplicacao ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
                'Aplicacao possui objetos. Existem objetos de integracao cadastrados para esta aplicacao (thl0021). Elimine-os antes de eliminar a aplicacao.' ).

        delete b-thl-aplicacao.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'aplicacaoIni', '' ),
                                queryParameters:getText( 'aplicacaoFin', fill( 'z', 100 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  applicationCodeStart as character        ,
                                  applicationCodeEnd   as character        ).

        define variable applicationItem as JsonObject no-undo.
        define variable applicationList as JsonArray  no-undo.

        assign applicationList = new JsonArray().

        //pk-aplicacao: aplicacao
        for each b-thl-aplicacao no-lock
            where b-thl-aplicacao.aplicacao >= applicationCodeStart
              and b-thl-aplicacao.aplicacao <= applicationCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign applicationItem = new JsonObject().

            applicationItem:Add( 'aplicacao'    , b-thl-aplicacao.aplicacao       ).
            applicationItem:Add( 'descricao'    , b-thl-aplicacao.descricao       ).
            applicationItem:Add( 'indInterna'   , b-thl-aplicacao.ind-interna     ).
            applicationItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            applicationList:Add( applicationItem ).

        end.

        return applicationList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-aplicacao.descricao  , input 'descricao'  ).
        jsonSetter:SetValue( input-output b-thl-aplicacao.ind-interna, input 'indInterna' ).
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-aplicacao then
            return b-thl-aplicacao.aplicacao.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-aplicacao exclusive-lock
            where b-thl-aplicacao.aplicacao = inContext:GetCharacter( 'aplicacao' )
            no-error.
    end method.

end class.

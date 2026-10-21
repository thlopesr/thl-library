/*------------------------------------------------------------------------
    File        : ObjetoUsuarioService
    Purpose     : Servico de dominio do cadastro de usuarios liberados para o objeto de integracao
                  (thl-objeto-usuario, tela thl0022b): criacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0022b:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (aplicacao, objeto, cod-usuario) so e gravada na criacao.
                  O registro so tem a chave: sem update().
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ObjetoUsuarioService inherits Service.

    define private buffer b-thl-objeto-usuario for thl-objeto-usuario.

    method public override character getEntityName().
        return 'Usuario do Objeto'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'aplicacao,objeto,usuario', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable applicationCode as character no-undo.
        define variable objectCode      as character no-undo.
        define variable userCode        as character no-undo.

        assign applicationCode = inContext:GetCharacter( 'aplicacao' )
               objectCode      = inContext:GetCharacter( 'objeto'    )
               userCode        = inContext:GetCharacter( 'usuario'   ).

        if userCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao informado. Informe o usuario Datasul.' ).

        if not can-find( first usuar_mestre
                         where usuar_mestre.cod_usuario = userCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao cadastrado.', 2 ).

        if not can-find( thl-objeto
                         where thl-objeto.aplicacao = applicationCode
                           and thl-objeto.objeto    = objectCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto nao cadastrado.', 2 ).

        if available b-thl-objeto-usuario then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario ja cadastrado. Este usuario ja esta liberado para o objeto.' ).

        do transaction.

            create b-thl-objeto-usuario.
            assign b-thl-objeto-usuario.aplicacao   = applicationCode
                   b-thl-objeto-usuario.objeto      = objectCode
                   b-thl-objeto-usuario.cod-usuario = userCode.


        end.

    end method.

    method public override void delete().

        if not available b-thl-objeto-usuario then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Usuario do objeto nao localizado.' ).

        delete b-thl-objeto-usuario.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'aplicacaoIni', '' ),
                                queryParameters:getText( 'aplicacaoFin', fill( 'z', 100 ) ),
                                queryParameters:getText( 'objetoIni', '' ),
                                queryParameters:getText( 'objetoFin', fill( 'z', 60 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  applicationCodeStart as character        ,
                                  applicationCodeEnd   as character        ,
                                  objectCodeStart      as character        ,
                                  objectCodeEnd        as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-objeto-usuario no-lock
            where b-thl-objeto-usuario.aplicacao   >= applicationCodeStart
              and b-thl-objeto-usuario.aplicacao   <= applicationCodeEnd
              and b-thl-objeto-usuario.objeto      >= objectCodeStart
              and b-thl-objeto-usuario.objeto      <= objectCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'aplicacao'    , b-thl-objeto-usuario.aplicacao ).
            recordItem:Add( 'objeto'       , b-thl-objeto-usuario.objeto ).
            recordItem:Add( 'usuario'      , b-thl-objeto-usuario.cod-usuario ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-objeto-usuario then
            return substitute( '&1#&2#&3', b-thl-objeto-usuario.aplicacao,
                                           b-thl-objeto-usuario.objeto,
                                           b-thl-objeto-usuario.cod-usuario ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-objeto-usuario exclusive-lock
            where b-thl-objeto-usuario.aplicacao   = inContext:GetCharacter( 'aplicacao' )
              and b-thl-objeto-usuario.objeto      = inContext:GetCharacter( 'objeto'    )
              and b-thl-objeto-usuario.cod-usuario = inContext:GetCharacter( 'usuario'   )
            no-error.
    end method.

end class.

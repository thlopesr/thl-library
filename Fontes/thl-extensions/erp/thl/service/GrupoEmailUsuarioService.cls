/*------------------------------------------------------------------------
    File        : GrupoEmailUsuarioService
    Purpose     : Servico de dominio do cadastro de usuarios do grupo de e-mail
                  (thl-ambiente-param-grupo-usuar, tela thl0011b): criacao,
                  exclusao e listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0011b:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-grp-usuar, cod-usuario, email-alternativo) so e gravada
                  na criacao. O registro so tem a chave: sem update().
                  Requer banco emsfnd (usuar_mestre) conectado para compilar e rodar.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.GrupoEmailUsuarioService inherits Service.

    define private buffer b-thl-ambiente-param-grupo-usuar for thl-ambiente-param-grupo-usuar.

    method public override character getEntityName().
        return 'Usuario do Grupo de E-mail'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'grupoEmail,usuario', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable groupCode as character no-undo.
        define variable userCode  as character no-undo.
        define variable altEmail  as character no-undo.

        assign groupCode = inContext:GetCharacter( 'grupoEmail'      )
               userCode  = inContext:GetCharacter( 'usuario'         )
               altEmail  = inContext:GetCharacter( 'emailAlternativo' ).

        if userCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao informado. Informe o usuario Datasul.' ).

        // Pi-validate: usuario deve existir no Datasul (banco emsfnd)
        if not can-find( first usuar_mestre
                         where usuar_mestre.cod_usuario = userCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Usuario nao cadastrado.', 2 ).

        if not can-find( thl-ambiente-param-grupo
                         where thl-ambiente-param-grupo.cod-grp-usuar = groupCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Grupo de e-mail nao cadastrado.', 2 ).

        // Pi-validate: combinacao grupo+usuario+email-alternativo ja existente
        if available b-thl-ambiente-param-grupo-usuar then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create',
                'Usuario ja cadastrado no grupo. Este usuario (com este e-mail alternativo) ja esta no grupo.' ).

        do transaction.

            create b-thl-ambiente-param-grupo-usuar.
            assign b-thl-ambiente-param-grupo-usuar.cod-grp-usuar     = groupCode
                   b-thl-ambiente-param-grupo-usuar.cod-usuario       = userCode
                   b-thl-ambiente-param-grupo-usuar.email-alternativo = altEmail.

        end.

    end method.

    method public override void delete().

        if not available b-thl-ambiente-param-grupo-usuar then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Usuario do grupo de e-mail nao localizado.' ).

        delete b-thl-ambiente-param-grupo-usuar.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'grupoEmailIni', '' ),
                                queryParameters:getText( 'grupoEmailFin', fill( 'z', 20 ) ) ).
    end method.

    method public JsonArray get ( pager          as PaginationHelper ,
                                  groupCodeStart as character        ,
                                  groupCodeEnd   as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        // indice fk-grupo (primary): acesso pelo cod-grp-usuar
        for each b-thl-ambiente-param-grupo-usuar no-lock
            where b-thl-ambiente-param-grupo-usuar.cod-grp-usuar >= groupCodeStart
              and b-thl-ambiente-param-grupo-usuar.cod-grp-usuar <= groupCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'grupoEmail'      , b-thl-ambiente-param-grupo-usuar.cod-grp-usuar ).
            recordItem:Add( 'usuario'         , b-thl-ambiente-param-grupo-usuar.cod-usuario ).
            recordItem:Add( 'emailAlternativo', b-thl-ambiente-param-grupo-usuar.email-alternativo ).
            recordItem:Add( 'referenceCode'   , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    // le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente-param-grupo-usuar then
            return substitute( '&1#&2#&3', b-thl-ambiente-param-grupo-usuar.cod-grp-usuar,
                                           b-thl-ambiente-param-grupo-usuar.cod-usuario,
                                           b-thl-ambiente-param-grupo-usuar.email-alternativo ).
        return ''.
    end method.

    method private void positionRecord().
        // usa pk-grupo-usuar (unique): combinacao dos tres campos da chave
        find first b-thl-ambiente-param-grupo-usuar exclusive-lock
            where b-thl-ambiente-param-grupo-usuar.cod-grp-usuar     = inContext:GetCharacter( 'grupoEmail'      )
              and b-thl-ambiente-param-grupo-usuar.cod-usuario       = inContext:GetCharacter( 'usuario'         )
              and b-thl-ambiente-param-grupo-usuar.email-alternativo = inContext:GetCharacter( 'emailAlternativo' )
            no-error.
    end method.

end class.

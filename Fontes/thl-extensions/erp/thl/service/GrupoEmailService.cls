/*------------------------------------------------------------------------
    File        : GrupoEmailService
    Purpose     : Servico de dominio do cadastro de grupos de e-mail
                  (thl-ambiente-param-grupo, tela thl0011): criacao, atualizacao,
                  exclusao e listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0011:
                  17006 para validacao.
                  Chave (cod-grp-usuar) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.GrupoEmailService inherits Service.

    define private buffer b-thl-ambiente-param-grupo for thl-ambiente-param-grupo.

    method public override character getEntityName().
        return 'Grupo de E-mail'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'grupoEmail', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable groupCode as character no-undo.

        assign groupCode = inContext:GetCharacter( 'grupoEmail' ).

        if groupCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Grupo de e-mail nao informado. Informe o codigo do grupo.' ).

        if available b-thl-ambiente-param-grupo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Grupo de e-mail ja cadastrado. Informe outro codigo.' ).

        do transaction.

            create b-thl-ambiente-param-grupo.
            assign b-thl-ambiente-param-grupo.cod-grp-usuar = groupCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-ambiente-param-grupo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Grupo de e-mail nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-ambiente-param-grupo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Grupo de e-mail nao localizado.' ).

        // bloqueio do local-delete-record da tela thl0011: impede exclusao com parametros de e-mail vinculados
        if can-find( first thl-email-param
                     where thl-email-param.cod-grp-usuar = b-thl-ambiente-param-grupo.cod-grp-usuar ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
                'Grupo de e-mail em uso. Existem parametros de e-mail (thl0010) que usam este grupo. Altere-os antes de eliminar o grupo.' ).

        // bloqueio do local-delete-record: impede exclusao com notificacoes de auditoria vinculadas
        if can-find( first thl-audit-tabela-notificacao
                     where thl-audit-tabela-notificacao.grupo-email = b-thl-ambiente-param-grupo.cod-grp-usuar ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
                'Grupo de e-mail em uso. Existem notificacoes de auditoria (thl0051) que usam este grupo. Altere-as antes de eliminar o grupo.' ).

        //elimina tambem os usuarios do grupo, como o local-delete-record do thl0011
        do transaction.

            for each thl-ambiente-param-grupo-usuar exclusive-lock
                where thl-ambiente-param-grupo-usuar.cod-grp-usuar = b-thl-ambiente-param-grupo.cod-grp-usuar.
                delete thl-ambiente-param-grupo-usuar.
            end.

            delete b-thl-ambiente-param-grupo.

        end.

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

        for each b-thl-ambiente-param-grupo no-lock
            where b-thl-ambiente-param-grupo.cod-grp-usuar >= groupCodeStart
              and b-thl-ambiente-param-grupo.cod-grp-usuar <= groupCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'grupoEmail'   , b-thl-ambiente-param-grupo.cod-grp-usuar ).
            recordItem:Add( 'descricao'    , b-thl-ambiente-param-grupo.descricao ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    // so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-ambiente-param-grupo.descricao, input 'descricao' ).
    end method.

    // le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente-param-grupo then
            return b-thl-ambiente-param-grupo.cod-grp-usuar.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-ambiente-param-grupo exclusive-lock
            where b-thl-ambiente-param-grupo.cod-grp-usuar = inContext:GetCharacter( 'grupoEmail' )
            no-error.
    end method.

end class.

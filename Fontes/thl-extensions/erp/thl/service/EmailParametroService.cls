/*------------------------------------------------------------------------
    File        : EmailParametroService
    Purpose     : Servico de dominio do cadastro de parametros de e-mail
                  (thl-email-param, tela thl0010): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0010:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-email-param) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.EmailParametroService inherits Service.

    define private buffer b-thl-email-param for thl-email-param.

    method public override character getEntityName().
        return 'Parametro de E-mail'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'emailParam', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable emailParamCode as character no-undo.

        assign emailParamCode = inContext:GetCharacter( 'emailParam' ).

        if emailParamCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro de e-mail nao informado. Informe o codigo do parametro de e-mail.' ).

        if available b-thl-email-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro de e-mail ja cadastrado. Informe outro codigo.' ).

        do transaction.

            create b-thl-email-param.
            assign b-thl-email-param.cod-email-param = emailParamCode.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-email-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Parametro de e-mail nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-email-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Parametro de e-mail nao localizado.' ).

        delete b-thl-email-param.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'emailParamIni', '' ),
                                queryParameters:getText( 'emailParamFin', fill( 'z', 30 ) ) ).
    end method.

    method public JsonArray get ( pager               as PaginationHelper ,
                                  emailParamCodeStart as character        ,
                                  emailParamCodeEnd   as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-email-param no-lock
            where b-thl-email-param.cod-email-param >= emailParamCodeStart
              and b-thl-email-param.cod-email-param <= emailParamCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'emailParam'   , b-thl-email-param.cod-email-param ).
            recordItem:Add( 'assunto'      , b-thl-email-param.assunto ).
            recordItem:Add( 'grupoEmail'   , b-thl-email-param.cod-grp-usuar ).
            recordItem:Add( 'remetente'    , b-thl-email-param.remetente ).
            recordItem:Add( 'copia'        , b-thl-email-param.copia ).
            recordItem:Add( 'mensagem'     , b-thl-email-param.mensagem ).
            recordItem:Add( 'importancia'  , b-thl-email-param.importancia ).
            recordItem:Add( 'logGerar'     , b-thl-email-param.log-gerar ).
            recordItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-email-param.assunto      , input 'assunto'     ).
        jsonSetter:SetValue( input-output b-thl-email-param.cod-grp-usuar, input 'grupoEmail'  ).
        jsonSetter:SetValue( input-output b-thl-email-param.remetente    , input 'remetente'   ).
        jsonSetter:SetValue( input-output b-thl-email-param.copia        , input 'copia'       ).
        jsonSetter:SetValue( input-output b-thl-email-param.mensagem     , input 'mensagem'    ).
        jsonSetter:SetValue( input-output b-thl-email-param.importancia  , input 'importancia' ).
        jsonSetter:SetValue( input-output b-thl-email-param.log-gerar    , input 'logGerar'    ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-email-param.cod-grp-usuar = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Grupo de e-mail nao informado. Informe o grupo de e-mail dos destinatarios.' ).

        if not can-find( thl-ambiente-param-grupo
                         where thl-ambiente-param-grupo.cod-grp-usuar = b-thl-email-param.cod-grp-usuar ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Grupo de e-mail nao cadastrado.', 2 ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-email-param then
            return b-thl-email-param.cod-email-param.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-email-param exclusive-lock
            where b-thl-email-param.cod-email-param = inContext:GetCharacter( 'emailParam' )
            no-error.
    end method.

end class.

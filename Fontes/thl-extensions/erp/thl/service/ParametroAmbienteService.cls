/*------------------------------------------------------------------------
    File        : ParametroAmbienteService
    Purpose     : Servico de dominio do cadastro de parametros de ambiente
                  (thl-ambiente-param, tela thl0002): criacao, atualizacao,
                  exclusao e listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-09-25
    Notes       : Padrao LpcoService (thl-extensions.erp.automatizador).
                  Exclusao do parametro elimina tambem as variaveis (thl0002b) e
                  os programas (thl0002c), na mesma transacao, como o
                  local-delete-record do thl0002-v01 (desde 2026-10-08; antes
                  era bloqueada).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ParametroAmbienteService inherits Service.

    define private buffer b-thl-ambiente-param for thl-ambiente-param.

    method public override character getEntityName().
        return 'Parametro de Ambiente'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'codParametro', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable parameterCode as character no-undo.

        assign parameterCode = inContext:GetCharacter( 'codParametro' ).

        if parameterCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro nao informado. Informe o codigo do parametro.' ).

        if available b-thl-ambiente-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro ja cadastrado. Informe outro codigo.' ).

        do transaction.

            create b-thl-ambiente-param.
            assign b-thl-ambiente-param.cod-param-ambiente = parameterCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-ambiente-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Parametro nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-ambiente-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Parametro nao localizado.' ).

        do transaction.

            for each thl-ambiente-param-variavel exclusive-lock
                where thl-ambiente-param-variavel.cod-param-ambiente = b-thl-ambiente-param.cod-param-ambiente.
                delete thl-ambiente-param-variavel.
            end.

            for each thl-ambiente-param-prog exclusive-lock
                where thl-ambiente-param-prog.cod-param-ambiente = b-thl-ambiente-param.cod-param-ambiente.
                delete thl-ambiente-param-prog.
            end.

            delete b-thl-ambiente-param.

        end.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'parametroIni', '' ),
                                queryParameters:getText( 'parametroFin', fill( 'z', 15 ) ) ).
    end method.

    method public JsonArray get ( pager              as PaginationHelper ,
                                  parameterCodeStart as character        ,
                                  parameterCodeEnd   as character        ).

        define variable parameterItem  as JsonObject no-undo.
        define variable parameterList as JsonArray  no-undo.

        assign parameterList = new JsonArray().

        for each b-thl-ambiente-param no-lock
            where b-thl-ambiente-param.cod-param-ambiente >= parameterCodeStart
              and b-thl-ambiente-param.cod-param-ambiente <= parameterCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign parameterItem = new JsonObject().

            parameterItem:Add( 'codParametro' , b-thl-ambiente-param.cod-param-ambiente   ).
            parameterItem:Add( 'descricao'    , b-thl-ambiente-param.descr-param-ambiente ).
            parameterItem:Add( 'referenceCode', this-object:loadReferenceCode()           ).

            parameterList:Add( parameterItem ).

        end.

        return parameterList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-ambiente-param.descr-param-ambiente, input 'descricao' ).
    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente-param then
            return b-thl-ambiente-param.cod-param-ambiente.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-ambiente-param exclusive-lock
            where b-thl-ambiente-param.cod-param-ambiente = inContext:GetCharacter( 'codParametro' )
            no-error.
    end method.

end class.

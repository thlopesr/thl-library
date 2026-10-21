/*------------------------------------------------------------------------
    File        : ParametroProgramaService
    Purpose     : Servico de dominio dos programas vinculados a um parametro
                  de ambiente (thl-ambiente-param-prog, tela thl0002c):
                  criacao, exclusao e listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-09-25
    Notes       : Padrao LpcoService (thl-extensions.erp.automatizador).
                  O registro so tem a chave: nao ha update() (a tela tambem so
                  inclui e elimina); o PATCH cai no update() de Service, que
                  lanca 'Acao nao suportada' (17006).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ParametroProgramaService inherits Service.

    define private buffer b-thl-ambiente-param-prog for thl-ambiente-param-prog.

    method public override character getEntityName().
        return 'Programa do Parametro'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'codParametro,codPrograma', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable parameterCode as character no-undo.
        define variable programName   as character no-undo.

        assign parameterCode = inContext:GetCharacter( 'codParametro' )
               programName   = inContext:GetCharacter( 'codPrograma'  ).

        if not can-find( thl-ambiente-param
                         where thl-ambiente-param.cod-param-ambiente = parameterCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro de Ambiente nao cadastrado.', 2 ).

        if programName = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Programa nao informado. Informe o programa Datasul.' ).

        if available b-thl-ambiente-param-prog then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Programa ja vinculado a este parametro.' ).

        do transaction.
            create b-thl-ambiente-param-prog.
            assign b-thl-ambiente-param-prog.cod-param-ambiente = parameterCode
                   b-thl-ambiente-param-prog.cod-prog-dtsul     = programName.
        end.

    end method.

    method public override void delete().

        if not available b-thl-ambiente-param-prog then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Programa do parametro nao localizado.' ).

        delete b-thl-ambiente-param-prog.

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

        define variable programItem as JsonObject no-undo.
        define variable programList as JsonArray  no-undo.

        assign programList = new JsonArray().

        //pk-param-prog: cod-param-ambiente, cod-prog-dtsul
        for each b-thl-ambiente-param-prog no-lock
            where b-thl-ambiente-param-prog.cod-param-ambiente >= parameterCodeStart
              and b-thl-ambiente-param-prog.cod-param-ambiente <= parameterCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign programItem = new JsonObject().

            programItem:Add( 'codParametro' , b-thl-ambiente-param-prog.cod-param-ambiente ).
            programItem:Add( 'codPrograma'  , b-thl-ambiente-param-prog.cod-prog-dtsul     ).
            programItem:Add( 'referenceCode', this-object:loadReferenceCode()              ).

            programList:Add( programItem ).

        end.

        return programList.

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente-param-prog then
            return substitute( '&1#&2', b-thl-ambiente-param-prog.cod-param-ambiente,
                                        b-thl-ambiente-param-prog.cod-prog-dtsul ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-ambiente-param-prog exclusive-lock
            where b-thl-ambiente-param-prog.cod-param-ambiente = inContext:GetCharacter( 'codParametro' )
              and b-thl-ambiente-param-prog.cod-prog-dtsul     = inContext:GetCharacter( 'codPrograma'  )
            no-error.
    end method.

end class.

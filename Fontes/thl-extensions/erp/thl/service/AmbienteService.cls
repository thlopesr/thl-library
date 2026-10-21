/*------------------------------------------------------------------------
    File        : AmbienteService
    Purpose     : Servico de dominio do cadastro de ambientes (thl-ambiente,
                  tela thl0001): criacao, atualizacao, exclusao e listagem
                  paginada.
    Author(s)   : Lopes
    Created     : 2026-09-25
    Notes       : Padrao LpcoService (thl-extensions.erp.automatizador).
                  Regras iguais as da tela thl0001 (ADR api-rest-cadastros-thl):
                  17006 para validacao, 2 para registro relacionado inexistente.
                  A chave (cod-ambiente) so e gravada na criacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AmbienteService inherits Service.

    define private buffer b-thl-ambiente for thl-ambiente.

    method public override character getEntityName().
        return 'Ambiente'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'codAmbiente', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable jsonSetter      as JsonSetter no-undo.
        define variable environmentCode as character  no-undo.

        assign environmentCode = inContext:GetCharacter( 'codAmbiente' ).

        if environmentCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Ambiente nao informado. Informe o codigo do ambiente.' ).

        if available b-thl-ambiente then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Ambiente ja cadastrado. Informe outro codigo.' ).

        assign jsonSetter = new JsonSetter( inContext ).

        do transaction.

            create b-thl-ambiente.
            assign b-thl-ambiente.cod-ambiente = environmentCode.

            this-object:mapFields( jsonSetter ).
            this-object:validateIp().

        end.

    end method.

    method public override void update().

        if not available b-thl-ambiente then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Ambiente nao localizado.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateIp().

    end method.

    method public override void delete().

        if not available b-thl-ambiente then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Ambiente nao localizado.' ).

        //elimina tambem as variaveis de parametro do ambiente (thl0002b), como o local-delete-record do thl0001
        do transaction.

            for each thl-ambiente-param-variavel exclusive-lock
                where thl-ambiente-param-variavel.cod-ambiente = b-thl-ambiente.cod-ambiente.
                delete thl-ambiente-param-variavel.
            end.

            delete b-thl-ambiente.

        end.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'ambienteIni', '' ),
                                queryParameters:getText( 'ambienteFin', fill( 'z', 3 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  environmentCodeStart as character        ,
                                  environmentCodeEnd   as character        ).

        define variable environmentItem  as JsonObject no-undo.
        define variable environmentList as JsonArray  no-undo.

        assign environmentList = new JsonArray().

        for each b-thl-ambiente no-lock
            where b-thl-ambiente.cod-ambiente >= environmentCodeStart
              and b-thl-ambiente.cod-ambiente <= environmentCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign environmentItem = new JsonObject().

            environmentItem:Add( 'codAmbiente'  , b-thl-ambiente.cod-ambiente     ).
            environmentItem:Add( 'nomeAmbiente' , b-thl-ambiente.nome-ambiente    ).
            environmentItem:Add( 'ip'           , b-thl-ambiente.ip               ).
            environmentItem:Add( 'referenceCode', this-object:loadReferenceCode() ).

            environmentList:Add( environmentItem ).

        end.

        return environmentList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-ambiente.nome-ambiente, input 'nomeAmbiente' ).
        jsonSetter:SetValue( input-output b-thl-ambiente.ip           , input 'ip'           ).
    end method.

    //ip e chave alternativa unica (idx-ip): valida antes do commit
    method private void validateIp().

        define buffer b-outro-ambiente for thl-ambiente.

        if b-thl-ambiente.ip <> '' and
           can-find( first b-outro-ambiente
                     where b-outro-ambiente.ip            = b-thl-ambiente.ip
                       and b-outro-ambiente.cod-ambiente <> b-thl-ambiente.cod-ambiente ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateIp',
                'IP ja usado por outro ambiente. Informe outro IP.' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente then
            return b-thl-ambiente.cod-ambiente.
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-ambiente exclusive-lock
            where b-thl-ambiente.cod-ambiente = inContext:GetCharacter( 'codAmbiente' )
            no-error.
    end method.

end class.

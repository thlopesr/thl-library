/*------------------------------------------------------------------------
    File        : ParametroVariavelService
    Purpose     : Servico de dominio das variaveis de parametro por ambiente
                  (thl-ambiente-param-variavel, tela thl0002b): criacao,
                  atualizacao, exclusao e listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-09-25
    Notes       : Padrao LpcoService (thl-extensions.erp.automatizador).
                  Chave: cod-ambiente ('*' = todos), cod-param-ambiente e
                  cod-variavel. Parametro/ambiente inexistente -> erro 2.
                  Valor de variavel sensivel (senha, token, segredo) sai
                  mascarado no get(); no PATCH, o valor mascarado mantem o
                  valor gravado (ADR api-rest-cadastros-thl, secao 2.7).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ParametroVariavelService inherits Service.

    define public  property MaskedValue     as character no-undo initial '********' get.
    define private property SensitiveTokens as character no-undo initial 'SENHA,PASSWORD,SECRET,TOKEN,KEY,CHAVE' get.

    define private buffer b-thl-ambiente-param-variavel for thl-ambiente-param-variavel.

    method public override character getEntityName().
        return 'Variavel de Parametro'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'codAmbiente,codParametro,codVariavel', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable environmentCode as character no-undo.
        define variable parameterCode   as character no-undo.
        define variable variableCode    as character no-undo.

        assign environmentCode = inContext:GetCharacter( 'codAmbiente'  )
               parameterCode   = inContext:GetCharacter( 'codParametro' )
               variableCode    = inContext:GetCharacter( 'codVariavel'  ).

        if not can-find( thl-ambiente-param
                         where thl-ambiente-param.cod-param-ambiente = parameterCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Parametro de Ambiente nao cadastrado.', 2 ).

        if environmentCode <> '*' and
           not can-find( thl-ambiente
                         where thl-ambiente.cod-ambiente = environmentCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Ambiente nao cadastrado.', 2 ).

        if variableCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Variavel nao informada. Informe o codigo da variavel.' ).

        if available b-thl-ambiente-param-variavel then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Variavel ja cadastrada para o parametro e ambiente.' ).

        do transaction.

            create b-thl-ambiente-param-variavel.
            assign b-thl-ambiente-param-variavel.cod-ambiente       = environmentCode
                   b-thl-ambiente-param-variavel.cod-param-ambiente = parameterCode
                   b-thl-ambiente-param-variavel.cod-variavel       = variableCode.

            this-object:mapFields( new JsonSetter( inContext ) ).

        end.

    end method.

    method public override void update().

        if not available b-thl-ambiente-param-variavel then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Variavel nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).

    end method.

    method public override void delete().

        if not available b-thl-ambiente-param-variavel then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Variavel nao localizada.' ).

        delete b-thl-ambiente-param-variavel.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'ambienteIni', '' ),
                                queryParameters:getText( 'ambienteFin', fill( 'z', 3 ) ),
                                queryParameters:getText( 'parametroIni', '' ),
                                queryParameters:getText( 'parametroFin', fill( 'z', 15 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  environmentCodeStart as character        ,
                                  environmentCodeEnd   as character        ,
                                  parameterCodeStart   as character        ,
                                  parameterCodeEnd     as character        ).

        define variable variableItem as JsonObject no-undo.
        define variable variableList as JsonArray  no-undo.

        assign variableList = new JsonArray().

        //idx-ambiente-param-variavel: cod-ambiente, cod-param-ambiente
        for each b-thl-ambiente-param-variavel no-lock
            where b-thl-ambiente-param-variavel.cod-ambiente       >= environmentCodeStart
              and b-thl-ambiente-param-variavel.cod-ambiente       <= environmentCodeEnd
              and b-thl-ambiente-param-variavel.cod-param-ambiente >= parameterCodeStart
              and b-thl-ambiente-param-variavel.cod-param-ambiente <= parameterCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign variableItem = new JsonObject().

            variableItem:Add( 'codAmbiente'  , b-thl-ambiente-param-variavel.cod-ambiente       ).
            variableItem:Add( 'codParametro' , b-thl-ambiente-param-variavel.cod-param-ambiente ).
            variableItem:Add( 'codVariavel'  , b-thl-ambiente-param-variavel.cod-variavel       ).
            variableItem:Add( 'descricao'    , b-thl-ambiente-param-variavel.descr-variavel     ).
            variableItem:Add( 'valor'        , if this-object:isSensitive( b-thl-ambiente-param-variavel.cod-variavel )
                                               then this-object:MaskedValue
                                               else b-thl-ambiente-param-variavel.valor-variavel ).
            variableItem:Add( 'referenceCode', this-object:loadReferenceCode()                  ).

            variableList:Add( variableItem ).

        end.

        return variableList.

    end method.

    //variavel sensivel pelo nome (piloto); definitivo: campo ind-sensivel no .df
    method public logical isSensitive( input variableCode as character ).

        define variable tokenIndex as integer no-undo.

        do tokenIndex = 1 to num-entries( this-object:SensitiveTokens ).
            if index( caps( variableCode ), entry( tokenIndex, this-object:SensitiveTokens ) ) > 0 then
                return true.
        end.

        return false.

    end method.

    //so os campos fora da chave; valor mascarado recebido mantem o valor gravado
    method private void mapFields( input jsonSetter as JsonSetter ).

        jsonSetter:SetValue( input-output b-thl-ambiente-param-variavel.descr-variavel, input 'descricao' ).

        if not ( inContext:Has( 'valor' ) and
                 inContext:GetCharacter( 'valor' ) = this-object:MaskedValue ) then
            jsonSetter:SetValue( input-output b-thl-ambiente-param-variavel.valor-variavel, input 'valor' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-ambiente-param-variavel then
            return substitute( '&1#&2#&3', b-thl-ambiente-param-variavel.cod-param-ambiente,
                                           b-thl-ambiente-param-variavel.cod-ambiente,
                                           b-thl-ambiente-param-variavel.cod-variavel ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-ambiente-param-variavel exclusive-lock
            where b-thl-ambiente-param-variavel.cod-ambiente       = inContext:GetCharacter( 'codAmbiente'  )
              and b-thl-ambiente-param-variavel.cod-param-ambiente = inContext:GetCharacter( 'codParametro' )
              and b-thl-ambiente-param-variavel.cod-variavel       = inContext:GetCharacter( 'codVariavel'  )
            no-error.
    end method.

end class.

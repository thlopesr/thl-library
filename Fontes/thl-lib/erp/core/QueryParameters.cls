
/*------------------------------------------------------------------------
    File        : QueryParameters
    Purpose     : Leitura tipada dos parametros de uma consulta (acao
                  Consultado do Service:execute): texto, inteiro, data,
                  data e hora e paginacao, com valor padrao.
    Author(s)   : Lopes
    Created     : 2026-10-03
    Notes       : Embrulha o JsonObject que o execute recebe como contexto.
                  Formato do resourcen.p: cada propriedade e um array de
                  valores (so o primeiro e usado). Aceita tambem valor
                  simples, para quem monta a consulta fora do HTTP (.p, RPW).
                  Fica em thl-lib.erp.core para o Service nao depender da
                  camada de mensageria (InboundObjectContext).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.util.pagination.PaginationHelper.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.erp.core.QueryParameters.

    define private property parameters as JsonObject no-undo get. set.

    constructor public QueryParameters ( input parameters as JsonObject ).

        if valid-object( parameters ) then
            assign this-object:parameters = parameters.
        else
            assign this-object:parameters = new JsonObject().

    end constructor.

    method public logical has( input paramName as character ).
        return this-object:parameters:Has( paramName ).
    end method.

    method public character getText( input paramName    as character ,
                                     input defaultValue as character ).

        define variable values_ as JsonArray no-undo.

        if not this-object:parameters:Has( paramName ) then
            return defaultValue.

        if this-object:parameters:GetType( paramName ) = JsonDataType:ARRAY then do.

            assign values_ = this-object:parameters:GetJsonArray( paramName ).

            if values_:Length = 0 then
                return defaultValue.

            return values_:GetCharacter( 1 ).

        end.

        if this-object:parameters:GetType( paramName ) = JsonDataType:NULL then
            return defaultValue.

        return this-object:parameters:GetCharacter( paramName ).

    end method.

    method public integer getInteger( input paramName    as character ,
                                      input defaultValue as integer   ).
        return integer( this-object:getText( paramName, string( defaultValue ) ) ).
    end method.

    method public datetime getDate( input paramName    as character ,
                                    input defaultValue as datetime  ).
        return StringUtil:parseDate( this-object:getText( paramName, '' ), defaultValue ).
    end method.

    method public datetime getDateTime( paramName    as character ,
                                        defaultValue as datetime  ).
        return StringUtil:parseDateTime( this-object:getText( paramName, '' ), defaultValue ).
    end method.

    method public PaginationHelper getPager( input defaultPageSize as integer ).
        return new PaginationHelper( this-object:getInteger( 'pageSize', defaultPageSize ),
                                     this-object:getInteger( 'page'    , 1               ) ).
    end method.

end class.
